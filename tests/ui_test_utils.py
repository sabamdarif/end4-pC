import os
from pathlib import Path
import subprocess
import tempfile


REPOSITORY = Path(__file__).resolve().parents[1]


def qml_block(path, start, end):
    source = (REPOSITORY / path).read_text()
    return source[source.index(start):source.index(end, source.index(start))]


def run_qml(test, body):
    with tempfile.TemporaryDirectory(prefix="ui-") as directory:
        root = Path(directory)
        (root / "shell.qml").write_text('''import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
ShellRoot {
    Window {
        visible: true
        width: 980
        height: 600
        Item {
            id: root
            width: 980
            height: 600
            function check(condition, message) {
                if (!condition) console.error("ASSERTION_FAILED", message);
            }
''' + body + '''
            Timer { interval: 1000; running: true; onTriggered: Qt.quit() }
        }
    }
}
''')
        result = subprocess.run(["qs", "-p", str(root)], capture_output=True, text=True,
                                timeout=8, env=dict(os.environ, QT_QPA_PLATFORM="offscreen"))
        output = result.stdout + result.stderr
        test.assertEqual(result.returncode, 0, output)
        test.assertIn("UI_TEST_DONE", output)
        for error in ("ASSERTION_FAILED", "TypeError", "ReferenceError", "Error loading configuration"):
            test.assertNotIn(error, output)
