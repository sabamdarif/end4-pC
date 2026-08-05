pragma Singleton
import qs
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/*
 * System updates service. Currently only supports Arch.
 */
Singleton {
    id: root

    property bool available: false
    property alias checking: checkUpdatesProc.running
    property int count: 0
    property int pacmanCount: 0
    property int aurCount: 0
    property int flatpakCount: 0
    
    readonly property bool updateAdvised: available && count > Config.options.updates.adviseUpdateThreshold
    readonly property bool updateStronglyAdvised: available && count > Config.options.updates.stronglyAdviseUpdateThreshold

    function load() {}
    function refresh() {
        if (!available) return;
        print("[Updates] Checking for system updates")
        checkUpdatesProc.running = true;
    }

    Timer {
        interval: Config.options.updates.checkInterval * 60 * 1000
        repeat: true
        running: Config.ready && Config.options.updates.enableCheck
        onTriggered: {
            print("[Updates] Periodic update check due")
            root.refresh();
        }
    }

    Process {
        id: checkAvailabilityProc
        running: Config.ready && Config.options.updates.enableCheck
        command: ["which", "checkupdates"]
        onExited: (exitCode, exitStatus) => {
            root.available = (exitCode === 0);
            root.refresh();
        }
    }

    Process {
        id: checkUpdatesProc
        command: ["bash", "-c", "pacman=$(checkupdates 2>/dev/null | wc -l); if command -v yay >/dev/null; then aur=$(yay -Qua 2>/dev/null | wc -l); elif command -v paru >/dev/null; then aur=$(paru -Qua 2>/dev/null | wc -l); else aur=0; fi; flatpak=$(flatpak remote-ls --updates 2>/dev/null | wc -l); printf '%s %s %s\\n' \"$pacman\" \"$aur\" \"$flatpak\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const counts = text.trim().split(/\\s+/).map(value => parseInt(value) || 0)
                root.pacmanCount = counts[0] ?? 0
                root.aurCount = counts[1] ?? 0
                root.flatpakCount = counts[2] ?? 0
                root.count = root.pacmanCount + root.aurCount + root.flatpakCount
            }
        }
    }
}
