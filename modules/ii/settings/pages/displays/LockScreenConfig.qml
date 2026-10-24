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
        icon: "lock"
        title: Translation.tr("Lock screen")
        shape: MaterialShape.Shape.Pentagon

        GroupedList {
            ConfigSwitch {
                buttonIcon: "account_circle"
                text: Translation.tr("Launch on startup")
                checked: Config.options.lock.launchOnStartup
                onCheckedChanged: { Config.options.lock.launchOnStartup = checked }
            }
            ConfigComboBox {
                buttonIcon: "timer"
                text: Translation.tr("Auto-lock after")
                model: [
                    { displayName: Translation.tr("5 minutes"),  value: "5 minutes" },
                    { displayName: Translation.tr("10 minutes"), value: "10 minutes" },
                    { displayName: Translation.tr("20 minutes"), value: "20 minutes" },
                    { displayName: Translation.tr("30 minutes"), value: "30 minutes" },
                    { displayName: Translation.tr("Never"),      value: "infinity" },
                ]
                currentValue: Config.options.lock.idleTimeout
                onSelected: (value) => { Config.options.lock.idleTimeout = value; }
            }
            ConfigSwitch {
                buttonIcon: "bedtime"
                text: Translation.tr("Suspend after lock")
                checked: Config.options.lock.suspendOnLock
                onCheckedChanged: { Config.options.lock.suspendOnLock = checked }
            }
            ConfigSpinBox {
                icon: "timer"
                text: Translation.tr("Suspend delay (seconds)")
                value: Config.options.lock.suspendDelaySec
                from: 5; to: 600; stepSize: 5
                enabled: Config.options.lock.suspendOnLock
                onValueChanged: { Config.options.lock.suspendDelaySec = value }
            }
            ConfigSwitch {
                buttonIcon: "widgets"
                text: Translation.tr("Show Widgets")
                checked: Config.options.lock.showWidgets
                onCheckedChanged: { Config.options.lock.showWidgets = checked }
            }
            ConfigSwitch {
                buttonIcon: "tools_installation_kit"
                text: Translation.tr("Show Toolbars")
                checked: Config.options.lock.showToolbars
                onCheckedChanged: { Config.options.lock.showToolbars = checked }
            }
            ConfigSwitch {
                buttonIcon: "music_note"
                text: Translation.tr("Show media player")
                checked: Config.options.lock.showMedia
                onCheckedChanged: { Config.options.lock.showMedia = checked }
            }
        }

        ContentSubsection {
            title: Translation.tr("Security")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "settings_power"
                    text: Translation.tr("Require password to power off/restart")
                    checked: Config.options.lock.security.requirePasswordToPower
                    onCheckedChanged: { Config.options.lock.security.requirePasswordToPower = checked }
                }
                ConfigSwitch {
                    buttonIcon: "key_vertical"
                    text: Translation.tr("Also unlock keyring")
                    checked: Config.options.lock.security.unlockKeyring
                    onCheckedChanged: { Config.options.lock.security.unlockKeyring = checked }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Style: General")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "shapes"
                    text: Translation.tr("Use varying shapes for password characters")
                    checked: Config.options.lock.materialShapeChars
                    onCheckedChanged: { Config.options.lock.materialShapeChars = checked }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Style: Blurred")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "blur_on"
                    text: Translation.tr("Enable blur")
                    checked: Config.options.lock.blur.enable
                    onCheckedChanged: { Config.options.lock.blur.enable = checked }
                }
                ConfigSpinBox {
                    icon: "deblur"
                    text: Translation.tr("Samples")
                    value: Config.options.lock.blur.size
                    from: 20; to: 200; stepSize: 10
                    onValueChanged: { Config.options.lock.blur.size = value }
                }
                ConfigSpinBox {
                    icon: "loupe"
                    text: Translation.tr("Extra wallpaper zoom (%)")
                    value: Config.options.lock.blur.extraZoom * 100
                    from: 1; to: 150; stepSize: 2
                    onValueChanged: { Config.options.lock.blur.extraZoom = value / 100 }
                }
            }
        }
    }
}
