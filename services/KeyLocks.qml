pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Service for tracking and triggering Caps Lock and Num Lock states and OSD notifications.
 */
Singleton {
    id: root

    property bool capsLock: false
    property bool numLock: false

    signal showCapsLockOsd(bool state)
    signal showNumLockOsd(bool state)

    function updateState(callback) {
        checkProc.pendingCallback = callback || null;
        checkProc.running = true;
    }

    function triggerCapsLock() {
        updateState(function() {
            root.showCapsLockOsd(root.capsLock);
        });
    }

    function triggerNumLock() {
        updateState(function() {
            root.showNumLockOsd(root.numLock);
        });
    }

    Component.onCompleted: {
        updateState(null);
    }

    // Periodic check to ensure state stays in sync
    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.updateState(null)
    }

    Process {
        id: checkProc
        property var pendingCallback: null
        command: ["sh", "-c", "cat /sys/class/leds/*::capslock/brightness 2>/dev/null | head -n1; cat /sys/class/leds/*::numlock/brightness 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                const lines = collector.text.trim().split("\n");
                if (lines.length >= 1 && lines[0] !== "") {
                    root.capsLock = parseInt(lines[0]) > 0;
                }
                if (lines.length >= 2 && lines[1] !== "") {
                    root.numLock = parseInt(lines[1]) > 0;
                }
                if (checkProc.pendingCallback) {
                    checkProc.pendingCallback();
                    checkProc.pendingCallback = null;
                }
            }
        }
    }

    IpcHandler {
        target: "keylocks"

        function capsLock() {
            root.triggerCapsLock();
        }

        function numLock() {
            root.triggerNumLock();
        }
    }
}
