import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

from ui_test_utils import qml_block


REPOSITORY = Path(__file__).resolve().parents[1]
ISLAND = "services/IslandEvents.qml"


@unittest.skipUnless(shutil.which("qs"), "Quickshell is required")
class IslandIntegrationTests(unittest.TestCase):
    def run_fixture(self, body, scripts=None, binaries=None):
        with tempfile.TemporaryDirectory(prefix="island-") as directory:
            root = Path(directory)
            downloads = root / "Downloads"
            downloads.mkdir()
            (downloads / "recent.part").write_text("partial download")
            for name, contents in (scripts or {}).items():
                path = root / "scripts/island" / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(contents)
            for name, contents in (binaries or {}).items():
                path = root / "bin" / name
                path.parent.mkdir(exist_ok=True)
                path.write_text(contents)
                path.chmod(0o755)
            stubs = root / "stubs"
            stubs.mkdir()
            for name, properties in {
                "Directories": f'''readonly property string downloads: {json.dumps(downloads.as_uri())}
    readonly property string home: {json.dumps(root.as_uri())}''',
                "FileUtils": 'function trimFileProtocol(path) { return path.replace(/^file:\\/\\//, ""); }',
                "Translation": 'function tr(text) { return text; }',
                "Persistent": 'property var states: ({ record: { enable: true } })',
            }.items():
                (stubs / f"{name}.qml").write_text(f'''pragma Singleton
import Quickshell
Singleton {{ {properties} }}
''')
            (root / "shell.qml").write_text('''import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "stubs"
ShellRoot {
    id: root
    property var cfg: ({ network: true, downloadDetection: "files", linkDownloadDir: "" })
    property bool fakeNet: false
    property string downloadMode: "files"
    property var linkBrands: []
    property var activities: []
    function upsertActivity(id, title, detail, icon, progress, state) {
        root.activities = [...root.activities, { title: title, detail: detail, state: state }];
    }
    function handleDownloadWatch(line) {}
    function check(condition, message) {
        if (!condition) console.error("ASSERTION_FAILED", message);
    }
''' + body + '''
    Timer { interval: 1500; running: true; onTriggered: Qt.quit() }
}
''')
            result = subprocess.run(["qs", "-p", str(root)], capture_output=True, text=True,
                                    timeout=8, env=dict(os.environ, QT_QPA_PLATFORM="offscreen",
                                                       PATH=f"{root / 'bin'}:{os.environ['PATH']}"))
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertIn("ISLAND_TEST_DONE", output)
            for error in ("ASSERTION_FAILED", "TypeError", "ReferenceError", "Process failed to start"):
                self.assertNotIn(error, output)
            log = root / "calls.jsonl"
            return [json.loads(line) for line in log.read_text().splitlines()] if log.exists() else []

    def test_missing_helpers_disable_actions_and_recent_partial_watcher(self):
        links = qml_block(ISLAND, "    readonly property var islandHelpers:", "    property var translation:")
        watcher = qml_block(ISLAND, "    readonly property bool downloadWatchEnabled:", "    function handleDownloadWatch(")
        reply = qml_block(ISLAND, "    function pasteReplyInto(", "    property var audioProfiles:")
        self.run_fixture(links + watcher + reply + '''
    Timer {
        interval: 300; running: true
        onTriggered: {
            check(partialDownloads.count === 1, "recent partial file found");
            check(!root.downloadWatchEnabled && !downloadWatcher.running, "missing watcher not launched");
            check(!downloadWatchRetry.running, "no missing-helper retry");
            check(!root.chatReplyAvailable, "reply action disabled");
            check(root.linkDownloadKind("https://example.test/video.mp4") === "", "download action disabled");
            root.downloadMedia("https://example.test/video.mp4", "video");
            check(!root.mediaDownloadBusy && root.activities[0].state === "error", "unavailable download explained");
            root.pasteReplyInto(null, "A literal reply");
            check(Quickshell.clipboardText === "A literal reply" && !pasteProc.running, "missing reply helper falls back to clipboard");
            root.cfg = { linkDownloadDir: "~/Saved///" };
            check(root.linkDownloadDir.endsWith("/Saved"), "destination lives on singleton and expands home");
            console.log("ISLAND_TEST_DONE");
            Qt.quit();
        }
    }
''')

    def test_link_downloader_queue_and_error_reporting(self):
        links = qml_block(ISLAND, "    readonly property var islandHelpers:", "    property var translation:")
        calls = self.run_fixture(links + '''
    Timer {
        interval: 200; running: true
        onTriggered: {
            check(root.linkDownloadKind("https://youtu.be/example") === "video", "video URL classified");
            check(root.linkDownloadKind("https://example.test/track.mp3") === "audio", "audio URL classified");
            root.downloadMedia("https://example.test/first.mp4", "video");
            root.downloadMedia("https://example.test/fail.mp4", "video");
            check(root.mediaDownloadQueue.length === 1, "second job queued");
        }
    }
    Timer {
        interval: 900; running: true
        onTriggered: {
            check(!root.mediaDownloadBusy && root.mediaDownloadQueue.length === 0, "queue drained");
            check(root.activities.some(activity => activity.state === "done"), "success reported");
            check(root.activities.some(activity => activity.state === "error" && activity.detail === "No connection"), "helper error mapped");
            console.log("ISLAND_TEST_DONE");
            Qt.quit();
        }
    }
''', scripts={"link_download.py": '''import json
from pathlib import Path
import sys
import time
root = Path(__file__).resolve().parents[2]
with (root / "calls.jsonl").open("a") as log:
    log.write(json.dumps(sys.argv[1:]) + "\\n")
time.sleep(0.1)
if "fail" in sys.argv[-1]:
    print("ERROR network")
    sys.exit(1)
print("FILE " + sys.argv[sys.argv.index("--dest") + 1] + "/first.mp4")
'''})
        self.assertEqual(len(calls), 2)
        self.assertTrue(calls[0][3].endswith("/Downloads/Island"))
        self.assertEqual(calls[1][-1], "https://example.test/fail.mp4")

    def test_watcher_exit_does_not_restart_immediately(self):
        helpers = qml_block(ISLAND, "    readonly property var islandHelpers:", "    readonly property bool mediaDownloadBusy:")
        watcher = qml_block(ISLAND, "    readonly property bool downloadWatchEnabled:", "    function handleDownloadWatch(")
        for exit_code in (0, 2):
            with self.subTest(exit_code=exit_code):
                calls = self.run_fixture(helpers + watcher + f'''
    Timer {{
        interval: 800; running: true
        onTriggered: {{
            check(root.downloadWatchEnabled && !downloadWatcher.running, "watcher ran and exited");
            check(downloadWatchRetry.running === {str(exit_code == 0).lower()}, "only successful exit schedules delayed retry");
            console.log("ISLAND_TEST_DONE");
            Qt.quit();
        }}
    }}
''', scripts={"download_watch.py": f'''from pathlib import Path
import sys
with (Path(__file__).resolve().parents[2] / "calls.jsonl").open("a") as log:
    log.write("[]\\n")
sys.exit({exit_code})
'''})
                self.assertEqual(len(calls), 1)

    def test_recording_stop_handles_simulation_and_process_failures(self):
        stop = qml_block("modules/ii/bar/DynamicIsland.qml", "    function stopRecording()", "    Timer {\n        interval: 1000")
        for exit_code in (0, 1, 2):
            with self.subTest(exit_code=exit_code):
                calls = self.run_fixture('''
    property bool fakeRecording: true
    property int collapsed: 0
    function collapse() { root.collapsed++; }
''' + stop + f'''
    Timer {{
        interval: 100; running: true
        onTriggered: {{
            root.stopRecording();
            check(!root.fakeRecording && !recordingStop.running, "simulation stops without invoking recorder command");
            root.stopRecording();
        }}
    }}
    Timer {{
        interval: 400; running: true
        onTriggered: {{
            check(Persistent.states.record.enable === {str(exit_code == 2).lower()}, "record state cleared only on stop or absent process");
            check(root.collapsed === 2, "stop collapses expanded view");
            console.log("ISLAND_TEST_DONE");
            Qt.quit();
        }}
    }}
''', binaries={"pkill": f'''#!/usr/bin/env python3
import json
from pathlib import Path
import sys
with (Path(__file__).resolve().parents[1] / "calls.jsonl").open("a") as log:
    log.write(json.dumps(sys.argv[1:]) + "\\n")
sys.exit({exit_code})
'''})
                self.assertEqual(calls, [["-INT", "-x", "wf-recorder"]])


if __name__ == "__main__":
    unittest.main()
