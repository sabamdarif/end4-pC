import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

/**
 * Standalone clipboard manager. Separate from the app launcher on purpose:
 * the launcher no longer has a clipboard prefix.
 */
Scope {
    id: root

    PanelWindow {
        id: panelWindow
        visible: GlobalStates.clipboardOpen

        WlrLayershell.namespace: "quickshell:clipboard"
        WlrLayershell.layer: WlrLayer.Overlay
        // niri has no focus-grab protocol, so OnDemand never routes keys to the layer surface.
        WlrLayershell.keyboardFocus: GlobalStates.clipboardOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"

        BackgroundEffect.blurRegion: (Appearance.blurActive && GlobalStates.clipboardOpen && contentLoader.item)
            ? clipboardBlurRegion : null
        Region {
            id: clipboardBlurRegion
            x: Math.round(contentLoader.x + Appearance.sizes.elevationMargin)
            y: Math.round(contentLoader.y + Appearance.sizes.elevationMargin)
            width: Math.max(0, contentLoader.width - Appearance.sizes.elevationMargin * 2)
            height: Math.max(0, contentLoader.height - Appearance.sizes.elevationMargin * 2)
            radius: Appearance.rounding.screenRounding + 5
        }

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // No mask: the panel is modal, so a click anywhere outside the card dismisses it
        // instead of falling through to whatever is underneath.
        MouseArea {
            anchors.fill: parent
            enabled: GlobalStates.clipboardOpen
            onClicked: GlobalStates.clipboardOpen = false
        }

        Connections {
            target: GlobalStates
            function onClipboardOpenChanged() {
                if (!GlobalStates.clipboardOpen) {
                    GlobalFocusGrab.dismiss();
                    return;
                }
                GlobalFocusGrab.addDismissable(panelWindow);
            }
        }

        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                GlobalStates.clipboardOpen = false;
            }
        }

        // Content (including decoded history thumbnails) is destroyed on close to free memory.
        Loader {
            id: contentLoader
            width: Appearance.sizes.clipboardPanelWidth
            height: Appearance.sizes.clipboardPanelHeight
            anchors.centerIn: parent
            active: GlobalStates.clipboardOpen
            sourceComponent: ClipboardContent {
                anchors.fill: parent
                Component.onCompleted: {
                    Cliphist.refresh();
                    reset();
                }
            }
        }
    }

    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            GlobalStates.clipboardOpen = !GlobalStates.clipboardOpen;
        }

        function open(): void {
            GlobalStates.clipboardOpen = true;
        }

        function close(): void {
            GlobalStates.clipboardOpen = false;
        }
    }
}
