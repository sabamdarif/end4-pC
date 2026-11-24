import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "scripts/images/fetch-cover.sh"


class CoverArtTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="cover-art-", dir=os.environ.get("TMPDIR"))
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.target = self.root / "cache with 'quotes'" / "cover"
        curl = self.root / "curl"
        curl.write_text('''#!/usr/bin/env python3
import os
from pathlib import Path
import sys
import time
args = sys.argv[1:]
time.sleep(float(os.environ.get("CURL_DELAY", "0")))
Path(os.environ["CURL_ARGS"]).write_text(repr(args))
Path(args[args.index("--output") + 1]).write_bytes(os.environ.get("CURL_DATA", "image").encode())
sys.exit(int(os.environ.get("CURL_EXIT", "0")))
''')
        curl.chmod(0o755)
        self.env = dict(os.environ, PATH=f"{self.root}:{os.environ['PATH']}", CURL_ARGS=str(self.root / "args"))

    def fetch(self, url="https://example.test/cover", **environment):
        return subprocess.run(["bash", str(SCRIPT), str(self.target), url],
                              env=dict(self.env, **environment), capture_output=True)

    def test_url_and_path_are_literal_arguments(self):
        url = "https://example.test/art'; touch injected; echo '$(whoami)"
        self.assertEqual(self.fetch(url).returncode, 0)
        self.assertEqual(self.target.read_bytes(), b"image")
        self.assertIn(repr(url), (self.root / "args").read_text())
        self.assertFalse((self.root / "injected").exists())

    def test_cached_cover_is_not_downloaded_again(self):
        self.assertEqual(self.fetch().returncode, 0)
        (self.root / "args").unlink()
        self.assertEqual(self.fetch(CURL_EXIT="22").returncode, 0)
        self.assertFalse((self.root / "args").exists())

    def test_failed_download_does_not_cache_partial_data(self):
        self.assertNotEqual(self.fetch(CURL_EXIT="22").returncode, 0)
        self.assertFalse(self.target.exists())
        self.assertEqual(list(self.target.parent.iterdir()), [])

    def test_empty_download_is_rejected(self):
        self.assertNotEqual(self.fetch(CURL_DATA="").returncode, 0)
        self.assertFalse(self.target.exists())

    def test_empty_old_cache_is_replaced(self):
        self.target.parent.mkdir()
        self.target.touch()
        self.assertEqual(self.fetch().returncode, 0)
        self.assertEqual(self.target.read_bytes(), b"image")

    @unittest.skipUnless(shutil.which("qs"), "Quickshell is required")
    def test_track_changes_during_download_and_feature_gating(self):
        repository = SCRIPT.parents[2]
        widgets = self.root / "modules/common/widgets"
        widgets.mkdir(parents=True)
        scripts = self.root / "scripts/images"
        scripts.mkdir(parents=True)
        shutil.copy(SCRIPT, scripts)
        shutil.copy(repository / "modules/common/widgets/CoverArt.qml", widgets)
        (widgets.parent / "Directories.qml").write_text(f'''pragma Singleton
import Quickshell
Singleton {{ readonly property string coverArt: {json.dumps(str(self.target.parent))} }}
''')
        (self.root / "shell.qml").write_text('''import QtQuick
import Quickshell
import "modules/common/widgets"
ShellRoot {
    function check(condition, message) {
        if (!condition) console.error("ASSERTION_FAILED", message);
    }
    CoverArt { id: art; url: "https://example.test/first" }
    Timer { interval: 50; running: true; onTriggered: art.url = "https://example.test/second" }
    Timer {
        interval: 600; running: true
        onTriggered: {
            check(art.downloadedUrl === art.url && art.source !== "", "latest track fetched after in-flight download");
            art.enabled = false;
            check(art.source === "", "disabled artwork hidden");
            art.url = "https://example.test/third";
            art.enabled = true;
        }
    }
    Timer {
        interval: 1000; running: true
        onTriggered: {
            check(art.downloadedUrl === art.url && art.source !== "", "enabling fetches latest cover");
            art.url = "file:///test.png";
            check(art.source === "file:///test.png", "local cover bypasses downloader");
            art.url = "";
            check(art.source === "", "missing cover cleared");
            console.log("COVER_ART_TEST_DONE");
            Qt.quit();
        }
    }
}
''')
        result = subprocess.run(["qs", "-p", str(self.root)], capture_output=True, text=True,
                                timeout=8, env=dict(self.env, QT_QPA_PLATFORM="offscreen", CURL_DELAY="0.15"))
        output = result.stdout + result.stderr
        self.assertEqual(result.returncode, 0, output)
        self.assertIn("COVER_ART_TEST_DONE", output)
        for error in ("ASSERTION_FAILED", "TypeError", "ReferenceError"):
            self.assertNotIn(error, output)


if __name__ == "__main__":
    unittest.main()
