pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

/**
 * Tracks Caps Lock and Num Lock states and handles OSD trigger IPC.
 */
Singleton {
    id: root

    readonly property string watcherPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/keylocks/watch-led.py`)
    readonly property string toggleScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/keylocks/toggle-key.py`)

    property bool capsLock: false
    property bool numLock: false
    property bool ready: false

    signal showCapsLockOsd(bool state)
    signal showNumLockOsd(bool state)

    function triggerCapsLock(): void {
        toggleCapsProc.running = true;
    }

    function setCapsLock(state: bool): void {
        if (root.ready && root.capsLock === state) return;
        root.triggerCapsLock();
    }

    function triggerNumLock(): void {
        toggleNumProc.running = true;
    }

    function setNumLock(state: bool): void {
        if (root.ready && root.numLock === state) return;
        root.triggerNumLock();
    }

    Process {
        id: watcher
        running: Config.options.osd.enableCapsLock || Config.options.osd.enableNumLock
        onRunningChanged: {
            if (!running) root.ready = false;
        }
        command: ["python3", root.watcherPath]

        stdout: SplitParser {
            onRead: line => {
                const text = line.trim();
                if (text === "") return;
                if (text === "ready") {
                    root.ready = true;
                    return;
                }
                const parts = text.split(" ");
                if (parts.length < 2) return;
                const state = parseInt(parts[1]) > 0;
                if (parts[0] === "caps") {
                    root.capsLock = state;
                    if (root.ready) root.showCapsLockOsd(state);
                } else if (parts[0] === "num") {
                    root.numLock = state;
                    if (root.ready) root.showNumLockOsd(state);
                }
            }
        }
    }

    Process {
        id: toggleNumProc
        command: ["python3", root.toggleScriptPath, "num"]
    }

    Process {
        id: toggleCapsProc
        command: ["python3", root.toggleScriptPath, "caps"]
    }

    IpcHandler {
        target: "keylocks"

        function triggerCapsLock(): void { root.triggerCapsLock(); }
        function triggerNumLock(): void { root.triggerNumLock(); }
        function toggleCapsLock(): void { root.triggerCapsLock(); }
        function toggleNumLock(): void { root.triggerNumLock(); }
        function capsLock(): void { root.triggerCapsLock(); }
        function numLock(): void { root.triggerNumLock(); }
        function setCapsLock(state: bool): void { root.setCapsLock(state); }
        function setNumLock(state: bool): void { root.setNumLock(state); }
    }

    IpcHandler {
        target: "keyLocks"

        function triggerCapsLock(): void { root.triggerCapsLock(); }
        function triggerNumLock(): void { root.triggerNumLock(); }
        function toggleCapsLock(): void { root.triggerCapsLock(); }
        function toggleNumLock(): void { root.triggerNumLock(); }
        function capsLock(): void { root.triggerCapsLock(); }
        function numLock(): void { root.triggerNumLock(); }
        function setCapsLock(state: bool): void { root.setCapsLock(state); }
        function setNumLock(state: bool): void { root.setNumLock(state); }
    }

    IpcHandler {
        target: "capslock"

        function trigger(): void { root.triggerCapsLock(); }
        function toggle(): void { root.triggerCapsLock(); }
        function set(state: bool): void { root.setCapsLock(state); }
    }

    IpcHandler {
        target: "numlock"

        function trigger(): void { root.triggerNumLock(); }
        function toggle(): void { root.triggerNumLock(); }
        function set(state: bool): void { root.setNumLock(state); }
    }
}
