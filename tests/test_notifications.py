import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPOSITORY = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("qs") and shutil.which("dbus-run-session"), "Quickshell and D-Bus are required")
class NotificationTests(unittest.TestCase):
    def test_process_local_images_and_missing_timers(self):
        with tempfile.TemporaryDirectory(prefix="notifications-", dir=os.environ.get("TMPDIR")) as directory:
            root = Path(directory)
            common = root / "modules/common"
            common.mkdir(parents=True)
            services = root / "services"
            services.mkdir()
            data = root / "notifications.json"
            data.write_text(json.dumps([{
                "notificationId": 1, "appIcon": "image://qsimage/1/1", "appName": "Test",
                "body": "Body", "image": "image://qsimage/1/2", "summary": "Summary",
                "time": 1, "urgency": "normal",
            }]))
            shutil.copy(REPOSITORY / "services/Notifications.qml", services)
            (common / "Directories.qml").write_text(f'''pragma Singleton
import Quickshell
Singleton {{ readonly property string notificationsPath: {json.dumps(str(data))} }}
''')
            (common / "Config.qml").write_text('''pragma Singleton
import Quickshell
Singleton { property var options: ({ notifications: { timeout: 7000 }, sounds: { notification: false } }) }
''')
            (root / "GlobalStates.qml").write_text('''pragma Singleton
import Quickshell
Singleton { property bool sidebarRightOpen: false }
''')
            (root / "shell.qml").write_text('''import QtQuick
import Quickshell
import "services"
ShellRoot {
    function check(condition, message) {
        if (!condition) console.error("ASSERTION_FAILED", message);
    }
    Component.onCompleted: console.log("NOTIFICATION_INIT", Notifications.list.length)
    Timer {
        interval: 200
        running: true
        onTriggered: {
            check(Notifications.list.length === 1, "saved notification loaded");
            const saved = Notifications.list[0];
            check(saved.image === "" && saved.appIcon === "", "stale handles cleared on load");
            saved.image = "image://qsimage/2/1";
            saved.appIcon = "image://qsimage/2/2";
            const serialized = Notifications.notifToJSON(saved);
            check(serialized.image === "" && serialized.appIcon === "", "live handles not persisted");
            saved.image = "file:///test.png";
            saved.appIcon = "test-app";
            check(Notifications.notifToJSON(saved).image === "file:///test.png", "file paths preserved");
            check(Notifications.notifToJSON(saved).appIcon === "test-app", "theme icons preserved");
            Notifications.cancelTimeout(1);
            Notifications.cancelTimeout(999);
            Notifications.attemptInvokeAction(1, "missing");
            console.log("NOTIFICATION_TEST_DONE");
        }
    }
    Timer { interval: 500; running: true; onTriggered: Qt.quit() }
}
''')
            result = subprocess.run(["dbus-run-session", "--", "qs", "-p", str(root)],
                                    capture_output=True, text=True, timeout=8,
                                    env=dict(os.environ, QT_QPA_PLATFORM="offscreen"))
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertIn("NOTIFICATION_TEST_DONE", output)
            for error in ("ASSERTION_FAILED", "TypeError", "ReferenceError"):
                self.assertNotIn(error, output)


if __name__ == "__main__":
    unittest.main()
