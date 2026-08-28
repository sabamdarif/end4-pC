import QtQuick
import QtQuick.Layouts
import Quickshell
// Aliased: Quickshell.Networking also exports a type called `Network`, which
// would shadow the nmcli service singleton of the same name from qs.services
import Quickshell.Networking as QsNetworking
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    Component.onCompleted: NetworkExtras.refresh()

    ContentSection {
        icon: "lan"
        shape: MaterialShape.Shape.Arch
        title: Translation.tr("Ethernet")

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: ethCol.implicitHeight + 28
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1

            ColumnLayout {
                id: ethCol
                anchors { fill: parent; margins: 14 }
                spacing: 10

                StyledText {
                    visible: NetworkExtras.ethernetDevices.length === 0
                    Layout.leftMargin: 8
                    text: Translation.tr("No wired network devices")
                    color: Appearance.colors.colSubtext
                }

                Repeater {
                    model: NetworkExtras.ethernetDevices
                    delegate: ColumnLayout {
                        id: ethRow
                        required property var modelData
                        // Read-only native state (Quickshell.Networking),
                        // matched to the nmcli device by interface name
                        readonly property var nativeDev: QsNetworking.Networking.devices.values.find(d => d.name === ethRow.modelData.iface) ?? null
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            spacing: 10
                            MaterialSymbol {
                                text: "settings_ethernet"
                                iconSize: Appearance.font.pixelSize.huge
                                color: Appearance.colors.colOnSecondaryContainer
                            }
                            StyledText {
                                text: ethRow.modelData.iface
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnSecondaryContainer
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: ethRow.modelData.connection !== ""
                                    ? "• " + ethRow.modelData.connection
                                    : ""
                                elide: Text.ElideRight
                                color: Appearance.colors.colSubtext
                            }
                            StyledText {
                                text: ethRow.modelData.state
                                color: ethRow.modelData.state === "connected" ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                            }
                        }
                        StyledText {
                            Layout.leftMargin: 34
                            visible: ethRow.modelData.ip4.length > 0
                            text: Translation.tr("IPv4: %1").arg(ethRow.modelData.ip4.join(", "))
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                        StyledText {
                            Layout.leftMargin: 34
                            visible: ethRow.modelData.ip6.length > 0
                            text: Translation.tr("IPv6: %1").arg(ethRow.modelData.ip6.join(", "))
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        StyledText {
                            Layout.leftMargin: 34
                            visible: ethRow.modelData.mac !== ""
                            text: Translation.tr("MAC: %1").arg(ethRow.modelData.mac)
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                        StyledText {
                            Layout.leftMargin: 34
                            visible: ethRow.nativeDev !== null && ethRow.nativeDev.linkSpeed > 0
                            text: Translation.tr("Link speed: %1 Mb/s").arg(ethRow.nativeDev !== null ? ethRow.nativeDev.linkSpeed : 0)
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }
        }
    }
}
