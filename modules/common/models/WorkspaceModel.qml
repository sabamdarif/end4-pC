import QtQuick
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.modules.common as C

NestableObject {
    id: root

    property HyprlandMonitor monitor: null
    readonly property var liveMonitorData: HyprlandData.monitors.find(m => m.id === monitor?.id)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

    readonly property bool isNiri: NiriData.isNiri
    readonly property int activeWorkspace: isNiri ? NiriData.activeWorkspaceIdx : (monitor?.activeWorkspace?.id ?? 1)
    readonly property bool currentWorkspaceNotFake: activeWindow?.activated ?? false // Active empty workspace = fake. At least, that's how I like to call it.
    readonly property int fakeWorkspace: currentWorkspaceNotFake ? -9999 : activeWorkspace
    readonly property int shownCount: isNiri ? NiriData.workspaceCount : C.Config.options.bar.workspaces.shown
    readonly property int group: isNiri ? 0 : Math.floor((activeWorkspace - 1) / shownCount)
    readonly property var specialWorkspace: liveMonitorData?.specialWorkspace
    readonly property string specialWorkspaceName: specialWorkspace?.name.replace("special:", "") ?? "special"
    readonly property bool specialWorkspaceActive: isNiri ? false : specialWorkspaceName !== ""

    property list<bool> occupied: []
    property list<var> biggestWindow: occupied.map((_, index) => {
        if (isNiri) {
            const ws = NiriData.workspaces[index];
            return ws ? NiriData.biggestWindowForWorkspace(ws.id) : null;
        }
        const wsId = getWorkspaceIdAt(index);
        var biggestWindow = HyprlandData.biggestWindowForWorkspace(wsId);
        return biggestWindow;
    })

    function getWorkspaceId(group, index) {
        if (isNiri) {
            return NiriData.workspaces[index]?.idx ?? (index + 1);
        }
        return group * root.shownCount + index + 1;
    }
    function getWorkspaceIdAt(index) {
        return root.getWorkspaceId(root.group, index);
    }

    // Function to update workspaceOccupied
    function updateWorkspaceOccupied() {
        if (isNiri) {
            root.occupied = Array.from({
                length: root.shownCount
            }, (_, i) => {
                const ws = NiriData.workspaces[i];
                if (!ws) return false;
                return (ws.active_window_id !== null && ws.active_window_id !== undefined) ||
                       NiriData.windows.some(w => w.workspace_id == ws.id);
            });
            return;
        }

        root.occupied = Array.from({
            length: root.shownCount
        }, (_, i) => {
            const thisWorkspaceId = getWorkspaceId(root.group, i);
            return Hyprland.workspaces.values.some(ws => ws.id === thisWorkspaceId);
        });
    }

    // Occupied workspace updates
    Component.onCompleted: updateWorkspaceOccupied()

    Connections {
        target: NiriData
        enabled: root.isNiri
        function onWorkspacesChanged() { root.updateWorkspaceOccupied(); }
        function onWindowsChanged() { root.updateWorkspaceOccupied(); }
    }

    Connections {
        target: Hyprland.workspaces
        enabled: !root.isNiri
        function onValuesChanged() {
            root.updateWorkspaceOccupied();
        }
    }
    Connections {
        target: Hyprland
        enabled: !root.isNiri
        function onFocusedWorkspaceChanged() {
            root.updateWorkspaceOccupied();
        }
    }
    onGroupChanged: {
        updateWorkspaceOccupied();
    }
}