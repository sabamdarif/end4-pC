import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    ColumnLayout {
        spacing: 10
        width: 240

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            spacing: 7

            MaterialShapeWrappedMaterialSymbol {
                shape: MaterialShape.Shape.Cookie6Sided
                text: "shield_lock"
                iconSize: Appearance.font.pixelSize.large
                implicitSize: 36
                color: Appearance.colors.colErrorContainer
                colSymbol: Appearance.colors.colError
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: -3

                StyledText {
                    text: Translation.tr("Privacy")
                    font.weight: Font.Medium
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnSurfaceVariant
                }

                StyledText {
                    text: Translation.tr("Devices in use")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnSurfaceVariant
                    opacity: 0.6
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: [
                    { label: Translation.tr("Camera"), icon: "videocam", apps: Privacy.cameraApps, active: Privacy.cameraShown && Privacy.cameraInUse },
                    { label: Translation.tr("Microphone"), icon: "mic", apps: Privacy.micApps, active: Privacy.micShown && Privacy.micInUse },
                    { label: Translation.tr("Screen"), icon: "screen_share", apps: Privacy.screenShareApps, active: Privacy.screenShareShown && Privacy.screenSharing }
                ].filter(source => source.active)

                delegate: Rectangle {
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colSurfaceContainerHigh

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 14
                            rightMargin: 14
                        }
                        spacing: 8

                        MaterialSymbol {
                            text: modelData.icon
                            iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colError
                        }

                        StyledText {
                            text: modelData.label
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer1
                        }

                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideRight
                            text: modelData.apps.length > 0 ? modelData.apps.join(", ") : Translation.tr("Unknown app")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnSurfaceVariant
                            opacity: 0.7
                        }
                    }
                }
            }
        }
    }
}
