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
        id: soundRow
        required property string eventName
        required property string configKey
        required property string enabledKey
        required property string label
        required property string rowIcon

        function currentPath() {
            return Config.options.sounds[soundRow.configKey] || ""
        }

        FileDialog {
            id: fileDialog
            title: Translation.tr("Choose sound file")
            nameFilters: [Translation.tr("Audio files (*.oga *.ogg *.wav *.mp3)")]
            onAccepted: {
                const source = FileUtils.trimFileProtocol(selectedFile.toString())
                const destination = `${Directories.systemSounds}/${soundRow.eventName}${source.substring(source.lastIndexOf("."))}`
                const escapedSource = StringUtils.shellSingleQuoteEscape(source)
                const escapedDestination = StringUtils.shellSingleQuoteEscape(destination)
                Quickshell.execDetached(["bash", "-c", `mkdir -p '${StringUtils.shellSingleQuoteEscape(Directories.systemSounds)}' && cp '${escapedSource}' '${escapedDestination}'`])
                Config.options.sounds[soundRow.configKey] = destination
            }
        }

        Layout.fillWidth: true
        ConfigSwitch {
            Layout.fillWidth: true
            buttonIcon: soundRow.rowIcon
            text: soundRow.label
            checked: Config.options.sounds[soundRow.enabledKey]
            onCheckedChanged: Config.options.sounds[soundRow.enabledKey] = checked
        }
        RippleButtonWithIcon {
            mainText: Translation.tr("Play")
            materialIcon: "play_arrow"
            onClicked: Audio.playSystemSound(soundRow.eventName)
        }
        RippleButtonWithIcon {
            mainText: Translation.tr("Pick")
            materialIcon: "upload_file"
            onClicked: fileDialog.open()
        }
        RippleButtonWithIcon {
            mainText: Translation.tr("Reset")
            materialIcon: "restart_alt"
            enabled: soundRow.currentPath() !== ""
            onClicked: Config.options.sounds[soundRow.configKey] = ""
        }
    }

    ContentSection {
        icon: "speaker"
        shape: MaterialShape.Shape.Pill
        title: Translation.tr("Output")

        GroupedList {
            ColumnLayout {
                spacing: 0
                StyledText {
                    visible: Audio.outputDevices.length === 0
                    Layout.leftMargin: 8
                    text: Translation.tr("No output devices")
                    color: Appearance.colors.colSubtext
                }
                Repeater {
                    model: Audio.outputDevices
                    StyledRadioButton {
                        required property var modelData
                        Layout.fillWidth: true
                        description: Audio.friendlyDeviceName(modelData)
                        checked: Pipewire.defaultAudioSink ? (modelData.id === Pipewire.defaultAudioSink.id) : false
                        onClicked: Audio.setDefaultSink(modelData)
                    }
                }
            }

            ConfigSlider {
                buttonIcon: (Audio.sink && Audio.sink.audio && Audio.sink.audio.muted) ? "volume_off" : "volume_up"
                text: Translation.tr("Output volume")
                from: 0
                to: Audio.maxVolume * 100
                value: (Audio.sink && Audio.sink.audio) ? Math.round(Audio.sink.audio.volume * 100) : 0
                stopIndicatorValues: [100]
                onValueChanged: {
                    if (Audio.sink && Audio.sink.audio) {
                        Audio.sink.audio.volume = value / 100.0;
                    }
                }
            }

            ConfigSwitch {
                buttonIcon: "volume_off"
                text: Translation.tr("Mute output")
                checked: (Audio.sink && Audio.sink.audio) ? Audio.sink.audio.muted : false
                onCheckedChanged: {
                    if (Audio.sink && Audio.sink.audio && Audio.sink.audio.muted !== checked) {
                        Audio.sink.audio.muted = checked;
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "mic"
        shape: MaterialShape.Shape.Arch
        title: Translation.tr("Input")

        GroupedList {
            ColumnLayout {
                spacing: 0
                StyledText {
                    visible: Audio.inputDevices.length === 0
                    Layout.leftMargin: 8
                    text: Translation.tr("No input devices")
                    color: Appearance.colors.colSubtext
                }
                Repeater {
                    model: Audio.inputDevices
                    StyledRadioButton {
                        required property var modelData
                        Layout.fillWidth: true
                        description: Audio.friendlyDeviceName(modelData)
                        checked: Pipewire.defaultAudioSource ? (modelData.id === Pipewire.defaultAudioSource.id) : false
                        onClicked: Audio.setDefaultSource(modelData)
                    }
                }
            }

            ConfigSlider {
                buttonIcon: (Audio.source && Audio.source.audio && Audio.source.audio.muted) ? "mic_off" : "mic"
                text: Translation.tr("Input volume")
                from: 0
                to: 100
                value: (Audio.source && Audio.source.audio) ? Math.round(Audio.source.audio.volume * 100) : 0
                stopIndicatorValues: [100]
                onValueChanged: {
                    if (Audio.source && Audio.source.audio) {
                        Audio.source.audio.volume = value / 100.0;
                    }
                }
            }

            ConfigSwitch {
                buttonIcon: "mic_off"
                text: Translation.tr("Mute microphone")
                checked: (Audio.source && Audio.source.audio) ? Audio.source.audio.muted : false
                onCheckedChanged: {
                    if (Audio.source && Audio.source.audio && Audio.source.audio.muted !== checked) {
                        Audio.source.audio.muted = checked;
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "hearing"
        shape: MaterialShape.Shape.Circle
        title: Translation.tr("Volume limits")

        GroupedList {
            ConfigSwitch {
                buttonIcon: "brand_awareness"
                text: Translation.tr("Allow volume above 100% (up to 150%)")
                checked: Config.options.audio.overamplify
                onCheckedChanged: {
                    if (checked === Config.options.audio.overamplify) return;
                    Config.options.audio.overamplify = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "hearing"
                text: Translation.tr("Limit sudden volume increase")
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
                    to: 154
                    stepSize: 2
                    onValueChanged: {
                        Config.options.audio.protection.maxAllowed = value;
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "notification_sound"
        shape: MaterialShape.Shape.Clover8Leaf
        title: Translation.tr("System sounds")

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
