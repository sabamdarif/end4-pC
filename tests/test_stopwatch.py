import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import unittest


REPOSITORY = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("qs"), "Quickshell is required")
class StopwatchTests(unittest.TestCase):
    def run_stopwatch(self, state, assertions):
        with tempfile.TemporaryDirectory(prefix="stopwatch-", dir="/tmp/opencode") as directory:
            root = Path(directory)
            common = root / "modules/common"
            common.mkdir(parents=True)
            services = root / "services"
            services.mkdir()
            (root / "states.json").write_text(json.dumps({"timer": {"stopwatch": state}}))
            shutil.copy(REPOSITORY / "modules/common/Persistent.qml", common)
            shutil.copy(REPOSITORY / "services/TimerService.qml", services)
            (common / "Directories.qml").write_text(f'''pragma Singleton
import Quickshell
Singleton {{ readonly property string state: {json.dumps(str(root))} }}
''')
            (common / "Config.qml").write_text('''pragma Singleton
import Quickshell
Singleton {
    property var options: ({ time: { pomodoro: { focus: 1500, breakTime: 300,
        longBreak: 900, cyclesBeforeLongBreak: 4 } }, sounds: { pomodoro: false } })
}
''')
            (services / "Translation.qml").write_text('''pragma Singleton
import Quickshell
Singleton { function tr(text) { return text; } }
''')
            (root / "shell.qml").write_text('''import QtQuick
import Quickshell
import "services"
import "modules/common"
ShellRoot {
    function check(condition, message) {
        if (!condition) console.error("ASSERTION_FAILED", message);
    }
    Component.onCompleted: console.log("STOPWATCH_INIT", TimerService.stopwatchTime)
    Timer {
        interval: 300
        running: true
        onTriggered: {
''' + assertions + '''
            console.log("STOPWATCH_TEST_DONE");
        }
    }
    Timer { interval: 700; running: true; onTriggered: Qt.quit() }
}
''')
            result = subprocess.run(["qs", "-p", str(root)], capture_output=True, text=True,
                                    timeout=8, env=dict(os.environ, QT_QPA_PLATFORM="offscreen"))
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertIn("STOPWATCH_TEST_DONE", output)
            for error in ("ASSERTION_FAILED", "TypeError", "ReferenceError"):
                self.assertNotIn(error, output)
            return json.loads((root / "states.json").read_text())["timer"]["stopwatch"]

    def test_paused_time_and_laps_survive_reload(self):
        state = self.run_stopwatch({"running": False, "start": 0, "elapsed": 32100, "laps": [1000]}, '''
            check(TimerService.stopwatchTime === 32100, "paused elapsed restored");
            check(TimerService.stopwatchLaps.length === 1, "paused laps restored");
            TimerService.stopwatchResume();
            check(Persistent.states.timer.stopwatch.start > 2147483647, "epoch is not truncated");
            TimerService.refreshStopwatch();
            check(TimerService.stopwatchTime >= 32100 && TimerService.stopwatchTime < 32110, "resume preserves elapsed");
            TimerService.stopwatchPause();
''')
        self.assertFalse(state["running"])
        self.assertGreaterEqual(state["elapsed"], 32100)
        self.assertEqual(state["laps"], [1000])

    def test_running_time_laps_and_reset(self):
        self.run_stopwatch({"running": True, "start": int(time.time() * 100) - 12345,
                            "elapsed": 0, "laps": []}, '''
            check(TimerService.stopwatchTime >= 12345 && TimerService.stopwatchTime < 13000, "running elapsed restored");
            TimerService.stopwatchRecordLap();
            check(TimerService.stopwatchLaps.length === 1, "lap recorded");
            check(TimerService.stopwatchLaps[0] >= 12345, "lap has actual elapsed");
            TimerService.stopwatchReset();
            check(TimerService.stopwatchTime === 0, "elapsed reset");
            check(Persistent.states.timer.stopwatch.elapsed === 0, "persisted elapsed reset");
            check(TimerService.stopwatchLaps.length === 0, "laps reset");
            check(!TimerService.stopwatchRunning, "reset stops timer");
''')


if __name__ == "__main__":
    unittest.main()
