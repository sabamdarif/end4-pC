import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

from ui_test_utils import qml_block, run_qml


class CliphistCommandTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="cliphist-commands-")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.entry = "42\t100% ready\\n\\c '$(touch injected)'\nnext line"
        self.decoder = self.root / "decoder with 'quotes' %"
        self.decoder.write_text('''#!/usr/bin/env python3
import sys
if sys.argv[1:] != ["decode"]:
    sys.exit(1)
sys.stdout.buffer.write(sys.stdin.buffer.read())
''')
        self.decoder.chmod(0o755)
        copier = self.root / "wl-copy"
        copier.write_text('''#!/usr/bin/env python3
import os
from pathlib import Path
import sys
Path(os.environ["COPIED_BYTES"]).write_bytes(sys.stdin.buffer.read())
''')
        copier.chmod(0o755)
        self.env = dict(os.environ, PATH=f"{self.root}:{os.environ['PATH']}",
                        COPIED_BYTES=str(self.root / "copied"))

    def command_block(self, operation):
        if operation == "copy":
            return qml_block("services/Cliphist.qml", "    function copy(entry) {", "    Process {")
        return qml_block("services/ClipboardPins.qml", f"        id: {operation}PinProc",
                         "        function pinEntry(entry) {")

    def run_command(self, operation, arguments):
        block = self.command_block(operation)
        program = json.loads(re.search(r'\["bash", "-c", ("(?:\\.|[^"\\])*")', block)[1])
        return subprocess.run(["bash", "-c", program, "cliphist-test", *arguments],
                              capture_output=True, cwd=self.root, env=self.env, check=True)

    def test_copy_preserves_literal_preview_bytes(self):
        self.run_command("copy", [self.entry, str(self.decoder)])
        self.assertEqual((self.root / "copied").read_bytes(), self.entry.encode())
        self.assertFalse((self.root / "injected").exists())

    def test_text_pin_preserves_literal_preview_bytes(self):
        result = self.run_command("text", [self.entry, str(self.decoder)])
        self.assertEqual(result.stdout, self.entry.encode())
        self.assertFalse((self.root / "injected").exists())

    def test_image_pin_preserves_literal_arguments(self):
        folder = self.root / "pins with 'quotes' $(touch injected)"
        target = folder / "image with 'quotes'.png"
        self.run_command("image", [str(folder), self.entry, str(self.decoder), str(target)])
        self.assertEqual(target.read_bytes(), self.entry.encode())
        self.assertFalse((self.root / "injected").exists())

    @unittest.skipUnless(shutil.which("qs"), "Quickshell is required")
    def test_qml_passes_data_as_positional_arguments(self):
        copy = self.command_block("copy").replace("Quickshell.execDetached", "root.recordCommand")
        text = self.command_block("text").split("command:", 1)[1].strip()
        image = self.command_block("image").split("command:", 1)[1].strip()
        text = text.replace("Cliphist.", "cliphist.")
        image = image.replace("Cliphist.", "cliphist.")
        run_qml(self, f'''
        property string entry: {json.dumps(self.entry)}
        property string cliphistBinary: {json.dumps(str(self.decoder))}
        property string pinsDir: "/tmp/test pins"
        property var captured: []
        function recordCommand(command) {{ root.captured = command; }}
        property QtObject cliphist: QtObject {{
            id: cliphist
            property string cliphistBinary: root.cliphistBinary
        }}
        property QtObject textPinProc: QtObject {{
            id: textPinProc
            property string pendingEntry: root.entry
        }}
        property QtObject imagePinProc: QtObject {{
            id: imagePinProc
            property string pendingEntry: root.entry
            property string pendingPath: root.pinsDir + "/image.png"
        }}
        property var textCommand: {text}
        property var imageCommand: {image}
''' + copy + '''
        Timer {
            interval: 100
            running: true
            onTriggered: {
                root.copy(root.entry);
                root.check(root.captured[4] === root.entry, "copy entry is positional");
                root.check(root.captured[5] === root.cliphistBinary, "copy decoder is positional");
                root.check(root.textCommand[4] === root.entry && root.textCommand[5] === root.cliphistBinary, "text pin arguments");
                root.check(root.imageCommand[4] === root.pinsDir, "image pin directory");
                root.check(root.imageCommand[5] === root.entry && root.imageCommand[6] === root.cliphistBinary, "image pin arguments");
                root.check(root.imageCommand[7] === imagePinProc.pendingPath, "image pin target");
                console.log("UI_TEST_DONE");
            }
        }
''')


if __name__ == "__main__":
    unittest.main()
