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
        icon: "mic"
        shape: MaterialShape.Shape.Arch
        title: Translation.tr("Input device")
        GroupedList {
            ColumnLayout {
                spacing: 0
                StyledText {
                    visible: Audio.inputDevices.length === 0
                    Layout.leftMargin: 8
                    text: Translation.tr("No devices")
                    color: Appearance.colors.colSubtext
                }
                Repeater {
                    model: Audio.inputDevices
                    StyledRadioButton {
                        required property var modelData
                        Layout.fillWidth: true
                        description: Audio.friendlyDeviceName(modelData)
                        checked: modelData.id === Pipewire.defaultAudioSource?.id
                        onClicked: Audio.setDefaultSource(modelData)
                    }
                }
            }
        }
    }
}
