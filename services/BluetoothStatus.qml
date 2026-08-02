pragma Singleton
pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property bool available: Bluetooth.adapters.values.length > 0
    readonly property bool enabled: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property BluetoothDevice firstActiveDevice: Bluetooth.defaultAdapter?.devices.values.find(device => device.connected) ?? null
    readonly property int activeDeviceCount: Bluetooth.defaultAdapter?.devices.values.filter(device => device.connected).length ?? 0
    readonly property bool connected: Bluetooth.devices.values.some(d => d.connected)

    function sortFunction(a, b) {
        // Ones with meaningful names before MAC addresses
        const macRegex = /^([0-9A-Fa-f]{2}-){5}[0-9A-Fa-f]{2}$/;
        const aIsMac = macRegex.test(a.name);
        const bIsMac = macRegex.test(b.name);
        if (aIsMac !== bIsMac)
            return aIsMac ? 1 : -1;

        // Alphabetical by name
        return a.name.localeCompare(b.name);
    }
    property list<var> connectedDevices: Bluetooth.devices.values.filter(d => d.connected).sort(sortFunction)
    property list<var> pairedButNotConnectedDevices: Bluetooth.devices.values.filter(d => d.paired && !d.connected).sort(sortFunction)
    property list<var> unpairedDevices: Bluetooth.devices.values.filter(d => !d.paired && !d.connected).sort(sortFunction)
    property list<var> friendlyDeviceList: [
        ...connectedDevices,
        ...pairedButNotConnectedDevices,
        ...unpairedDevices
    ]

    // Connect/disconnect feedback
    property var _prevConnectedNames: null
    onConnectedDevicesChanged: {
        const names = connectedDevices.map(d => d.name);
        if (_prevConnectedNames === null || !startupGrace.done) {
            _prevConnectedNames = names;
            return;
        }
        const added = names.filter(n => !_prevConnectedNames.includes(n));
        const removed = _prevConnectedNames.filter(n => !names.includes(n));
        _prevConnectedNames = names;
        added.forEach(name => root.connectionFeedback(true, name));
        removed.forEach(name => root.connectionFeedback(false, name));
    }

    function connectionFeedback(connected, name) {
        Quickshell.execDetached([
            "notify-send",
            connected ? Translation.tr("Bluetooth device connected") : Translation.tr("Bluetooth device disconnected"),
            name,
            "-a", "Shell",
            "--hint=int:transient:1",
        ]);
        if (Config.options.sounds.bluetooth)
            Audio.playSystemSound(connected ? "device-added" : "device-removed");
    }

    Timer {
        // Don't fire feedback for devices that are already connected when the shell starts
        id: startupGrace
        property bool done: false
        interval: 3000
        running: true
        onTriggered: done = true
    }
}
