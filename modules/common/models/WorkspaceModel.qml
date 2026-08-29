import QtQuick
import Quickshell.Wayland
import qs.services

NestableObject {
    id: root

    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

    readonly property int activeWorkspace: NiriData.activeWorkspaceIdx
    readonly property bool currentWorkspaceNotFake: activeWindow?.activated ?? false // Active empty workspace = fake. At least, that's how I like to call it.
    readonly property int fakeWorkspace: currentWorkspaceNotFake ? -9999 : activeWorkspace
    readonly property int shownCount: NiriData.workspaceCount
    // niri numbers workspaces per output without grouping, so there is only one group.
    readonly property int group: 0

    property list<bool> occupied: []
    property list<var> biggestWindow: occupied.map((_, index) => {
        const ws = NiriData.workspaces[index];
        return ws ? NiriData.biggestWindowForWorkspace(ws.id) : null;
    })

    function getWorkspaceId(group, index) {
        return NiriData.workspaces[index]?.idx ?? (index + 1);
    }
    function getWorkspaceIdAt(index) {
        return root.getWorkspaceId(root.group, index);
    }

    // Function to update workspaceOccupied
    function updateWorkspaceOccupied() {
        root.occupied = Array.from({
            length: root.shownCount
        }, (_, i) => {
            const ws = NiriData.workspaces[i];
            if (!ws) return false;
            return (ws.active_window_id !== null && ws.active_window_id !== undefined) ||
                   NiriData.windows.some(w => w.workspace_id == ws.id);
        });
    }

    // Occupied workspace updates
    Component.onCompleted: updateWorkspaceOccupied()

    Connections {
        target: NiriData
        function onWorkspacesChanged() { root.updateWorkspaceOccupied(); }
        function onWindowsChanged() { root.updateWorkspaceOccupied(); }
    }
}
