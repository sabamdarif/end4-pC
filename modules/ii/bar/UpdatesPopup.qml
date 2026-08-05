import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    ColumnLayout {
        spacing: 10
        width: 220

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 3
            spacing: 7

            MaterialShapeWrappedMaterialSymbol {
                shape: MaterialShape.Shape.Clover4Leaf
                text: "deployed_code_update"
                iconSize: Appearance.font.pixelSize.large
                implicitSize: 36
                color: Appearance.colors.colPrimaryContainer
                colSymbol: Appearance.colors.colPrimary
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: -3

                StyledText {
                    text: Translation.tr("Updates")
                    font.weight: Font.Medium
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnSurfaceVariant
                }

                StyledText {
                    text: Translation.tr("Pending packages")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnSurfaceVariant
                    opacity: 0.6
                }
            }

            StyledText {
                Layout.rightMargin: 8
                text: Updates.count
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.Bold
                color: Appearance.colors.colPrimary
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: [
                    { label: "Pacman", icon: "deployed_code", count: Updates.pacmanCount },
                    { label: "AUR", icon: "package_2", count: Updates.aurCount },
                    { label: "Flatpak", icon: "package", count: Updates.flatpakCount }
                ]

                delegate: Rectangle {
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colSurfaceContainerHigh

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 10
                            rightMargin: 10
                        }
                        spacing: 8

                        MaterialSymbol {
                            text: modelData.icon
                            iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colPrimary
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.label
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer1
                        }

                        StyledText {
                            text: modelData.count
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Bold
                            color: Appearance.colors.colPrimary
                            font.features: { "tnum": 1 }
                        }
                    }
                }
            }
        }
    }
}
