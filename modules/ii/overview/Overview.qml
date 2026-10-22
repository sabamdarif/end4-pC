import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: overviewScope
    property bool dontAutoCancelSearch: false

    PanelWindow {
        id: panelWindow
        visible: GlobalStates.overviewOpen

        WlrLayershell.namespace: "quickshell:overview"
        // Keep the launcher above fullscreen and other application surfaces, like Caelestia's launcher.
        WlrLayershell.layer: WlrLayer.Overlay
        // niri has no focus-grab protocol, so OnDemand never routes keys to the layer surface.
        WlrLayershell.keyboardFocus: GlobalStates.overviewOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"

        property string pendingSearchText: ""

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // Full-window backdrop: a click anywhere outside the launcher card closes it.
        // The card itself swallows clicks (see SearchWidget) so they never reach here.
        MouseArea {
            anchors.fill: parent
            onClicked: GlobalStates.overviewOpen = false
        }

        Connections {
            target: GlobalStates
            function onOverviewOpenChanged() {
                if (!GlobalStates.overviewOpen) {
                    overviewScope.dontAutoCancelSearch = false;
                    LauncherSearch.query = "";
                    GlobalFocusGrab.dismiss();
                } else {
                    GlobalFocusGrab.addDismissable(panelWindow);
                }
            }
        }

        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                GlobalStates.overviewOpen = false;
            }
        }
        implicitWidth: contentLoader.implicitWidth
        implicitHeight: contentLoader.implicitHeight

        function setSearchingText(text) {
            if (contentLoader.item) {
                contentLoader.item.setSearchingText(text);
                contentLoader.item.focusSearchInput();
            } else {
                panelWindow.pendingSearchText = text;
            }
        }

        // Content is destroyed when the overview closes to free memory.
        Loader {
            id: contentLoader
            anchors.top: parent.top
            anchors.topMargin: Math.round(parent.height * 0.14)
            anchors.horizontalCenter: parent.horizontalCenter
            active: GlobalStates.overviewOpen
            onLoaded: {
                if (panelWindow.pendingSearchText !== "") {
                    item.setSearchingText(panelWindow.pendingSearchText);
                    panelWindow.pendingSearchText = "";
                }
                Qt.callLater(() => {
                    if (contentLoader.item)
                        contentLoader.item.focusSearchInput();
                });
            }

            sourceComponent: SearchWidget {
                id: searchWidget
            }
        }
    }

    IpcHandler {
        target: "search"

        function toggle() {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
        function workspacesToggle() {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
        function close() {
            GlobalStates.overviewOpen = false;
        }
        function open() {
            GlobalStates.overviewOpen = true;
        }
        function toggleReleaseInterrupt() {
            GlobalStates.superReleaseMightTrigger = false;
        }
    }
}