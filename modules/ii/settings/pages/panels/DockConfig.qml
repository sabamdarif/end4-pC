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
        icon: "call_to_action"
        title: Translation.tr("Dock")
        shape: MaterialShape.Shape.Cookie6Sided

        GroupedList {
            ConfigSwitch {
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.dock.enable
                onCheckedChanged: { Config.options.dock.enable = checked }
            }
            ConfigSwitch {
                buttonIcon: "background_dot_small"
                text: Translation.tr("Background")
                checked: Config.options.dock.showBackground
                onCheckedChanged: { Config.options.dock.showBackground = checked }
            }
            ConfigSwitch {
                buttonIcon: "highlight_mouse_cursor"
                text: Translation.tr("Hover to reveal")
                checked: Config.options.dock.hoverToReveal
                onCheckedChanged: { Config.options.dock.hoverToReveal = checked }
            }
            ConfigSwitch {
                buttonIcon: "push_pin"
                text: Translation.tr("Pinned on startup")
                checked: Config.options.dock.pinnedOnStartup
                onCheckedChanged: { Config.options.dock.pinnedOnStartup = checked }
            }
        }


        ContentSubsection {
            title: Translation.tr("Buttons & Media")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "music_note"
                    text: Translation.tr("Media Player")
                    checked: Config.options.dock.showMedia
                    onCheckedChanged: { Config.options.dock.showMedia = checked }
                }
                ConfigSwitch {
                    buttonIcon: "keep"
                    text: Translation.tr("Show Pin Button")
                    checked: Config.options.dock.showPinButton
                    onCheckedChanged: { Config.options.dock.showPinButton = checked }
                }
                ConfigSwitch {
                    buttonIcon: "apps"
                    text: Translation.tr("Show Apps Button")
                    checked: Config.options.dock.showAppsButton
                    onCheckedChanged: { Config.options.dock.showAppsButton = checked }
                }
                ConfigSwitch {
                    buttonIcon: "colors"
                    text: Translation.tr("Tint app icons")
                    checked: Config.options.dock.monochromeIcons
                    onCheckedChanged: { Config.options.dock.monochromeIcons = checked }
                }
            }
        }
    }
}
