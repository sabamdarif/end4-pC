pragma Singleton

import QtQuick
import qs.modules.common
import Quickshell
import Quickshell.Io

/**
 * Night light and gamma service, backed by wlsunset.
 */
Singleton {
    id: root
    signal gammaChangeAttempt()

    readonly property real gammaLowerLimit: 25

    property string from: Config.options?.light?.night?.from ?? "19:00" 
    property string to: Config.options?.light?.night?.to ?? "06:30"
    property bool automatic: Config.options?.light?.night?.automatic ?? true
    property int colorTemperature: Config.options?.light?.night?.colorTemperature ?? 5000
    property int gamma: 100
    property bool shouldBeOn
    property bool temperatureActive: false

    property int fromHour: Number(from.split(":")[0])
    property int fromMinute: Number(from.split(":")[1])
    property int toHour: Number(to.split(":")[0])
    property int toMinute: Number(to.split(":")[1])

    property int clockHour: DateTime.clock.hours
    property int clockMinute: DateTime.clock.minutes

    onClockMinuteChanged: reEvaluate()
    onAutomaticChanged: reEvaluate()

    Connections {
        target: Persistent
        function onReadyChanged() {
            if (Persistent.ready) {
                reEvaluate();
            }
        }
    }

    function inBetween(t, from, to) {
        if (from < to) {
            return (t >= from && t <= to);
        } else {
            // Wrapped around midnight
            return (t >= from || t <= to);
        }
    }

    function reEvaluate() {
        const t = clockHour * 60 + clockMinute;
        const from = fromHour * 60 + fromMinute;
        const to = toHour * 60 + toMinute;

        root.shouldBeOn = inBetween(t, from, to);
        ensureState();
    }

    onShouldBeOnChanged: ensureState()

    function ensureState() {
        if (!Persistent.ready) return;

        const isUserEnabled = Persistent.states.nightLight?.userEnabled ?? false;

        if (!isUserEnabled) {
            root.disableTemperature();
            return;
        }

        if (root.automatic) {
            if (root.shouldBeOn) {
                root.enableTemperature();
            } else {
                root.disableTemperature();
            }
        } else {
            root.enableTemperature();
        }
    }

    function apply() {
        const gammaFloat = (root.gamma / 100).toFixed(2);

        if (root.temperatureActive) {
            if (root.automatic) {
                const cmd = `pkill -x wlsunset 2>/dev/null; exec wlsunset -t ${root.colorTemperature} -T 6500 -s ${root.from} -S ${root.to} -g ${gammaFloat}`;
                Quickshell.execDetached(["bash", "-c", cmd]);
            } else {
                const cmd = `pkill -x wlsunset 2>/dev/null; exec wlsunset -t ${root.colorTemperature} -T 6500 -s 00:00 -S 00:01 -g ${gammaFloat}`;
                Quickshell.execDetached(["bash", "-c", cmd]);
            }
        } else {
            if (root.gamma < 100) {
                const cmd = `pkill -x wlsunset 2>/dev/null; exec wlsunset -t 6500 -T 6501 -g ${gammaFloat}`;
                Quickshell.execDetached(["bash", "-c", cmd]);
            } else {
                Quickshell.execDetached(["pkill", "-x", "wlsunset"]);
            }
        }
    }

    function load() {
        if (Persistent.ready) {
            ensureState();
        }
    }

    function enableTemperature() {
        root.temperatureActive = true;
        root.apply();
    }

    function disableTemperature() {
        root.temperatureActive = false;
        root.apply();
    }

    function setGamma(gamma) {
        root.gamma = Math.max(root.gammaLowerLimit, Math.min(100, gamma));
        root.gammaChangeAttempt();
        root.apply();
    }

    function fetchState() {
        fetchProc.running = true;
    }

    Process {
        id: fetchProc
        running: true
        command: ["pidof", "wlsunset"]
        stdout: StdioCollector {
            id: stateCollector
            onStreamFinished: {
                const isRunning = stateCollector.text.trim().length > 0;
                if (Persistent.ready && !Persistent.states.nightLight?.userEnabled) {
                    if (isRunning) root.disableTemperature();
                } else {
                    root.temperatureActive = isRunning;
                }
            }
        }
    }

    function toggleTemperature(active = undefined) {
        if (!Persistent.ready) return;

        const currentEnabled = Persistent.states.nightLight?.userEnabled ?? false;
        const targetState = (active !== undefined) ? active : !currentEnabled;

        Persistent.states.nightLight.userEnabled = targetState;

        if (targetState) {
            ensureState();
        } else {
            disableTemperature();
        }
    }

    // Change temp
    Connections {
        target: Config.options.light.night
        function onColorTemperatureChanged() {
            if (!root.temperatureActive) return;
            root.apply();
        }
    }
}