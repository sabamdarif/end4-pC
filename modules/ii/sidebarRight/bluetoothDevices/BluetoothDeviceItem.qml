import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

DialogListItem {
    id: root
    required property var device
    readonly property bool connecting: (root.device?.pairing ?? false)
        || root.device?.state === BluetoothDeviceState.Connecting
    property bool expanded: false
    pointingHandCursor: !expanded

    onClicked: expanded = !expanded
    altAction: () => expanded = !expanded
    
    component ActionButton: DialogButton {
        colBackground: Appearance.colors.colPrimary
        colBackgroundHover: Appearance.colors.colPrimaryHover
        colRipple: Appearance.colors.colPrimaryActive
        colText: Appearance.colors.colOnPrimary
    }

    contentItem: ColumnLayout {
        anchors {
            fill: parent
            topMargin: root.verticalPadding
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
        }
        spacing: 0

        RowLayout {
            // Name
            spacing: 10

            MaterialSymbol {
                iconSize: Appearance.font.pixelSize.larger
                text: Icons.getBluetoothDeviceMaterialSymbol(root.device?.icon || "")
                color: Appearance.colors.colOnSurfaceVariant
            }

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                StyledText {
                    Layout.fillWidth: true
                    color: Appearance.colors.colOnSurfaceVariant
                    elide: Text.ElideRight
                    text: root.device?.name || Translation.tr("Unknown device")
                    textFormat: Text.PlainText
                }
                StyledText {
                    visible: text !== ""
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                    text: {
                        const device = root.device;
                        if (!device) return "";
                        if (device.pairing) return Translation.tr("Pairing…");
                        if (device.state === BluetoothDeviceState.Connecting) return Translation.tr("Connecting…");
                        if (device.state === BluetoothDeviceState.Disconnecting) return Translation.tr("Disconnecting…");
                        if (!device.paired) return "";
                        let statusText = device.connected ? Translation.tr("Connected") : Translation.tr("Paired");
                        if (!device.batteryAvailable) return statusText;
                        statusText += ` • ${Math.round(device.battery * 100)}%`;
                        return statusText;
                    }
                }
            }

            MaterialSymbol {
                text: "keyboard_arrow_down"
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnLayer3
                rotation: root.expanded ? 180 : 0
                Behavior on rotation {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }

        ConnectingWave {
            Layout.fillWidth: true
            Layout.topMargin: 4
            running: root.connecting
        }

        RowLayout {
            visible: root.expanded
            Layout.topMargin: 8
            Item {
                Layout.fillWidth: true
            }
            ActionButton {
                readonly property bool p: root.device?.paired ?? false
                colBackground: p ? Appearance.colors.colError : ColorUtils.transparentize(Appearance.colors.colLayer3, 1)
                colBackgroundHover: p ? Appearance.colors.colErrorHover : ColorUtils.transparentize(Appearance.colors.colLayer3, 1)
                colRipple: p ? Appearance.colors.colErrorActive : Appearance.colors.colLayer3Hover
                colText: p ? Appearance.colors.colOnError : Appearance.colors.colPrimary

                buttonText: p ? Translation.tr("Forget") : Translation.tr("Always connect")
                onClicked: {
                    const device = root.device;
                    if (!device) return;
                    if (device.paired) {
                        device.forget();
                    } else {
                        device.pair();
                    }
                }
            }
            ActionButton {
                buttonText: root.device?.connected ? Translation.tr("Disconnect") : Translation.tr("Connect")

                onClicked: {
                    const device = root.device;
                    if (!device) return;
                    if (device.connected) {
                        device.disconnect();
                    } else {
                        device.connect();
                    }
                }
            }
        }
        Item {
            Layout.fillHeight: true
        }
    }
}
