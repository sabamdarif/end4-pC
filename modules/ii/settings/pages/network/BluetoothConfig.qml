import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool poweredOn: page.adapter?.enabled ?? false
    readonly property bool scanning: page.adapter?.discovering ?? false
    readonly property var savedDevices: [
        ...BluetoothStatus.connectedDevices,
        ...BluetoothStatus.pairedButNotConnectedDevices
    ]

    function deviceName(device) {
        return device?.name || device?.deviceName || Translation.tr("Unknown device")
    }

    // Discovery drains both ends, so it only runs while this page is on screen.
    readonly property bool shouldScan: page.visible && page.poweredOn
    function applyScan(on) {
        // Writing the value bluez already has logs a warning, so compare first.
        const adapter = page.adapter
        if (!adapter || adapter.discovering === on)
            return
        adapter.discovering = on
    }
    onShouldScanChanged: page.applyScan(page.shouldScan)
    Component.onCompleted: page.applyScan(page.shouldScan)
    Component.onDestruction: page.applyScan(false)

    ContentSection {
        icon: "bluetooth"
        shape: MaterialShape.Shape.Circle
        title: Translation.tr("Bluetooth")

        GroupedList {
            ConfigSwitch {
                id: bluetoothEnableSwitch
                buttonIcon: "bluetooth"
                text: Translation.tr("Enable Bluetooth")
                enabled: BluetoothStatus.available
                checked: BluetoothStatus.enabled
                onCheckedChanged: {
                    if (checked !== BluetoothStatus.enabled)
                        BluetoothStatus.togglePower()
                }
                // Clicking breaks the `checked` binding, so re-sync it when the
                // state changes elsewhere (sidebar toggle, bluetoothctl, hardware)
                Connections {
                    target: BluetoothStatus
                    function onEnabledChanged() {
                        bluetoothEnableSwitch.checked = BluetoothStatus.enabled
                    }
                }
            }
            RowLayout {
                spacing: 10
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                MaterialSymbol {
                    text: "radar"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnSecondaryContainer
                }
                StyledText {
                    Layout.fillWidth: true
                    text: !BluetoothStatus.available ? Translation.tr("No Bluetooth adapter")
                        : page.scanning ? Translation.tr("Scanning for devices…")
                        : Translation.tr("%1 devices found").arg(BluetoothStatus.unpairedDevices.length)
                    color: Appearance.colors.colOnSecondaryContainer
                }
                RippleButtonWithIcon {
                    materialIcon: "refresh"
                    mainText: Translation.tr("Scan")
                    enabled: page.poweredOn && !page.scanning
                    onClicked: page.applyScan(true)
                }
            }
        }
    }

    ContentSection {
        icon: "bluetooth_searching"
        shape: MaterialShape.Shape.Arch
        title: Translation.tr("Available devices")

        // Dynamic list: NOT inside GroupedList (it reparents static children
        // only), so use a card with a ColumnLayout and a Repeater instead
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: availableCol.implicitHeight + 20
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1

            ColumnLayout {
                id: availableCol
                anchors { fill: parent; margins: 10 }
                spacing: 2

                StyledText {
                    visible: BluetoothStatus.unpairedDevices.length === 0
                    Layout.leftMargin: 8
                    text: page.poweredOn ? Translation.tr("No devices found") : Translation.tr("Bluetooth is off")
                    color: Appearance.colors.colSubtext
                }

                Repeater {
                    model: BluetoothStatus.unpairedDevices
                    delegate: RippleButton {
                        id: availableRow
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 48
                        buttonRadius: Appearance.rounding.small
                        colBackground: "transparent"
                        onClicked: {
                            const device = availableRow.modelData
                            if (!device) return
                            if (device.pairing)
                                device.cancelPair()
                            else
                                device.pair()
                        }
                        StyledToolTip {
                            text: availableRow.modelData.pairing ? Translation.tr("Click to cancel pairing") : Translation.tr("Click to pair")
                        }
                        contentItem: RowLayout {
                            spacing: 10
                            MaterialSymbol {
                                text: Icons.getBluetoothDeviceMaterialSymbol(availableRow.modelData.icon || "")
                                iconSize: Appearance.font.pixelSize.huge
                                color: Appearance.colors.colOnSecondaryContainer
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                StyledText {
                                    Layout.fillWidth: true
                                    text: page.deviceName(availableRow.modelData)
                                    elide: Text.ElideRight
                                    color: Appearance.colors.colOnSecondaryContainer
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                    elide: Text.ElideRight
                                    text: availableRow.modelData.pairing
                                        ? Translation.tr("Pairing…")
                                        : availableRow.modelData.address
                                }
                            }
                            MaterialSymbol {
                                text: "add_link"
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "bookmark"
        shape: MaterialShape.Shape.Clover4Leaf
        title: Translation.tr("Saved devices")

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: savedCol.implicitHeight + 20
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1

            ColumnLayout {
                id: savedCol
                anchors { fill: parent; margins: 10 }
                spacing: 2

                StyledText {
                    visible: page.savedDevices.length === 0
                    Layout.leftMargin: 8
                    text: Translation.tr("No paired devices")
                    color: Appearance.colors.colSubtext
                }

                Repeater {
                    model: page.savedDevices
                    delegate: RowLayout {
                        id: savedRow
                        required property var modelData
                        property bool confirmingForget: false
                        Layout.fillWidth: true
                        spacing: 6

                        RippleButton {
                            Layout.fillWidth: true
                            implicitHeight: 48
                            buttonRadius: Appearance.rounding.small
                            colBackground: "transparent"
                            onClicked: {
                                const device = savedRow.modelData
                                if (!device) return
                                if (device.connected)
                                    device.disconnect()
                                else
                                    device.connect()
                            }
                            StyledToolTip {
                                text: savedRow.modelData.connected ? Translation.tr("Click to disconnect") : Translation.tr("Click to connect")
                            }
                            contentItem: RowLayout {
                                spacing: 10
                                MaterialSymbol {
                                    text: Icons.getBluetoothDeviceMaterialSymbol(savedRow.modelData.icon || "")
                                    iconSize: Appearance.font.pixelSize.huge
                                    color: savedRow.modelData.connected ? Appearance.colors.colPrimary : Appearance.colors.colOnSecondaryContainer
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: page.deviceName(savedRow.modelData)
                                        elide: Text.ElideRight
                                        color: Appearance.colors.colOnSecondaryContainer
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colSubtext
                                        elide: Text.ElideRight
                                        text: {
                                            let parts = []
                                            if (savedRow.modelData.state === BluetoothDeviceState.Connecting) parts.push(Translation.tr("Connecting…"))
                                            else if (savedRow.modelData.state === BluetoothDeviceState.Disconnecting) parts.push(Translation.tr("Disconnecting…"))
                                            else parts.push(savedRow.modelData.connected ? Translation.tr("Connected") : Translation.tr("Paired"))
                                            if (BluetoothStatus.hasBattery(savedRow.modelData))
                                                parts.push(Math.round(savedRow.modelData.battery * 100) + "%")
                                            return parts.join(" • ")
                                        }
                                    }
                                }
                                MaterialSymbol {
                                    visible: savedRow.modelData.connected
                                    text: "check_circle"
                                    iconSize: Appearance.font.pixelSize.larger
                                    color: Appearance.colors.colPrimary
                                }
                            }
                        }

                        RippleButtonWithIcon {
                            visible: !savedRow.confirmingForget
                            materialIcon: "delete"
                            mainText: ""
                            onClicked: savedRow.confirmingForget = true
                            StyledToolTip {
                                text: Translation.tr("Forget this device")
                            }
                        }
                        DialogButton {
                            visible: savedRow.confirmingForget
                            buttonText: Translation.tr("Forget?")
                            colText: Appearance.m3colors.m3error
                            onClicked: {
                                savedRow.confirmingForget = false
                                savedRow.modelData?.forget()
                            }
                        }
                        DialogButton {
                            visible: savedRow.confirmingForget
                            buttonText: Translation.tr("Cancel")
                            onClicked: savedRow.confirmingForget = false
                        }
                    }
                }
            }
        }
    }
}
