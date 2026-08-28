import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    ContentSection {
        icon: "select_window"
        shape: MaterialShape.Shape.SoftBurst
        title: Translation.tr("Overlay")

        GroupedList {
            ConfigSwitch {
                buttonIcon: "high_density"
                text: Translation.tr("Enable opening zoom animation")
                checked: Config.options.overlay.openingZoomAnimation
                onCheckedChanged: {
                    Config.options.overlay.openingZoomAnimation = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "texture"
                text: Translation.tr("Darken screen")
                checked: Config.options.overlay.darkenScreen
                onCheckedChanged: {
                    Config.options.overlay.darkenScreen = checked;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Floating Image")
            GroupedList {
                ConfigTextArea {
                    id: floatingImageSourceField
                    Layout.fillWidth: true
                    fieldWidth: 430
                    buttonIcon: "imagesmode"
                    text: Translation.tr("Image source")
                    value: Config.options.overlay.floatingImage.imageSource
                    onValueChanged: {
                        floatingImageSourceDebounceTimer.restart();
                    }

                    Timer {
                        id: floatingImageSourceDebounceTimer
                        interval: 1000
                        repeat: false
                        onTriggered: {
                            Config.options.overlay.floatingImage.imageSource = floatingImageSourceField.value;
                        }
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Crosshair")

            Rectangle {
                id: crosshairCard
                Layout.fillWidth: true
                implicitHeight: crosshairCol.implicitHeight + 28
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1

                ColumnLayout {
                    id: crosshairCol
                    anchors { fill: parent; margins: 14 }
                    spacing: 8

                    ConfigTextArea {
                        id: crosshairCodeField
                        Layout.fillWidth: true
                        buttonIcon: "point_scan"
                        text: Translation.tr("Crosshair code")
                        placeholderText: Translation.tr("Crosshair code (in Valorant's format)")
                        value: Config.options.crosshair.code
                        onValueChanged: {
                            crosshairCodeDebounceTimer.restart();
                        }

                        Timer {
                            id: crosshairCodeDebounceTimer
                            interval: 1000
                            repeat: false
                            onTriggered: {
                                Config.options.crosshair.code = crosshairCodeField.value;
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText {
                            Layout.leftMargin: 8
                            Layout.fillWidth: true
                            text: Translation.tr("Press Super+G to open the overlay and pin the crosshair")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            wrapMode: Text.Wrap
                        }
                        RippleButtonWithIcon {
                            id: editorButton
                            Layout.fillWidth: true
                            Layout.rightMargin: 6
                            Layout.preferredHeight: 40
                            buttonRadius: Appearance.rounding.normal
                            materialIcon: "open_in_new"
                            mainText: Translation.tr("Open editor")
                            onClicked: {
                                Qt.openUrlExternally(`https://www.vcrdb.net/builder?c=${Config.options.crosshair.code}`);
                            }
                        }
                    }
                }
            }
        }
    }
}
