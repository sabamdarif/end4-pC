pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

/**
 * Tracks the panels that close when focus moves away, like the sidebars.
 * niri has no focus-grab protocol, so dismissal is driven by niri's focus and
 * workspace events instead.
 */ 
Singleton {
    id: root

    signal dismissed()

    property list<var> dismissable: []

    function dismiss() {
        root.dismissable = [];
        root.dismissed();
    }

    Component.onCompleted: {
        console.log("[GlobalFocusGrab] Initialized");
    }

    property int lastWindowIdOnOpen: -1

    function addDismissable(window) {
        if (root.dismissable.indexOf(window) === -1) {
            root.dismissable.push(window);
            root.lastWindowIdOnOpen = NiriData.focusedWindowId;
        }
    }

    function removeDismissable(window) {
        var index = root.dismissable.indexOf(window);
        if (index !== -1) {
            root.dismissable.splice(index, 1);
        }
    }

    Connections {
        target: NiriData
        function onFocusedWindowIdChanged() {
            if (root.dismissable.length === 0) return;
            if (NiriData.focusedWindowId !== root.lastWindowIdOnOpen && NiriData.focusedWindowId !== -1) {
                root.dismiss();
            }
        }
        function onActiveWorkspaceIdxChanged() {
            if (root.dismissable.length > 0) {
                root.dismiss();
            }
        }
    }
}
