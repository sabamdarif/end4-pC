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

    function goTo(term) {
        const t = term.toLowerCase().trim()

        function findTarget(rootItem) {
            for (let i = 0; i < rootItem.children.length; i++) {
                let child = rootItem.children[i]
                if (child.title && child.title.toLowerCase().includes(t)) {
                    return child
                }
            }
            for (let i = 0; i < rootItem.children.length; i++) {
                let found = findTarget(rootItem.children[i])
                if (found) return found
            }
            return null
        }

        let target = findTarget(mainLayout)
        if (target) {
            let pos = target.mapToItem(mainLayout, 0, 0)
            page.contentY = Math.max(0, pos.y - 0)
        }
    }

    component SoundOverrideRow: ConfigRow {
        required property string eventName
        required property string configKey
        required property string enabledKey
        required property string label
        required property string icon

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
        uniform: true
        ConfigSwitch {
            Layout.fillWidth: true
            buttonIcon: icon
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

    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        ContentSection {
            icon: "volume_up"
            shape: MaterialShape.Shape.Circle
            title: Translation.tr("Audio")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "brand_awareness"
                    text: Translation.tr("Overamplified sound (up to 150%)")
                    checked: Config.options.audio.overamplify
                    onCheckedChanged: {
                        if (checked === Config.options.audio.overamplify) return;
                        Config.options.audio.overamplify = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "hearing"
                    text: Translation.tr("Earbang protection")
                    checked: Config.options.audio.protection.enable
                    onCheckedChanged: {
                        Config.options.audio.protection.enable = checked;
                    }
                }
                ConfigRow {
                    enabled: Config.options.audio.protection.enable
                    ConfigSpinBox {
                        icon: "arrow_warm_up"
                        text: Translation.tr("Max allowed increase")
                        value: Config.options.audio.protection.maxAllowedIncrease
                        from: 0
                        to: 100
                        stepSize: 2
                        onValueChanged: {
                            Config.options.audio.protection.maxAllowedIncrease = value;
                        }
                    }
                    ConfigSpinBox {
                        icon: "vertical_align_top"
                        text: Translation.tr("Volume limit")
                        value: Config.options.audio.protection.maxAllowed
                        from: 0
                        to: 154 // pavucontrol allows up to 153%
                        stepSize: 2
                        onValueChanged: {
                            Config.options.audio.protection.maxAllowed = value;
                        }
                    }
                }
            }
        }

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

        ContentSection {
            icon: "notification_sound"
            shape: MaterialShape.Shape.Clover8Leaf
            title: Translation.tr("Sounds")
            GroupedList {
                SoundOverrideRow {
                    eventName: "dialog-warning"
                    configKey: "batteryOverride"
                    enabledKey: "battery"
                    icon: "battery_android_full"
                    label: Translation.tr("Battery")
                    enabled: Battery.available
                }
                SoundOverrideRow {
                    eventName: "alarm-clock-elapsed"
                    configKey: "pomodoroOverride"
                    enabledKey: "pomodoro"
                    icon: "av_timer"
                    label: Translation.tr("Pomodoro")
                }
                SoundOverrideRow {
                    eventName: "device-added"
                    configKey: "bluetoothOverride"
                    enabledKey: "bluetooth"
                    icon: "bluetooth"
                    label: Translation.tr("Bluetooth")
                }
                SoundOverrideRow {
                    eventName: "message-new-instant"
                    configKey: "notificationOverride"
                    enabledKey: "notification"
                    icon: "notifications_active"
                    label: Translation.tr("New notification")
                }
                SoundOverrideRow {
                    eventName: "audio-volume-change"
                    configKey: "volumeChangedOverride"
                    enabledKey: "volumeChanged"
                    icon: "volume_up"
                    label: Translation.tr("Volume changed")
                }
            }
        }
    }
}
