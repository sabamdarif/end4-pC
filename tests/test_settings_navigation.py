import re
import shutil
import unittest

from ui_test_utils import REPOSITORY, qml_block, run_qml


class SettingsNavigationTests(unittest.TestCase):
    def test_island_settings_target_is_a_registered_leaf(self):
        island = (REPOSITORY / "modules/ii/bar/DiXIdle.qml").read_text()
        registry = (REPOSITORY / "modules/ii/settings/SettingsPages.qml").read_text()
        target = re.search(r'GlobalStates\.openSettingsAt\("([^"]+)"\)', island).group(1)
        leaves = re.findall(r'\{\s*key:\s*"([^"]+)"[^\n]*component:', registry)
        self.assertEqual(target, "right-sidebar")
        self.assertIn(target, leaves)

    @unittest.skipUnless(shutil.which("qs"), "Quickshell is required")
    def test_narrow_selection_collapses_rail_and_content_fits_viewport(self):
        navigation = qml_block("modules/ii/settings/SettingsContent.qml",
                               "    function selectLeaf(", "    Component.onCompleted:")
        navigation = navigation.replace("SettingsPages", "settingsPages")
        rail = qml_block("modules/ii/settings/SettingsContent.qml",
                         "    property bool railExpanded:", "    Connections {")
        sizing = qml_block("modules/common/widgets/ContentPage.qml",
                           "        width: root.forceWidth", "        anchors {")
        run_qml(self, '''
        property string currentLeaf: ""
        property bool showingProfile: false
        property bool forceWidth: false
        property real baseWidth: 600
        property real maxContentWidth: 1250
        property real horizontalPadding: 24
        function setGroupExpanded(key, value) {}
        property QtObject settingsPages: QtObject {
            id: settingsPages
            function leafIndex(key) { return key === "wifi" ? 0 : -1 }
            function groupOf(key) { return key === "wifi" ? "network" : "" }
        }
''' + navigation + rail + '''
        ColumnLayout {
            id: contentColumn
''' + sizing + '''
        }
        Timer {
            interval: 100
            running: true
            onTriggered: {
                root.width = 600;
                root.railExpanded = true;
                root.selectLeaf("wifi");
                root.check(!root.railExpanded && root.currentLeaf === "wifi", "narrow selection collapses rail");
                root.width = 900;
                root.railExpanded = true;
                root.selectLeaf("wifi");
                root.check(!root.railExpanded, "breakpoint selection collapses rail");
                root.width = 980;
                root.selectLeaf("wifi");
                root.check(root.railExpanded, "wide selection keeps rail expanded");
                root.width = 286;
                root.check(contentColumn.width === 238, "content respects narrow viewport padding");
                root.width = 30;
                root.check(contentColumn.width === 0, "tiny viewport cannot produce negative width");
                root.width = 2000;
                root.check(contentColumn.width === 1250, "wide content retains maximum width");
                root.forceWidth = true;
                root.check(contentColumn.width === 600, "explicit fixed width remains supported");
                console.log("UI_TEST_DONE");
            }
        }
''')


if __name__ == "__main__":
    unittest.main()
