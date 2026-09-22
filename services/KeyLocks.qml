pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Tracks Caps Lock and Num Lock state by passively watching keyboard LED
 * events from /dev/input (scripts/keylocks/watch-led.py). We cannot bind the
 * lock keys in niri, because niri consumes any bound key and the lock would
 * never toggle; the watcher observes the real LED state without stealing keys.
 */
Singleton {
    id: root

    readonly property string watcherPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/keylocks/watch-led.py`)

    property bool capsLock: false
    property bool numLock: false
    // False until the startup snapshot has been applied, so we do not flash an
    // OSD on shell launch.
    property bool ready: false

    signal showCapsLockOsd(bool state)
    signal showNumLockOsd(bool state)

    Process {
        id: watcher
        running: true
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
}
