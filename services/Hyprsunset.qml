pragma Singleton

import QtQuick
import qs.modules.common
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * Night light service supporting both hyprsunset (Hyprland) and wlsunset (Niri / Wayland).
 */
Singleton {
    id: root
    signal gammaChangeAttempt()

    readonly property bool useWlsunset: NiriData.isNiri || Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") === ""
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

    function applyWlsunset() {
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

    function startHyprsunset() {
        if (root.useWlsunset) return;
        Quickshell.execDetached(["bash", "-c", `pidof hyprsunset || hyprsunset`]);
    }

    function load() {
        if (!root.useWlsunset) {
            root.startHyprsunset();
        }
        if (Persistent.ready) {
            ensureState();
        }
    }

    Timer {
        id: updateHyprsunset
        interval: 100
        repeat: false
        onTriggered: {
            root.ensureState();
            root.setGamma(root.gamma);
        }
    }

    function enableTemperature() {
        root.temperatureActive = true;
        if (root.useWlsunset) {
            root.applyWlsunset();
        } else {
            root.startHyprsunset();
            Quickshell.execDetached(["bash", "-c", `hyprctl hyprsunset temperature ${root.colorTemperature}`]);
        }
    }

    function disableTemperature() {
        root.temperatureActive = false;
        if (root.useWlsunset) {
            root.applyWlsunset();
        } else {
            Quickshell.execDetached(["hyprctl", "hyprsunset", "identity"]);
        }
    }

    function setGamma(gamma) {
        root.gamma = Math.max(root.gammaLowerLimit, Math.min(100, gamma));
        root.gammaChangeAttempt();

        if (root.useWlsunset) {
            root.applyWlsunset();
        } else {
            root.startHyprsunset();
            Quickshell.execDetached(["bash", "-c", `hyprctl hyprsunset gamma ${root.gamma}`]);
        }
    }

    function fetchState() {
        fetchProc.running = true;
    }

    Process {
        id: fetchProc
        running: true
        command: root.useWlsunset ? ["pidof", "wlsunset"] : ["bash", "-c", "hyprctl hyprsunset temperature"]
        stdout: StdioCollector {
            id: stateCollector
            onStreamFinished: {
                const output = stateCollector.text.trim();
                if (root.useWlsunset) {
                    const isRunning = (output.length > 0);
                    if (Persistent.ready && !Persistent.states.nightLight?.userEnabled) {
                        if (isRunning) root.disableTemperature();
                    } else {
                        root.temperatureActive = isRunning;
                    }
                } else {
                    if (output.length == 0 || output.startsWith("Couldn't"))
                        root.temperatureActive = false;
                    else
                        root.temperatureActive = (output != "6500");
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
            if (root.useWlsunset) {
                root.applyWlsunset();
            } else {
                Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature", `${Config.options.light.night.colorTemperature}`]);
            }
        }
    }
}