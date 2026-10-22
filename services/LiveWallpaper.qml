pragma Singleton

import qs.modules.common
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string socketPrefix:
        `${Quickshell.env("XDG_RUNTIME_DIR") || "/run/user/1000"}/mpvpaper-`

    property bool available: false
    property bool paused: false

    readonly property bool pauseOnBattery: Config.options?.background.liveWallpaper.pauseOnBattery ?? false
    readonly property real pauseBelowPercent: Config.options?.background.liveWallpaper.pauseBelowPercent ?? 0

    function sendCommand(json) {
        if (!root.available) return;
        commandProc.command = ["bash", "-c",
            `for s in ${root.socketPrefix}*.sock; do [ -S "$s" ] || continue; `
            + `printf '%s\\n' '${json}' | socat - UNIX-CONNECT:"$s" >/dev/null 2>&1; done`];
        commandProc.running = true;
    }

    function setPaused(value) {
        root.paused = value;
        root.sendCommand(`{"command":["set_property","pause",${value}]}`);
    }

    function toggle() { root.setPaused(!root.paused) }
    function pause()  { root.setPaused(true) }
    function resume() { root.setPaused(false) }

    Process { id: commandProc }

    Process {
        id: pollProc
        running: true
        command: ["bash", "-c",
            `for s in ${root.socketPrefix}*.sock; do [ -S "$s" ] || continue; `
            + `printf '%s\\n' '{"command":["get_property","pause"]}' | socat -T1 - UNIX-CONNECT:"$s" 2>/dev/null | head -1; exit 0; done`]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim();
                if (line === "") {
                    root.available = false;
                    return;
                }
                try {
                    const reply = JSON.parse(line);
                    root.available = reply.error === "success";
                    if (root.available) root.paused = reply.data === true;
                } catch (e) {
                    root.available = false;
                }
            }
        }
    }

    Timer {
        running: true
        repeat: true
        interval: 4000
        onTriggered: pollProc.running = true
    }

    readonly property bool shouldPauseForPower: root.available
        && Battery.available && !Battery.isPluggedIn
        && (root.pauseOnBattery
            || (root.pauseBelowPercent > 0 && Battery.percentage * 100 <= root.pauseBelowPercent))

    onShouldPauseForPowerChanged: {
        if (root.shouldPauseForPower) root.pause();
        else if (root.paused) root.resume();
    }
}
