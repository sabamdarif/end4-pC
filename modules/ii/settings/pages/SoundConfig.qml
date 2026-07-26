import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.services
import qs.modules.common
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
                ConfigSwitch {
                    buttonIcon: "battery_android_full"
                    text: Translation.tr("Battery")
                    enabled: Battery.available
                    checked: Config.options.sounds.battery
                    onCheckedChanged: {
                        Config.options.sounds.battery = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "av_timer"
                    text: Translation.tr("Pomodoro")
                    checked: Config.options.sounds.pomodoro
                    onCheckedChanged: {
                        Config.options.sounds.pomodoro = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "notifications_active"
                    text: Translation.tr("New notification")
                    checked: Config.options.sounds.notification
                    onCheckedChanged: {
                        Config.options.sounds.notification = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "volume_up"
                    text: Translation.tr("Volume changed")
                    checked: Config.options.sounds.volumeChanged
                    onCheckedChanged: {
                        Config.options.sounds.volumeChanged = checked;
                    }
                }
            }
        }
    }
}
