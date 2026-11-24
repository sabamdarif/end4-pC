pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io

Singleton {
    id: root

    readonly property bool available: Bluetooth.adapters.values.length > 0
    readonly property bool enabled: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property BluetoothDevice firstActiveDevice: Bluetooth.devices.values.find(device => device.connected) ?? null
    readonly property int activeDeviceCount: Bluetooth.devices.values.filter(device => device.connected).length
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
    readonly property list<var> connectedBatteryDevices: connectedDevices.filter(device => root.hasBattery(device))
    readonly property var primaryConnectedDevice: firstActiveDevice ?? connectedDevices[0] ?? null
    readonly property var primaryBatteryDevice: hasBattery(primaryConnectedDevice)
        ? primaryConnectedDevice
        : connectedBatteryDevices[0] ?? null
    property list<var> friendlyDeviceList: [
        ...connectedDevices,
        ...pairedButNotConnectedDevices,
        ...unpairedDevices
    ]

    function hasBattery(device): bool {
        return !!device && device.batteryAvailable && Number.isFinite(Number(device.battery));
    }

    function isConnected(device): bool {
        return !!device && (device.connected || device.state === BluetoothDeviceState.Connected);
    }

    function togglePower() {
        const adapter = Bluetooth.defaultAdapter;
        if (!adapter) return;
        // rfkill-blocked adapter won't power on — unblock first
        Quickshell.execDetached(["bash", "-c", "rfkill unblock bluetooth"]);
        adapter.enabled = !adapter.enabled;
        if (adapter.enabled) {
            adapter.pairable = true;
        }
    }

    function stopDiscovery() {
        const adapter = Bluetooth.defaultAdapter;
        if (adapter && adapter.discovering) {
            adapter.discovering = false;
        }
    }

    function trustDevice(device) {
        if (!device) return;
        try { device.trusted = true; } catch (e) {}
        Quickshell.execDetached(["bluetoothctl", "trust", device.address]);
    }

    function connectDevice(device) {
        if (!device) return;
        stopDiscovery();
        trustDevice(device);
        device.connect();
        Quickshell.execDetached(["bluetoothctl", "connect", device.address]);
    }

    function disconnectDevice(device) {
        if (!device) return;
        device.disconnect();
    }

    Connections {
        target: Bluetooth.defaultAdapter
        function onEnabledChanged() {
            if (Bluetooth.defaultAdapter?.enabled) {
                Bluetooth.defaultAdapter.pairable = true;
            }
        }
    }

    Component.onCompleted: {
        if (Bluetooth.defaultAdapter?.enabled) {
            Bluetooth.defaultAdapter.pairable = true;
        }
    }

    Instantiator {
        model: Bluetooth.devices
        delegate: Connections {
            required property BluetoothDevice modelData
            target: modelData
            function onPairedChanged() {
                if (modelData.paired && !modelData.trusted) {
                    root.trustDevice(modelData);
                }
            }
            function onStateChanged() {
                if (modelData.state === BluetoothDeviceState.Connecting) {
                    root.stopDiscovery();
                }
            }
            Component.onCompleted: {
                if (modelData.paired && !modelData.trusted) {
                    root.trustDevice(modelData);
                }
            }
        }
    }
}
