pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Tracks Caps Lock and Num Lock states and handles OSD trigger IPC.
 */
Singleton {
    id: root

    property bool capsLock: false
    property bool numLock: false
    property bool ready: false

    signal showCapsLockOsd(bool state)
    signal showNumLockOsd(bool state)

    function triggerCapsLock(): void {
        root.capsLock = !root.capsLock;
        root.showCapsLockOsd(root.capsLock);
    }

    function setCapsLock(state: bool): void {
        root.capsLock = state;
        root.showCapsLockOsd(root.capsLock);
    }

    function triggerNumLock(): void {
        root.numLock = !root.numLock;
        root.showNumLockOsd(root.numLock);
    }

    function setNumLock(state: bool): void {
        root.numLock = state;
        root.showNumLockOsd(root.numLock);
    }

    Process {
        id: initProc
        command: ["sh", "-c", "echo \"$(cat /sys/class/leds/*::capslock/brightness 2>/dev/null | head -1) $(cat /sys/class/leds/*::numlock/brightness 2>/dev/null | head -1)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(/\s+/);
                if (parts.length >= 2) {
                    if (parts[0] !== "") root.capsLock = (parseInt(parts[0]) || 0) > 0;
                    if (parts[1] !== "") root.numLock = (parseInt(parts[1]) || 0) > 0;
                }
                root.ready = true;
            }
        }
        Component.onCompleted: running = true
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
