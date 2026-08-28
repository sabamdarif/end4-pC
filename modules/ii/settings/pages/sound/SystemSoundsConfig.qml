import QtQuick
import QtQuick.Dialogs
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    component SoundOverrideRow: ConfigRow {
        required property string eventName
        required property string configKey
        required property string enabledKey
        required property string label
        required property string rowIcon

        function currentPath() {
            return Config.options.sounds[configKey] || ""
        }

        function pickSound() {
            fileDialog.open()
        }

        FileDialog {
            id: fileDialog
            title: Translation.tr("Choose sound file")
            nameFilters: [Translation.tr("Audio files (*.oga *.ogg *.wav *.mp3)")]
            onAccepted: {
                const source = FileUtils.trimFileProtocol(selectedFile.toString())
                const destination = `${Directories.systemSounds}/${eventName}${source.substring(source.lastIndexOf("."))}`
                const escapedSource = StringUtils.shellSingleQuoteEscape(source)
                const escapedDestination = StringUtils.shellSingleQuoteEscape(destination)
                Quickshell.execDetached(["bash", "-c", `mkdir -p '${StringUtils.shellSingleQuoteEscape(Directories.systemSounds)}' && cp '${escapedSource}' '${escapedDestination}'`])
                Config.options.sounds[configKey] = destination
            }
        }

        Layout.fillWidth: true
        // Not uniform: equal cells cut the label off behind Play/Pick/Reset.
        ConfigSwitch {
            Layout.fillWidth: true
            buttonIcon: rowIcon
            text: label
            checked: Config.options.sounds[enabledKey]
            onCheckedChanged: Config.options.sounds[enabledKey] = checked
        }
        RippleButtonWithIcon {
            mainText: Translation.tr("Play")
            materialIcon: "play_arrow"
            onClicked: Audio.playSystemSound(eventName)
        }
        RippleButtonWithIcon {
            mainText: Translation.tr("Pick")
            materialIcon: "upload_file"
            onClicked: pickSound()
        }
        RippleButtonWithIcon {
            mainText: Translation.tr("Reset")
            materialIcon: "restart_alt"
            enabled: currentPath() !== ""
            onClicked: Config.options.sounds[configKey] = ""
        }
    }

    ContentSection {
        icon: "notification_sound"
        shape: MaterialShape.Shape.Clover8Leaf
        title: Translation.tr("Sounds")
        GroupedList {
            SoundOverrideRow {
                eventName: "dialog-warning"
                configKey: "batteryOverride"
                enabledKey: "battery"
                rowIcon: "battery_android_full"
                label: Translation.tr("Battery")
                enabled: Battery.available
            }
            SoundOverrideRow {
                eventName: "alarm-clock-elapsed"
                configKey: "pomodoroOverride"
                enabledKey: "pomodoro"
                rowIcon: "av_timer"
                label: Translation.tr("Pomodoro")
            }
            SoundOverrideRow {
                eventName: "device-added"
                configKey: "bluetoothOverride"
                enabledKey: "bluetooth"
                rowIcon: "bluetooth"
                label: Translation.tr("Bluetooth")
            }
            SoundOverrideRow {
                eventName: "message-new-instant"
                configKey: "notificationOverride"
                enabledKey: "notification"
                rowIcon: "notifications_active"
                label: Translation.tr("New notification")
            }
            SoundOverrideRow {
                eventName: "audio-volume-change"
                configKey: "volumeChangedOverride"
                enabledKey: "volumeChanged"
                rowIcon: "volume_up"
                label: Translation.tr("Volume changed")
            }
        }
    }
}
