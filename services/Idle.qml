pragma Singleton
import qs
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Wayland

Singleton {
    id: root

    property alias inhibit: idleInhibitor.enabled
    inhibit: false

    // Convert the human-readable timeout string to seconds (0 = disabled)
    readonly property int idleTimeoutSeconds: {
        switch (Config.options.lock.idleTimeout) {
            case "5 minutes":  return 300;
            case "10 minutes": return 600;
            case "20 minutes": return 1200;
            case "30 minutes": return 1800;
            default:           return 0; // "infinity" or unknown → disabled
        }
    }

    IdleMonitor {
        id: idleMonitor
        timeout: root.idleTimeoutSeconds
        enabled: root.idleTimeoutSeconds > 0
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle && !GlobalStates.screenLocked) {
                if (Config.options.lock.useSwaylock) {
                    Quickshell.execDetached(["bash", "-c", "pidof swaylock || swaylock"]);
                } else {
                    GlobalStates.screenLocked = true;
                }
            }
        }
    }

    Connections {
        target: Persistent
        function onReadyChanged() {
            if (!Persistent.isNewHyprlandInstance) {
                root.inhibit = Persistent.states.idle.inhibit;
            } else {
                Persistent.states.idle.inhibit = root.inhibit;
            }
        }
    }

    function toggleInhibit(active = null) {
        if (active !== null) {
            root.inhibit = active;
        } else {
            root.inhibit = !root.inhibit;
        }
        Persistent.states.idle.inhibit = root.inhibit;
    }

    IdleInhibitor {
        id: idleInhibitor
        window: PanelWindow {
            // Inhibitor requires a "visible" surface
            // Actually not lol
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            // Just in case...
            anchors {
                right: true
                bottom: true
            }
            // Make it not interactable
            mask: Region {
                item: null
            }
        }
    }
}
