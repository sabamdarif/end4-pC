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
    def run_service(self, contents, body):
        with tempfile.TemporaryDirectory(prefix="notifications-", dir=os.environ.get("TMPDIR")) as directory:
            root = Path(directory)
            common = root / "modules/common"
            common.mkdir(parents=True)
            services = root / "services"
            services.mkdir()
            data = root / "notifications.json"
            if contents is not None:
                data.write_text(contents)
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
import Quickshell.Io
import "services"
ShellRoot {
    id: root
    function check(condition, message) {
        if (!condition) console.error("ASSERTION_FAILED", message);
    }
    Component.onCompleted: console.log("NOTIFICATION_INIT", Notifications.list.length)
''' + body + '''
    Timer { interval: 1000; running: true; onTriggered: Qt.quit() }
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
            return data.read_text()

    def test_process_local_images_and_missing_timers(self):
        contents = json.dumps([{
            "notificationId": 1, "appIcon": "image://qsimage/1/1", "appName": "Test",
            "body": "Body", "image": "image://qsimage/1/2", "summary": "Summary",
            "time": 1, "urgency": "normal",
        }])
        self.run_service(contents, '''
    property QtObject discardedWrapper
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
            root.discardedWrapper = saved;
            Notifications.attemptInvokeAction(1, "missing");
        }
    }
    Timer {
        interval: 300; running: true
        onTriggered: {
            check(root.discardedWrapper === null, "discarded wrapper released");
            Notifications.refresh();
        }
    }
    Timer {
        interval: 450; running: true
        onTriggered: {
            check(Notifications.list.length === 0, "dismissed notification not restored");
            console.log("NOTIFICATION_TEST_DONE");
            Qt.quit();
        }
    }
''')

    @unittest.skipUnless(shutil.which("notify-send"), "notify-send is required")
    def test_live_wrappers_and_timers_released_on_clear(self):
        saved = self.run_service("[]", '''
    property QtObject firstWrapper
    property QtObject secondWrapper
    property QtObject cancelledTimer
    property QtObject clearedTimer
    Process { id: first; command: ["notify-send", "-t", "5000", "First notification"] }
    Process { id: second; command: ["notify-send", "-t", "5000", "Second notification"] }
    Timer { interval: 100; running: true; onTriggered: first.running = true }
    Timer { interval: 150; running: true; onTriggered: second.running = true }
    Timer {
        interval: 400; running: true
        onTriggered: {
            check(Notifications.list.length === 2, "both live notifications received");
            root.firstWrapper = Notifications.list[0];
            root.secondWrapper = Notifications.list[1];
            root.cancelledTimer = firstWrapper.timer;
            root.clearedTimer = secondWrapper.timer;
            check(cancelledTimer !== null && clearedTimer !== null, "popup timers started");
            Notifications.cancelTimeout(firstWrapper.notificationId);
        }
    }
    Timer {
        interval: 500; running: true
        onTriggered: {
            check(root.cancelledTimer === null, "cancelled timer released");
            Notifications.attemptInvokeAction(firstWrapper.notificationId, "unknown-action");
            Notifications.discardAllNotifications();
        }
    }
    Timer {
        interval: 650; running: true
        onTriggered: {
            check(Notifications.list.length === 0, "all notifications cleared");
            check(root.firstWrapper === null && root.secondWrapper === null, "wrappers released");
            check(root.clearedTimer === null, "cleared timer released");
            console.log("NOTIFICATION_TEST_DONE");
            Qt.quit();
        }
    }
''')
        self.assertEqual(json.loads(saved), [])

    def test_malformed_files_are_preserved(self):
        for contents in ('{"unfinished":', "null", "{}", "[null]", '[{"notificationId": "1"}]'):
            with self.subTest(contents=contents):
                saved = self.run_service(contents, '''
    Timer {
        interval: 200; running: true
        onTriggered: {
            Notifications.discardAllNotifications();
            console.log("NOTIFICATION_TEST_DONE");
        }
    }
''')
                self.assertEqual(saved, contents)


if __name__ == "__main__":
    unittest.main()
