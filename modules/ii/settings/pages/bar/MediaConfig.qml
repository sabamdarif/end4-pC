import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    ContentSection {
        icon: "music_note"
        shape: MaterialShape.Shape.Sunny
        title: Translation.tr("Media")

        GroupedList {
            ConfigTextArea {
                id: preferredPlayerField
                Layout.fillWidth: true
                buttonIcon: "play_circle"
                text: Translation.tr("Preferred Player")
                placeholderText: Translation.tr("e.g. spotify, firefox")
                value: Config.options.bar.media.preferredPlayer
                onValueChanged: {
                    mediaDebounceTimer.restart();
                }

                Timer {
                    id: mediaDebounceTimer
                    interval: 600
                    repeat: false
                    onTriggered: {
                        Config.options.bar.media.preferredPlayer = preferredPlayerField.value;
                    }
                }
            }
            ConfigSwitch {
                buttonIcon: "keep"; text: Translation.tr("Pin media controls")
                checked: Config.options.bar.media.alwaysVisible
                onCheckedChanged: { Config.options.bar.media.alwaysVisible = checked; }
            }
            ConfigSwitch {
                buttonIcon: "titlecase"; text: Translation.tr("Show only title")
                checked: Config.options.bar.media.onlyTitle
                onCheckedChanged: { Config.options.bar.media.onlyTitle = checked; }
            }
            ConfigSpinBox {
                icon: "width"
                text: Translation.tr("Max media width")
                value: Config.options.bar.media.maxWidth
                from: 100
                to: 500
                stepSize: 10
                onValueChanged: {
                    Config.options.bar.media.maxWidth = value;
                }
            }
        }
    }
}
