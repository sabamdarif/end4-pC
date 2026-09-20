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

        mask: Region {
            item: contentLoader.item
        }

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Connections {
            target: GlobalStates
            function onOverviewOpenChanged() {
                if (!GlobalStates.overviewOpen) {
                    overviewScope.dontAutoCancelSearch = false;
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
                contentLoader.item.searchWidgetItem.setSearchingText(text);
                contentLoader.item.searchWidgetItem.focusFirstItem();
            } else {
                panelWindow.pendingSearchText = text;
            }
        }

        // Content is destroyed when the overview closes to free the launcher search tree.
        // A fresh SearchWidget starts empty, so no explicit cancel is needed on reopen.
        Loader {
            id: contentLoader
            anchors.centerIn: parent
            active: GlobalStates.overviewOpen
            onLoaded: {
                if (panelWindow.pendingSearchText !== "") {
                    item.searchWidgetItem.setSearchingText(panelWindow.pendingSearchText);
                    item.searchWidgetItem.focusFirstItem();
                    panelWindow.pendingSearchText = "";
                }
            }

            sourceComponent: Column {
                id: columnLayout
                spacing: 0
                property alias searchWidgetItem: searchWidget

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        GlobalStates.overviewOpen = false;
                    } else if (event.key === Qt.Key_Left) {
                        if (!searchWidget.searchingText)
                            NiriData.focusWorkspaceUp();
                    } else if (event.key === Qt.Key_Right) {
                        if (!searchWidget.searchingText)
                            NiriData.focusWorkspaceDown();
                    }
                }

                SearchWidget {
                    id: searchWidget
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    function toggleEmojis() {
        if (GlobalStates.overviewOpen && overviewScope.dontAutoCancelSearch) {
            GlobalStates.overviewOpen = false;
            return;
        }
        overviewScope.dontAutoCancelSearch = true;
        panelWindow.setSearchingText(Config.options.search.prefix.emojis);
        GlobalStates.overviewOpen = true;
    }

    function toggleSymbols() {
        if (GlobalStates.overviewOpen && overviewScope.dontAutoCancelSearch) {
            GlobalStates.overviewOpen = false;
            return;
        }
        overviewScope.dontAutoCancelSearch = true;
        panelWindow.setSearchingText(Config.options.search.prefix.symbols);
        GlobalStates.overviewOpen = true;
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
        function emojiToggle() {
            overviewScope.toggleEmojis();
        }
        function symbolsToggle() {
            overviewScope.toggleSymbols();
        }
    }
}