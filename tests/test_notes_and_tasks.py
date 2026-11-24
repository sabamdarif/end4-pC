import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPOSITORY = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("qs"), "Quickshell is required")
class NotesAndTasksTests(unittest.TestCase):
    def run_service(self, service, contents, ready):
        with tempfile.TemporaryDirectory(prefix="notes-tasks-", dir=os.environ.get("TMPDIR")) as directory:
            root = Path(directory)
            common = root / "modules/common"
            common.mkdir(parents=True)
            services = root / "services"
            services.mkdir()
            data = root / "data.json"
            if contents is not None:
                data.write_text(contents)
            shutil.copy(REPOSITORY / f"services/{service}.qml", services)
            (common / "Directories.qml").write_text(f'''pragma Singleton
import Quickshell
Singleton {{
    readonly property string desktopNotesPath: {json.dumps(str(data))}
    readonly property string todoPath: {json.dumps(str(data))}
}}
''')
            (services / "Translation.qml").write_text('''pragma Singleton
import Quickshell
Singleton { function tr(text) { return text; } }
''')
            operation = 'addNote("new note")' if service == "Notes" else 'addTask("new task")'
            (root / "shell.qml").write_text(f'''import QtQuick
import Quickshell
import "services"
ShellRoot {{
    Component.onCompleted: console.log("SERVICE_INIT", {service}.ready)
    Timer {{
        interval: 300
        running: true
        onTriggered: {{
            console.log("SERVICE_READY", {service}.ready);
            {service}.{operation};
        }}
    }}
    Timer {{ interval: 700; running: true; onTriggered: Qt.quit() }}
}}
''')
            result = subprocess.run(["qs", "-p", str(root)], capture_output=True, text=True,
                                    timeout=8, env=dict(os.environ, QT_QPA_PLATFORM="offscreen"))
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertIn(f"SERVICE_READY {'true' if ready else 'false'}", output)
            self.assertNotIn("TypeError", output)
            self.assertNotIn("ReferenceError", output)
            return data.read_text()

    def test_malformed_files_are_preserved_and_writes_blocked(self):
        for service in ("Notes", "Todo"):
            for contents in ('{"unfinished":', "", "null", "{}", "[null]"):
                with self.subTest(service=service, contents=contents):
                    self.assertEqual(self.run_service(service, contents, False), contents)

    def test_invalid_entries_are_preserved(self):
        for service, contents in (
            ("Notes", '[{"id":"1","content":"note","attachments":[null]}]'),
            ("Todo", '[{"content":"task","done":"false"}]'),
        ):
            with self.subTest(service=service):
                self.assertEqual(self.run_service(service, contents, False), contents)

    def test_valid_files_remain_editable(self):
        for service, item in (
            ("Notes", {"id": "1", "content": "saved", "attachments": [], "createdAt": 1}),
            ("Todo", {"content": "saved", "done": False}),
        ):
            with self.subTest(service=service):
                saved = json.loads(self.run_service(service, json.dumps([item]), True))
                self.assertEqual(saved[0], item)
                self.assertEqual(len(saved), 2)

    def test_missing_files_are_initialized(self):
        for service in ("Notes", "Todo"):
            with self.subTest(service=service):
                self.assertEqual(len(json.loads(self.run_service(service, None, True))), 1)


if __name__ == "__main__":
    unittest.main()
