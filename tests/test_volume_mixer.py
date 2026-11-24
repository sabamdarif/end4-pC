import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


REPOSITORY = Path(__file__).resolve().parents[1]


class VolumeMixerTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="volume-mixer-", dir="/tmp/opencode")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        source = (REPOSITORY / "modules/common/Config.qml").read_text()
        self.command = json.loads(re.search(r'property string volumeMixer: ("(?:\\.|[^"\\])*")', source)[1])
        self.bash = shutil.which("bash")
        self.env = dict(os.environ, PATH=str(self.root), MIXER_LAUNCH=str(self.root / "launched"))

    def install(self, name):
        executable = self.root / name
        executable.write_text('''#!/bin/sh
printf '%s' "$0" > "$MIXER_LAUNCH"
''')
        executable.chmod(0o755)

    def launch(self):
        return subprocess.run([self.bash, "-c", self.command], env=self.env, capture_output=True)

    def test_prefers_qt_when_both_mixers_exist(self):
        self.install("pavucontrol-qt")
        self.install("pavucontrol")
        self.assertEqual(self.launch().returncode, 0)
        self.assertEqual((self.root / "launched").read_text(), str(self.root / "pavucontrol-qt"))

    def test_falls_back_to_pavucontrol(self):
        self.install("pavucontrol")
        self.assertEqual(self.launch().returncode, 0)
        self.assertEqual((self.root / "launched").read_text(), str(self.root / "pavucontrol"))

    def test_missing_mixers_fail_without_launching_anything(self):
        self.assertNotEqual(self.launch().returncode, 0)
        self.assertFalse((self.root / "launched").exists())


if __name__ == "__main__":
    unittest.main()
