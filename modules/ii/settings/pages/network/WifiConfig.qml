import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    function wifiSignalIcon(strength) {
        return strength > 80 ? "signal_wifi_4_bar"
            : strength > 60 ? "network_wifi_3_bar"
            : strength > 40 ? "network_wifi_2_bar"
            : strength > 20 ? "network_wifi_1_bar"
            : "signal_wifi_0_bar"
    }

    ContentSection {
        icon: "wifi"
        shape: MaterialShape.Shape.Circle
        title: Translation.tr("Wi-Fi")

        GroupedList {
            ConfigSwitch {
                id: wifiEnableSwitch
                buttonIcon: "wifi"
                text: Translation.tr("Enable Wi-Fi")
                checked: Network.wifiEnabled
                onCheckedChanged: {
                    if (checked !== Network.wifiEnabled)
                        Network.enableWifi(checked)
                }
                // Clicking breaks the `checked` binding — re-sync when the
                // state changes elsewhere (sidebar toggle, nmcli, hardware)
                Connections {
                    target: Network
                    function onWifiEnabledChanged() {
                        wifiEnableSwitch.checked = Network.wifiEnabled
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
                    text: Network.wifiScanning
                        ? Translation.tr("Scanning for networks…")
                        : Translation.tr("%1 networks found").arg(Network.wifiNetworks.length)
                    color: Appearance.colors.colOnSecondaryContainer
                }
                RippleButtonWithIcon {
                    materialIcon: "refresh"
                    mainText: Translation.tr("Scan")
                    enabled: Network.wifiEnabled && !Network.wifiScanning
                    onClicked: Network.rescanWifi()
                }
            }
        }

        // Dynamic list: NOT inside GroupedList (it reparents static
        // children only) — card + ColumnLayout + Repeater instead
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: wifiListCol.implicitHeight + 20
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1

            ColumnLayout {
                id: wifiListCol
                anchors { fill: parent; margins: 10 }
                spacing: 2

                StyledText {
                    visible: Network.friendlyWifiNetworks.length === 0
                    Layout.leftMargin: 8
                    text: Network.wifiEnabled ? Translation.tr("No networks found") : Translation.tr("Wi-Fi is disabled")
                    color: Appearance.colors.colSubtext
                }

                Repeater {
                    model: Network.friendlyWifiNetworks
                    delegate: ColumnLayout {
                        id: wifiRow
                        required property var modelData
                        readonly property bool known: NetworkExtras.isKnownWifi(modelData.ssid)
                        property bool confirmingForget: false
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            RippleButton {
                                Layout.fillWidth: true
                                implicitHeight: 44
                                buttonRadius: Appearance.rounding.small
                                colBackground: "transparent"
                                onClicked: {
                                    if (wifiRow.modelData.active)
                                        Network.disconnectWifiNetwork()
                                    else
                                        Network.connectToWifiNetwork(wifiRow.modelData)
                                }
                                StyledToolTip {
                                    text: wifiRow.modelData.active ? Translation.tr("Click to disconnect") : Translation.tr("Click to connect")
                                }
                                contentItem: RowLayout {
                                    spacing: 10
                                    MaterialSymbol {
                                        text: page.wifiSignalIcon(wifiRow.modelData.strength)
                                        iconSize: Appearance.font.pixelSize.huge
                                        color: Appearance.colors.colOnSecondaryContainer
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        StyledText {
                                            Layout.fillWidth: true
                                            text: wifiRow.modelData.ssid
                                            elide: Text.ElideRight
                                            color: Appearance.colors.colOnSecondaryContainer
                                        }
                                        StyledText {
                                            Layout.fillWidth: true
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.colors.colSubtext
                                            text: {
                                                let parts = []
                                                parts.push(wifiRow.modelData.isSecure ? wifiRow.modelData.security : Translation.tr("Open"))
                                                if (wifiRow.modelData.active) parts.push(Translation.tr("Connected"))
                                                else if (Network.wifiConnectTarget === wifiRow.modelData) parts.push(Translation.tr("Connecting…"))
                                                if (wifiRow.known) parts.push(Translation.tr("Saved"))
                                                return parts.join(" • ")
                                            }
                                        }
                                    }
                                    MaterialSymbol {
                                        visible: wifiRow.modelData.active
                                        text: "check_circle"
                                        iconSize: Appearance.font.pixelSize.larger
                                        color: Appearance.colors.colPrimary
                                    }
                                    MaterialSymbol {
                                        visible: !wifiRow.modelData.active && wifiRow.modelData.isSecure
                                        text: "lock"
                                        iconSize: Appearance.font.pixelSize.larger
                                        color: Appearance.colors.colSubtext
                                    }
                                }
                            }

                            // Autoconnect toggle (saved networks only)
                            StyledSwitch {
                                visible: wifiRow.known
                                checked: NetworkExtras.autoconnectFor(wifiRow.modelData.ssid)
                                onClicked: NetworkExtras.setAutoconnect(wifiRow.modelData.ssid, checked)
                                StyledToolTip {
                                    text: Translation.tr("Connect automatically")
                                }
                            }

                            // Forget (saved networks only), two-step confirm
                            RippleButtonWithIcon {
                                visible: wifiRow.known && !wifiRow.confirmingForget
                                materialIcon: "delete"
                                mainText: ""
                                onClicked: wifiRow.confirmingForget = true
                                StyledToolTip {
                                    text: Translation.tr("Forget this network")
                                }
                            }
                            DialogButton {
                                visible: wifiRow.confirmingForget
                                buttonText: Translation.tr("Forget?")
                                colText: Appearance.m3colors.m3error
                                onClicked: {
                                    wifiRow.confirmingForget = false
                                    NetworkExtras.forgetWifi(wifiRow.modelData.ssid)
                                }
                            }
                            DialogButton {
                                visible: wifiRow.confirmingForget
                                buttonText: Translation.tr("Cancel")
                                onClicked: wifiRow.confirmingForget = false
                            }
                        }

                        // PSK prompt (appears when connecting to a secured
                        // network whose secrets nmcli doesn't have yet)
                        ColumnLayout {
                            visible: wifiRow.modelData.askingPassword
                            Layout.fillWidth: true
                            Layout.leftMargin: 40
                            Layout.bottomMargin: 6

                            MaterialTextField {
                                id: pskField
                                Layout.fillWidth: true
                                placeholderText: Translation.tr("Password")
                                echoMode: TextInput.Password
                                inputMethodHints: Qt.ImhSensitiveData
                                onAccepted: Network.changePassword(wifiRow.modelData, pskField.text)
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Item { Layout.fillWidth: true }
                                DialogButton {
                                    buttonText: Translation.tr("Cancel")
                                    onClicked: wifiRow.modelData.askingPassword = false
                                }
                                DialogButton {
                                    buttonText: Translation.tr("Connect")
                                    onClicked: Network.changePassword(wifiRow.modelData, pskField.text)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
