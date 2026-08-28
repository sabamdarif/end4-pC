pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services

/**
 * Manages a HyprlandFocusGrab that's to be shared by all windows.
 * "Persistent" is for windows that should always be included but not closed on dismiss, like bar and onscreen keyboard.
 * "Dismissable" is for stuff like sidebars.
 **/
 
Singleton {
    id: root

    signal dismissed()

    property list<var> persistent: []
    property list<var> dismissable: []

    function dismiss() {
        root.dismissable = [];
        root.dismissed();
    }

    Component.onCompleted: {
        console.log("[GlobalFocusGrab] Initialized" + (WM.compositor !== "hyprland" ? " (inactive, non-Hyprland compositor)" : ""));
    }

    function addPersistent(window) {
        if (root.persistent.indexOf(window) === -1) {
            root.persistent.push(window);
        }
    }

    function removePersistent(window) {
        var index = root.persistent.indexOf(window);
        if (index !== -1) {
            root.persistent.splice(index, 1);
        }
    }

    // Compositors without a focus-grab protocol (niri) fall back to watching the
    // focused window, so track which window was focused when the panel opened.
    readonly property string focusedWindowId: {
        const focused = WM.windowList.find(w => w.focused);
        return focused ? String(focused.id) : "";
    }
    property string lastWindowIdOnOpen: ""

    function addDismissable(window) {
        if (root.dismissable.indexOf(window) === -1) {
            root.dismissable.push(window);
            root.lastWindowIdOnOpen = root.focusedWindowId;
        }
    }

    function removeDismissable(window) {
        var index = root.dismissable.indexOf(window);
        if (index !== -1) {
            root.dismissable.splice(index, 1);
        }
    }

    function hasActive(element) {
        return element?.activeFocus || Array.from(
            element?.children ?? []
        ).some(
            (child) => hasActive(child)
        );
    }

    HyprlandFocusGrab {
        id: grab
        windows: root.dismissable.every(w => !w?.focusable) || root.dismissable.some(w => root.hasActive(w?.contentItem)) ? [...root.dismissable, ...root.persistent] : [...root.dismissable]
        active: WM.compositor === "hyprland" && root.dismissable.length > 0
        onCleared: () => {
            root.dismiss();
        }
    }

    onFocusedWindowIdChanged: {
        if (WM.compositor === "hyprland" || root.dismissable.length === 0) return;
        if (root.focusedWindowId !== root.lastWindowIdOnOpen && root.focusedWindowId !== "")
            root.dismiss();
    }

    Connections {
        target: WM
        enabled: WM.compositor !== "hyprland"
        function onActiveWorkspaceChanged() {
            if (root.dismissable.length > 0)
                root.dismiss();
        }
    }
}
