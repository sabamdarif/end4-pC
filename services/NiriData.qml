pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Provides real-time Niri workspace and window data via Niri IPC.
 */
Singleton {
    id: root

    readonly property bool isNiri: Quickshell.env("NIRI_SOCKET") !== ""

    property var workspaces: []
    property var workspaceById: ({})
    property var windows: []

    property int activeWorkspaceIdx: {
        const active = workspaces.find(ws => ws.is_active || ws.is_focused);
        return active ? active.idx : 1;
    }
    property int activeWorkspaceId: {
        const active = workspaces.find(ws => ws.is_active || ws.is_focused);
        return active ? active.id : 1;
    }
    property int workspaceCount: Math.max(1, workspaces.length)

    function updateWorkspaces() {
        if (!isNiri) return;
        getWorkspaces.running = true;
    }

    function updateWindows() {
        if (!isNiri) return;
        getWindows.running = true;
    }

    function updateAll() {
        if (!isNiri) return;
        updateWorkspaces();
        updateWindows();
    }

    function focusWorkspace(workspaceIdxOrId) {
        if (!isNiri) return;
        dispatchProcess.command = ["niri", "msg", "action", "focus-workspace", String(workspaceIdxOrId)];
        dispatchProcess.running = true;
    }

    function focusWorkspaceDown() {
        if (!isNiri) return;
        dispatchProcess.command = ["niri", "msg", "action", "focus-workspace-down"];
        dispatchProcess.running = true;
    }

    function focusWorkspaceUp() {
        if (!isNiri) return;
        dispatchProcess.command = ["niri", "msg", "action", "focus-workspace-up"];
        dispatchProcess.running = true;
    }

    function biggestWindowForWorkspace(workspaceId) {
        const windowsInWs = windows.filter(w => w.workspace_id == workspaceId);
        if (windowsInWs.length === 0) return null;
        return windowsInWs.reduce((maxWin, win) => {
            const maxW = maxWin?.layout?.tile_size?.[0] ?? maxWin?.layout?.window_size?.[0] ?? 0;
            const maxH = maxWin?.layout?.tile_size?.[1] ?? maxWin?.layout?.window_size?.[1] ?? 0;
            const maxArea = maxW * maxH;

            const winW = win?.layout?.tile_size?.[0] ?? win?.layout?.window_size?.[0] ?? 0;
            const winH = win?.layout?.tile_size?.[1] ?? win?.layout?.window_size?.[1] ?? 0;
            const winArea = winW * winH;

            return winArea > maxArea ? win : maxWin;
        }, null);
    }

    Component.onCompleted: {
        if (isNiri) {
            updateAll();
        }
    }

    Process {
        id: dispatchProcess
        command: []
    }

    Process {
        id: getWorkspaces
        command: ["niri", "msg", "-j", "workspaces"]
        stdout: StdioCollector {
            id: workspacesCollector
            onStreamFinished: {
                try {
                    var rawWorkspaces = JSON.parse(workspacesCollector.text);
                    if (Array.isArray(rawWorkspaces)) {
                        rawWorkspaces.sort((a, b) => a.idx - b.idx);
                        root.workspaces = rawWorkspaces;

                        let map = {};
                        for (var i = 0; i < rawWorkspaces.length; ++i) {
                            var ws = rawWorkspaces[i];
                            map[ws.id] = ws;
                        }
                        root.workspaceById = map;
                    }
                } catch (e) {
                    console.log("NiriData: Error parsing workspaces:", e);
                }
            }
        }
    }

    Process {
        id: getWindows
        command: ["niri", "msg", "-j", "windows"]
        stdout: StdioCollector {
            id: windowsCollector
            onStreamFinished: {
                try {
                    var rawWindows = JSON.parse(windowsCollector.text);
                    if (Array.isArray(rawWindows)) {
                        root.windows = rawWindows;
                    }
                } catch (e) {
                    console.log("NiriData: Error parsing windows:", e);
                }
            }
        }
    }

    Process {
        id: eventStreamProcess
        command: ["niri", "msg", "event-stream"]
        running: root.isNiri
        stdout: SplitParser {
            onRead: line => {
                root.updateAll();
            }
        }
    }
}
