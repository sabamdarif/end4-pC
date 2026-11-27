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

    Component.onCompleted: NetworkExtras.refresh()

    ContentSection {
        icon: "lan"
        shape: MaterialShape.Shape.Arch
        title: Translation.tr("Ethernet")

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Rectangle {
                visible: NetworkExtras.ethernetDevices.length === 0
                Layout.fillWidth: true
                implicitHeight: 64
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1

                StyledText {
                    anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                    text: Translation.tr("No wired network devices")
                    color: Appearance.colors.colSubtext
                }
            }

            Repeater {
                model: NetworkExtras.ethernetDevices
                delegate: Rectangle {
                    id: ethCard
                    required property var modelData
                    required property int index
                    readonly property bool isFirst: index === 0
                    readonly property bool isLast: index === NetworkExtras.ethernetDevices.length - 1
                    // Read-only native state (Quickshell.Networking),
                    // matched to the nmcli device by interface name
                    readonly property var nativeDev: QsNetworking.Networking.devices.values.find(d => d.name === ethCard.modelData.iface) ?? null

                    Layout.fillWidth: true
                    implicitHeight: ethRow.implicitHeight + 28
                    color: Appearance.colors.colLayer1
                    topLeftRadius: isFirst ? Appearance.rounding.normal : Appearance.rounding.unsharpenmore
                    topRightRadius: topLeftRadius
                    bottomLeftRadius: isLast ? Appearance.rounding.normal : Appearance.rounding.unsharpenmore
                    bottomRightRadius: bottomLeftRadius

                    ColumnLayout {
                        id: ethRow
                        anchors { fill: parent; margins: 14 }
                        spacing: 2

                        RowLayout {
                            spacing: 10
                            MaterialSymbol {
                                text: "settings_ethernet"
                                iconSize: Appearance.font.pixelSize.huge
                                color: Appearance.colors.colOnSecondaryContainer
                            }
                            StyledText {
                                text: ethCard.modelData.iface
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnSecondaryContainer
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: ethCard.modelData.connection !== ""
                                    ? "• " + ethCard.modelData.connection
                                    : ""
                                elide: Text.ElideRight
                                color: Appearance.colors.colSubtext
                            }
                            StyledText {
                                text: ethCard.modelData.state
                                animateChange: true
                                color: ethCard.modelData.state === "connected" ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                            }
                        }
                        StyledText {
                            Layout.leftMargin: 34
                            visible: ethCard.modelData.ip4.length > 0
                            text: Translation.tr("IPv4: %1").arg(ethCard.modelData.ip4.join(", "))
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                        StyledText {
                            Layout.leftMargin: 34
                            visible: ethCard.modelData.ip6.length > 0
                            text: Translation.tr("IPv6: %1").arg(ethCard.modelData.ip6.join(", "))
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        StyledText {
                            Layout.leftMargin: 34
                            visible: ethCard.modelData.mac !== ""
                            text: Translation.tr("MAC: %1").arg(ethCard.modelData.mac)
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                        StyledText {
                            Layout.leftMargin: 34
                            visible: ethCard.nativeDev !== null && ethCard.nativeDev.linkSpeed > 0
                            text: Translation.tr("Link speed: %1 Mb/s").arg(ethCard.nativeDev !== null ? ethCard.nativeDev.linkSpeed : 0)
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            tabularNums: true
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }
        }
    }
}
