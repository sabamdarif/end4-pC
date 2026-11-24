import os
import shutil
import subprocess
import tempfile
import unittest

from ui_test_utils import qml_block, run_qml


@unittest.skipUnless(shutil.which("qs"), "Quickshell is required")
class CliphistAutostartTests(unittest.TestCase):
    def test_watcher_updates_are_idempotent(self):
        functions = qml_block("modules/ii/settings/pages/apps/ClipboardConfig.qml",
                              "    function autostartList() {", "    ContentSection {")
        functions = functions.replace("page.", "root.").replace("NiriConfig", "niriConfig")
        functions = functions.replace("Config.options.cliphist", "config.options.cliphist")
        run_qml(self, '''
        property QtObject config: QtObject {
            id: config
            property var options: ({cliphist: {maxEntries: 20}})
        }
        property QtObject niriConfig: QtObject {
            id: niriConfig
            property var options: ({autostart: []})
        }
''' + functions + '''
        Timer {
            interval: 100
            running: true
            onTriggered: {
                root.applyCliphistToAutostart();
                const initial = JSON.stringify(niriConfig.options.autostart);
                root.check(niriConfig.options.autostart.length === 2, "creates text and image watchers");
                root.applyCliphistToAutostart();
                root.check(JSON.stringify(niriConfig.options.autostart) === initial, "repeated update is unchanged");

                niriConfig.options.autostart = [
                    {command: "wl-paste --type text --watch cliphist store -max-items 750", enabled: false},
                    {command: "wl-paste --type image --watch cliphist -max-items=10 store", enabled: true},
                    {command: "cliphist store", enabled: true},
                    {command: "unrelated -max-items 99", enabled: false}
                ];
                root.applyCliphistToAutostart();
                const updated = niriConfig.options.autostart;
                root.check(updated.length === 4, "does not duplicate existing watchers");
                root.check(updated[0].command === "wl-paste --type text --watch cliphist -max-items 20 store", "migrates trailing flag");
                root.check(!updated[0].enabled, "preserves disabled watcher");
                root.check(updated[1].command === "wl-paste --type image --watch cliphist -max-items 20 store", "migrates global equals flag");
                root.check(updated[2].command === "cliphist -max-items 20 store", "adds missing flag");
                root.check(updated[3].command === "unrelated -max-items 99" && !updated[3].enabled, "preserves unrelated entry");

                config.options.cliphist.maxEntries = 30;
                root.applyCliphistToAutostart();
                root.applyCliphistToAutostart();
                root.check(niriConfig.options.autostart.length === 4, "changing limit remains idempotent");
                root.check(niriConfig.options.autostart[0].command === "wl-paste --type text --watch cliphist -max-items 30 store", "updates existing global flag");
                console.log("UI_TEST_DONE");
            }
        }
''')

    @unittest.skipUnless(shutil.which("cliphist"), "cliphist is required")
    def test_watcher_command_enforces_limit(self):
        with tempfile.TemporaryDirectory(prefix="cliphist-") as directory:
            env = dict(os.environ, XDG_CACHE_HOME=directory, XDG_CONFIG_HOME=directory)
            for index in range(5):
                subprocess.run(["cliphist", "-max-items", "3", "store"],
                               input=f"unique entry {index}".encode(), capture_output=True,
                               check=True, env=env)
            result = subprocess.run(["cliphist", "list"], capture_output=True,
                                    check=True, text=True, env=env)
            self.assertEqual(len(result.stdout.splitlines()), 3)


if __name__ == "__main__":
    unittest.main()
