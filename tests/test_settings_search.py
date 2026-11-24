import shutil
import unittest

from ui_test_utils import qml_block, run_qml


@unittest.skipUnless(shutil.which("qs"), "Quickshell is required")
class SettingsSearchTests(unittest.TestCase):
    def test_keyboard_selection_reveals_results_beyond_popup_height(self):
        view = qml_block("modules/ii/settings/SettingsContent.qml",
                         "                            StyledListView {\n                                id: settingsSearchResultsView",
                         "                                delegate: RippleButton {")
        view = view.replace("StyledListView", "ListView").replace("                                animateAppearance: false\n", "")
        run_qml(self, '''
        property var settingsSearchResults: Array.from({length: 15}, (_, index) => index)
        property int settingsSearchIndex: 0
        Rectangle {
            width: 250
            height: 300
''' + view + '''
                delegate: Item { width: ListView.view.width; height: 44 }
            }
        }
        Timer {
            interval: 100
            running: true
            onTriggered: root.settingsSearchIndex = 14
        }
        Timer {
            interval: 300
            running: true
            onTriggered: {
                const view = settingsSearchResultsView;
                const last = view.itemAtIndex(14);
                root.check(view.count === 15, "all results remain available");
                root.check(view.contentY > 0, "selection scrolls beyond popup height");
                root.check(last && last.y >= view.contentY && last.y + last.height <= view.contentY + view.height,
                           "last result is fully visible");
                root.settingsSearchIndex = 0;
                root.check(view.contentY === 0, "upward selection reveals first result");
                root.settingsSearchResults = [];
                root.check(view.count === 0, "clearing query empties results");
                console.log("UI_TEST_DONE");
            }
        }
''')


if __name__ == "__main__":
    unittest.main()
