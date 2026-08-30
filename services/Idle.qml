pragma Singleton
import qs
import qs.services
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Wayland

Singleton {
    id: root

    property alias inhibit: idleInhibitor.enabled
    inhibit: false

    // Keep-awake durations offered by the quick toggle menu, in minutes
    readonly property list<int> inhibitDurations: [15, 30, 60, 0]
    // Last duration picked in the menu, reused when the toggle is switched on without picking one
    readonly property int inhibitDurationMinutes: Persistent.states.idle.durationMinutes
    // Epoch seconds when the running inhibit ends. 0 means it lasts until switched off, here and above.
    readonly property int inhibitUntil: Persistent.states.idle.inhibitUntil

    property int nowSeconds: Math.floor(Date.now() / 1000)
    readonly property int inhibitSecondsLeft: (root.inhibit && root.inhibitUntil > 0) ? Math.max(0, root.inhibitUntil - root.nowSeconds) : 0
    readonly property string inhibitStatusText: {
        if (!root.inhibit) return Translation.tr("Off");
        if (root.inhibitUntil <= 0) return Translation.tr("On");
        return Translation.tr("%1 min left").arg(Math.ceil(root.inhibitSecondsLeft / 60));
    }

    function inhibitDurationLabel(minutes) {
        if (minutes <= 0) return Translation.tr("Infinite");
        if (minutes < 60) return Translation.tr("%1 minutes").arg(minutes);
        return Translation.tr("%1 hour").arg(minutes / 60);
    }

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

    Timer {
        running: root.inhibit && root.inhibitUntil > 0
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.nowSeconds = Math.floor(Date.now() / 1000);
            if (root.nowSeconds >= root.inhibitUntil) root.toggleInhibit(false);
        }
    }

    Connections {
        target: Persistent
        function onReadyChanged() {
            if (Persistent.isNewCompositorInstance) {
                Persistent.states.idle.inhibit = root.inhibit;
                Persistent.states.idle.inhibitUntil = 0;
                return;
            }
            const until = Persistent.states.idle.inhibitUntil;
            root.nowSeconds = Math.floor(Date.now() / 1000);
            if (Persistent.states.idle.inhibit && (until <= 0 || root.nowSeconds < until)) {
                root.inhibit = true;
            } else {
                root.toggleInhibit(false);
            }
        }
    }

    // `minutes` also becomes the remembered duration; -1 reuses the remembered one.
    function toggleInhibit(active = null, minutes = -1) {
        const enable = (active !== null) ? active : !root.inhibit;
        if (minutes >= 0) Persistent.states.idle.durationMinutes = minutes;
        const duration = (minutes >= 0) ? minutes : root.inhibitDurationMinutes;
        root.nowSeconds = Math.floor(Date.now() / 1000);
        Persistent.states.idle.inhibitUntil = (enable && duration > 0) ? root.nowSeconds + duration * 60 : 0;
        root.inhibit = enable;
        Persistent.states.idle.inhibit = enable;
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
