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
        icon: "notifications"
        shape: MaterialShape.Shape.Bun
        title: Translation.tr("Notifications")

        GroupedList {
            ConfigComboBox {
                text: Translation.tr("Popup position")
                buttonIcon: "my_location"
                currentValue: Config.options.notifications.position
                onSelected: newValue => {
                    Config.options.notifications.position = newValue;
                }
                model: [
                    { displayName: Translation.tr("Top left"),      value: "top_left" },
                    { displayName: Translation.tr("Top center"),    value: "top_center" },
                    { displayName: Translation.tr("Top right"),     value: "top_right" },
                    { displayName: Translation.tr("Bottom left"),   value: "bottom_left" },
                    { displayName: Translation.tr("Bottom center"), value: "bottom_center" },
                    { displayName: Translation.tr("Bottom right"),  value: "bottom_right" }
                ]
            }

            ConfigSwitch {
                buttonIcon: "counter_2"
                text: Translation.tr("Unread indicator: show count")
                checked: Config.options.bar.indicators.notifications.showUnreadCount
                onCheckedChanged: { Config.options.bar.indicators.notifications.showUnreadCount = checked; }
            }

            ConfigSpinBox {
                icon: "av_timer"
                text: Translation.tr("Timeout duration (if not defined by notification) (ms)")
                value: Config.options.notifications.timeout
                from: 1000
                to: 60000
                stepSize: 1000
                onValueChanged: {
                    Config.options.notifications.timeout = value;
                }
            }
        }
    }

    ContentSection {
        icon: "voting_chip"
        shape: MaterialShape.Shape.Sunny
        title: Translation.tr("On-screen display (OSD)")

        GroupedList {
            ConfigSpinBox {
                icon: "av_timer"
                text: Translation.tr("Timeout (ms)")
                value: Config.options.osd.timeout
                from: 100
                to: 3000
                stepSize: 100
                onValueChanged: {
                    Config.options.osd.timeout = value;
                }
            }
        }
    }

    ContentSection {
        icon: "toggle_on"
        shape: MaterialShape.Shape.Circle
        title: Translation.tr("Show OSD for")

        GroupedList {
            ConfigSwitch {
                buttonIcon: "volume_up"
                text: Translation.tr("Sound")
                checked: Config.options.osd.enableVolume
                onCheckedChanged: { Config.options.osd.enableVolume = checked; }
            }
            ConfigSwitch {
                buttonIcon: "mic_off"
                text: Translation.tr("Microphone mute")
                checked: Config.options.osd.enableMicMute
                onCheckedChanged: { Config.options.osd.enableMicMute = checked; }
            }
            ConfigSwitch {
                buttonIcon: "brightness_medium"
                text: Translation.tr("Brightness")
                checked: Config.options.osd.enableBrightness
                onCheckedChanged: { Config.options.osd.enableBrightness = checked; }
            }
            ConfigSwitch {
                buttonIcon: "keyboard_capslock"
                text: Translation.tr("Caps Lock")
                checked: Config.options.osd.enableCapsLock
                onCheckedChanged: { Config.options.osd.enableCapsLock = checked; }
            }
            ConfigSwitch {
                buttonIcon: "pin"
                text: Translation.tr("Num Lock")
                checked: Config.options.osd.enableNumLock
                onCheckedChanged: { Config.options.osd.enableNumLock = checked; }
            }
        }
    }
}
