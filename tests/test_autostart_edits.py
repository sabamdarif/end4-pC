import shutil
import unittest

from ui_test_utils import qml_block, run_qml


@unittest.skipUnless(shutil.which("qs"), "Quickshell is required")
class AutostartEditTests(unittest.TestCase):
    def test_model_mutations_preserve_all_pending_commands(self):
        actions = qml_block("modules/ii/settings/pages/apps/AutostartConfig.qml",
                            "    function autostartList() {", "    function fileBadge(")
        actions = actions.replace("NiriConfig.options.autostart", "root.entries").replace("page.", "root.")
        run_qml(self, '''
        property var entries: [{command: "first", enabled: true}, {command: "second", enabled: true}]
        Repeater {
            id: autostartRepeater
            model: root.entries
            delegate: Item {
                required property var modelData
                property string commandDraft: modelData.command
            }
        }
''' + actions + '''
        Timer {
            interval: 100
            running: true
            onTriggered: {
                autostartRepeater.itemAt(0).commandDraft = "edited first";
                autostartRepeater.itemAt(1).commandDraft = "edited second";
                root.updateAutostart(0, "enabled", false);
                root.check(root.entries[0].command === "edited first", "toggle preserves its command");
                root.check(root.entries[1].command === "edited second", "toggle preserves other command");
                root.check(!root.entries[0].enabled, "toggle still applies");
                autostartRepeater.itemAt(1).commandDraft = "new draft";
                root.addAutostart("third");
                root.check(root.entries[1].command === "new draft", "add preserves draft");
                autostartRepeater.itemAt(1).commandDraft = "last draft";
                root.removeAutostart(0);
                root.check(root.entries[0].command === "last draft", "remove preserves remaining draft");
                autostartRepeater.itemAt(1).commandDraft = "third draft";
                root.updateAutostart(0, "command", "committed command");
                root.check(root.entries[0].command === "committed command", "debounce commits command");
                root.check(root.entries[1].command === "third draft", "debounce preserves other draft");
                console.log("UI_TEST_DONE");
            }
        }
''')


if __name__ == "__main__":
    unittest.main()
