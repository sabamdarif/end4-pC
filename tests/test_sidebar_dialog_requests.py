import shutil
import unittest

from ui_test_utils import qml_block, run_qml


@unittest.skipUnless(shutil.which("qs"), "Quickshell is required")
class SidebarDialogRequestTests(unittest.TestCase):
    def test_request_survives_lazy_sidebar_creation(self):
        request = qml_block("GlobalStates.qml", "    function openSidebarDialog(", "    property bool barOpen:")
        handler = qml_block("modules/ii/sidebarRight/SidebarRightContent.qml", "    function openPendingDialog(", "    readonly property MprisPlayer")
        handler = handler.replace("GlobalStates.requestedSidebarDialog", "root.requestedSidebarDialog")
        run_qml(self, '''
        property string requestedSidebarDialog: ""
        property bool sidebarRightOpen: false
        property string openedDialog: ""
        function openDialog(name) { root.openedDialog = name; }
''' + request + handler + '''
        Component.onCompleted: {
            root.openSidebarDialog("drives");
            root.check(root.sidebarRightOpen, "request opens the sidebar");
            root.check(root.requestedSidebarDialog === "drives", "request remains before content exists");
            root.openPendingDialog();
            root.check(root.openedDialog === "showDrivesDialog", "new content consumes the request");
            root.check(root.requestedSidebarDialog === "", "request is cleared after consumption");
            root.openSidebarDialog("screentime");
            root.openPendingDialog();
            root.check(root.openedDialog === "showScreenTimeDialog", "loaded sidebar handles wellbeing too");
            root.openSidebarDialog("unknown");
            root.openPendingDialog();
            root.check(root.openedDialog === "showScreenTimeDialog", "unknown requests do not open arbitrary properties");
            console.log("UI_TEST_DONE");
        }
''')
