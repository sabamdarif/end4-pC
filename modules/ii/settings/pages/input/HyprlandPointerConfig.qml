import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    HyprlandConfigSync {}

    ContentSection {
        icon: "trackpad_input"
        shape: MaterialShape.Shape.Pentagon
        title: Translation.tr("Touchpad & Mouse")

        ContentSubsection {
            title: Translation.tr("Touchpad")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "swap_vert"
                    text: Translation.tr("Natural scroll")
                    checked: Config.options.hyprland.input.touchpad.naturalScroll
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.input.touchpad.naturalScroll) return
                        Config.options.hyprland.input.touchpad.naturalScroll = checked
                        HyprlandConfig.set("input:touchpad:natural_scroll", checked ? 1 : 0)
                    }
                }

                ConfigSwitch {
                    buttonIcon: "keyboard_hide"
                    text: Translation.tr("Disable while typing")
                    checked: Config.options.hyprland.input.touchpad.disableWhileTyping
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.input.touchpad.disableWhileTyping) return
                        Config.options.hyprland.input.touchpad.disableWhileTyping = checked
                        HyprlandConfig.set("input:touchpad:disable_while_typing", checked ? 1 : 0)
                    }
                }

                ConfigSwitch {
                    buttonIcon: "touch_app"
                    text: Translation.tr("Clickfinger behavior")
                    checked: Config.options.hyprland.input.touchpad.clickfingerBehavior
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.input.touchpad.clickfingerBehavior) return
                        Config.options.hyprland.input.touchpad.clickfingerBehavior = checked
                        HyprlandConfig.set("input:touchpad:clickfinger_behavior", checked ? 1 : 0)
                    }
                }

                ConfigSpinBox {
                    icon: "swipe"
                    text: Translation.tr("Scroll factor")
                    value: Math.round(Config.options.hyprland.input.touchpad.scrollFactor * 10)
                    from: 1; to: 30; stepSize: 1
                    onValueChanged: {
                        const newVal = value / 10.0
                        if (newVal === Config.options.hyprland.input.touchpad.scrollFactor) return
                        Config.options.hyprland.input.touchpad.scrollFactor = newVal
                        HyprlandConfig.set("input:touchpad:scroll_factor", newVal)
                    }
                }
            }
        }
    }
}
