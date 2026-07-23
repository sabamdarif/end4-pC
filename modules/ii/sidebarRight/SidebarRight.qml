import qs
import qs.services
import qs.modules.common
import QtQuick
import Quickshell.Io
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    property int sidebarWidth: Appearance.sizes.sidebarWidth
    readonly property bool centerOnly: Config.options.bar.layouts.leftLayout.length === 0 && Config.options.bar.layouts.rightLayout.length === 0 && !Config.options.bar.vertical

    // Niri: full-screen transparent click-catcher to dismiss sidebar when clicking outside
    PanelWindow {
        id: dismissCatcher
        visible: GlobalStates.sidebarRightOpen && NiriData.isNiri
        color: "transparent"

        WlrLayershell.namespace: "quickshell:sidebarRight:dismiss"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        mask: Region {
            item: catchArea
            Region {
                item: sidebarHole
                intersection: Intersection.Subtract
            }
        }

        Rectangle {
            id: catchArea
            visible: false
            anchors.fill: parent
        }

        Rectangle {
            id: sidebarHole
            visible: false
            x: parent.width - root.sidebarWidth
            y: 0
            width: root.sidebarWidth
            height: parent.height
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: false
            onClicked: {
                GlobalFocusGrab.dismiss();
            }
        }
    }

    PanelWindow {
        id: panelWindow
        visible: GlobalStates.sidebarRightOpen

        function hide() {
            GlobalStates.sidebarRightOpen = false;
        }

        exclusiveZone: 0
        implicitWidth: sidebarWidth
        WlrLayershell.namespace: "quickshell:sidebarRight"
        WlrLayershell.keyboardFocus: GlobalStates.sidebarRightOpen
            ? (NiriData.isNiri ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand)
            : WlrKeyboardFocus.None
        color: "transparent"

        anchors {
            top: true
            right: true
            bottom: true
        }

        margins {
            top: {
                if (!centerOnly) return 0;
                switch (Config.options.bar.cornerStyle) {
                    case 0: return -Appearance.sizes.barHeight;
                    case 1: return -Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut;
                    case 2: return -Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut;
                    case 3: return -Appearance.sizes.barHeight - Appearance.sizes.hyprlandGapsOut;
                    default: return 0;
                }
            }
        }

        onVisibleChanged: {
            if (visible) {
                GlobalFocusGrab.addDismissable(panelWindow);
            } else {
                GlobalFocusGrab.removeDismissable(panelWindow);
            }
        }
        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                panelWindow.hide();
            }
        }

        Loader {
            id: sidebarContentLoader
            active: GlobalStates.sidebarRightOpen || Config?.options.sidebar.keepRightSidebarLoaded
            anchors {
                fill: parent
                margins: Appearance.sizes.hyprlandGapsOut
                leftMargin: Appearance.sizes.elevationMargin
            }
            width: sidebarWidth - Appearance.sizes.hyprlandGapsOut - Appearance.sizes.elevationMargin
            height: parent.height - Appearance.sizes.hyprlandGapsOut * 2

            focus: GlobalStates.sidebarRightOpen
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    panelWindow.hide();
                }
            }

            sourceComponent: SidebarRightContent {}
        }
    }

    IpcHandler {
        target: "sidebarRight"

        function toggle(): void {
            GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
        }

        function close(): void {
            GlobalStates.sidebarRightOpen = false;
        }

        function open(): void {
            GlobalStates.sidebarRightOpen = true;
        }
    }

    NiriSafeShortcut {
        name: "sidebarRightToggle"
        description: "Toggles right sidebar on press"

        onPressed: {
            GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
        }
    }
    NiriSafeShortcut {
        name: "sidebarRightOpen"
        description: "Opens right sidebar on press"

        onPressed: {
            GlobalStates.sidebarRightOpen = true;
        }
    }
    NiriSafeShortcut {
        name: "sidebarRightClose"
        description: "Closes right sidebar on press"

        onPressed: {
            GlobalStates.sidebarRightOpen = false;
        }
    }
}
