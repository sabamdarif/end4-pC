import shutil
import unittest

from ui_test_utils import qml_block, run_qml


@unittest.skipUnless(shutil.which("qs"), "Quickshell is required")
class LauncherSelectionTests(unittest.TestCase):
    def test_actions_run_before_close_clears_results(self):
        action = qml_block("modules/ii/overview/SearchWidget.qml",
                           "    function launchSelected() {", "    Keys.onPressed:")
        action = action.replace("GlobalStates", "globalStates").replace("LauncherSearch", "launcher")
        action = action.replace("Quickshell.clipboardText", "root.copiedText")
        run_qml(self, '''
        property int actionCount: 0
        property string copiedText: ""
        property string selectedSection: ""
        property int sectionIndex: 0
        property var displayedApps: launcher.appResults
        property QtObject globalStates: QtObject {
            id: globalStates
            property bool overviewOpen: true
            onOverviewOpenChanged: if (!overviewOpen) launcher.query = ""
        }
        property QtObject launcher: QtObject {
            id: launcher
            property string query: "app"
            readonly property var appResults: query !== "" ? [{execute: () => root.actionCount++}] : []
            readonly property var settingsResults: query !== "" ? [{execute: () => root.actionCount++}] : []
            readonly property var mathResult: query !== "" ? {result: "42"} : null
        }
        property QtObject fileSearch: QtObject {
            id: fileSearch
            readonly property var results: launcher.query !== "" ? [{execute: () => root.actionCount++}] : []
        }
''' + action + '''
        Timer {
            interval: 100
            running: true
            onTriggered: {
                for (const section of ["apps", "files", "settings", "math", ""]) {
                    globalStates.overviewOpen = true;
                    launcher.query = "app";
                    root.selectedSection = section;
                    root.launchSelected();
                    root.check(!globalStates.overviewOpen, section + " closes launcher");
                    root.check(launcher.query === "", section + " clears search");
                }
                root.check(root.actionCount === 3, "each selected result executes");
                root.check(root.copiedText === "42", "calculator and fallback copy before clearing");
                console.log("UI_TEST_DONE");
            }
        }
''')


if __name__ == "__main__":
    unittest.main()
