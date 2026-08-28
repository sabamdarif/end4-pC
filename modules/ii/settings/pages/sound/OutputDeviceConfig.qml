import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    ContentSection {
        icon: "speaker"
        shape: MaterialShape.Shape.Pill
        title: Translation.tr("Output device")
        GroupedList {
            ColumnLayout {
                spacing: 0
                StyledText {
                    visible: Audio.outputDevices.length === 0
                    Layout.leftMargin: 8
                    text: Translation.tr("No devices")
                    color: Appearance.colors.colSubtext
                }
                Repeater {
                    model: Audio.outputDevices
                    StyledRadioButton {
                        required property var modelData
                        Layout.fillWidth: true
                        description: Audio.friendlyDeviceName(modelData)
                        checked: modelData.id === Pipewire.defaultAudioSink?.id
                        onClicked: Audio.setDefaultSink(modelData)
                    }
                }
            }
        }
    }
}
