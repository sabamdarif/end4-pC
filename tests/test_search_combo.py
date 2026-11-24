import shutil
import unittest

from ui_test_utils import qml_block, run_qml


@unittest.skipUnless(shutil.which("qs"), "Quickshell is required")
class SearchComboTests(unittest.TestCase):
    def test_navigation_skips_hidden_rows_and_accepts_selection(self):
        path = "modules/common/widgets/StyledComboBoxSearch.qml"
        actions = qml_block(path, "    function matchesSearch(", "    implicitHeight:")
        editing = qml_block(path, "                        onTextChanged:", "                        Keys.onDownPressed:")
        run_qml(self, '''
        property var model: [{displayName: "Alpha"}, {displayName: "Beta"}, {displayName: "Alpha Mono"}]
        property string textRole: "displayName"
        property string searchText: ""
        property int currentIndex: 0
        property int acceptedIndex: -1
        property bool closed: false
        signal activated(int index)
        onActivated: index => root.acceptedIndex = index
        property QtObject popup: QtObject { function close() { root.closed = true } }
        ListView {
            id: listView
            width: 200
            height: 80
            model: root.model
            delegate: Item {
                required property var modelData
                height: root.matchesSearch(modelData) ? 40 : 0
            }
        }
        TextField {
            id: searchField
''' + editing + '''
        }
''' + actions + '''
        Timer {
            interval: 100
            running: true
            onTriggered: {
                searchField.text = "alpha";
                root.check(listView.currentIndex === 0, "typing selects first match");
                root.moveSelection(1);
                root.check(listView.currentIndex === 2, "down skips hidden match");
                root.acceptSelection();
                root.check(root.acceptedIndex === 2 && root.closed, "accept commits highlighted match");
                root.moveSelection(-1);
                root.check(listView.currentIndex === 0, "up skips hidden match");
                root.moveSelection(-1);
                root.check(listView.currentIndex === 0, "up stays at first match");
                searchField.text = "missing";
                root.check(listView.currentIndex === -1, "no matches clear selection");
                root.closed = false;
                root.acceptSelection();
                root.check(!root.closed && root.acceptedIndex === 2, "empty result cannot commit");
                searchField.text = "";
                root.moveSelection(1);
                root.check(listView.currentIndex === 1, "unfiltered down selects next row");
                root.acceptSelection();
                root.check(root.acceptedIndex === 1, "unfiltered selection commits");
                console.log("UI_TEST_DONE");
            }
        }
''')


if __name__ == "__main__":
    unittest.main()
