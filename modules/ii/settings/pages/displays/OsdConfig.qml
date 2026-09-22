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
        icon: "voting_chip"
        shape: MaterialShape.Shape.Sunny
        title: Translation.tr("On-screen display")
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
        title: Translation.tr("Show OSD for")
        GroupedList {
            ConfigSwitch {
                buttonIcon: "volume_up"; text: Translation.tr("Sound")
                checked: Config.options.osd.enableVolume
                onCheckedChanged: { Config.options.osd.enableVolume = checked; }
            }
            ConfigSwitch {
                buttonIcon: "mic_off"; text: Translation.tr("Microphone mute")
                checked: Config.options.osd.enableMicMute
                onCheckedChanged: { Config.options.osd.enableMicMute = checked; }
            }
            ConfigSwitch {
                buttonIcon: "brightness_medium"; text: Translation.tr("Brightness")
                checked: Config.options.osd.enableBrightness
                onCheckedChanged: { Config.options.osd.enableBrightness = checked; }
            }
            ConfigSwitch {
                buttonIcon: "keyboard_capslock"; text: Translation.tr("Caps Lock")
                checked: Config.options.osd.enableCapsLock
                onCheckedChanged: { Config.options.osd.enableCapsLock = checked; }
            }
            ConfigSwitch {
                buttonIcon: "pin"; text: Translation.tr("Num Lock")
                checked: Config.options.osd.enableNumLock
                onCheckedChanged: { Config.options.osd.enableNumLock = checked; }
            }
        }
    }
}
