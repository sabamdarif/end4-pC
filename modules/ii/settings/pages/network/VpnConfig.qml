import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    Component.onCompleted: NetworkExtras.refresh()

    ContentSection {
        icon: "vpn_lock"
        shape: MaterialShape.Shape.Pill
        title: Translation.tr("VPN")

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: vpnCol.implicitHeight + 20
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1

            ColumnLayout {
                id: vpnCol
                anchors { fill: parent; margins: 10 }
                spacing: 2

                StyledText {
                    visible: NetworkExtras.vpnConnections.length === 0
                    Layout.leftMargin: 8
                    text: Translation.tr("No VPN connections configured")
                    color: Appearance.colors.colSubtext
                }

                Repeater {
                    model: NetworkExtras.vpnConnections
                    delegate: RowLayout {
                        id: vpnRow
                        required property var modelData
                        property bool confirmingDelete: false
                        Layout.fillWidth: true
                        spacing: 10

                        MaterialSymbol {
                            Layout.leftMargin: 8
                            text: "vpn_key"
                            iconSize: Appearance.font.pixelSize.huge
                            color: vpnRow.modelData.active ? Appearance.colors.colPrimary : Appearance.colors.colOnSecondaryContainer
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText {
                                Layout.fillWidth: true
                                text: vpnRow.modelData.name
                                elide: Text.ElideRight
                                color: Appearance.colors.colOnSecondaryContainer
                            }
                            StyledText {
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                                text: (vpnRow.modelData.type === "wireguard" ? "WireGuard" : "VPN")
                                    + (vpnRow.modelData.active ? " • " + Translation.tr("Connected") : "")
                            }
                        }

                        RippleButtonWithIcon {
                            visible: !vpnRow.confirmingDelete
                            materialIcon: vpnRow.modelData.active ? "link_off" : "link"
                            mainText: vpnRow.modelData.active ? Translation.tr("Disconnect") : Translation.tr("Connect")
                            onClicked: {
                                if (vpnRow.modelData.active)
                                    NetworkExtras.vpnDown(vpnRow.modelData.name)
                                else
                                    NetworkExtras.vpnUp(vpnRow.modelData.name)
                            }
                        }
                        RippleButtonWithIcon {
                            visible: !vpnRow.confirmingDelete
                            materialIcon: "delete"
                            mainText: ""
                            onClicked: vpnRow.confirmingDelete = true
                            StyledToolTip {
                                text: Translation.tr("Delete this VPN connection")
                            }
                        }
                        DialogButton {
                            visible: vpnRow.confirmingDelete
                            buttonText: Translation.tr("Delete?")
                            colText: Appearance.m3colors.m3error
                            onClicked: {
                                vpnRow.confirmingDelete = false
                                NetworkExtras.vpnDelete(vpnRow.modelData.name)
                            }
                        }
                        DialogButton {
                            visible: vpnRow.confirmingDelete
                            buttonText: Translation.tr("Cancel")
                            onClicked: vpnRow.confirmingDelete = false
                        }
                    }
                }
            }
        }

        GroupedList {
            ConfigTextArea {
                id: vpnImportField
                buttonIcon: "download"
                text: Translation.tr("Import VPN config")
                description: Translation.tr(".ovpn (OpenVPN) or .conf (WireGuard) file path")
                placeholderText: Translation.tr("/path/to/vpn-config.ovpn")
                confirmButtonVisible: vpnImportField.value.trim() !== ""
                confirmButtonIcon: "add"
                onConfirmClicked: {
                    NetworkExtras.vpnImport(vpnImportField.value)
                    vpnImportField.value = ""
                }
            }
        }

        StyledText {
            visible: NetworkExtras.lastActionOutput !== ""
            Layout.leftMargin: 8
            Layout.fillWidth: true
            text: NetworkExtras.lastActionOutput
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }
    }
}
