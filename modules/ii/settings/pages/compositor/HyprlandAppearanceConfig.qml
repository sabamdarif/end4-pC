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
        icon: "deblur"
        shape: MaterialShape.Shape.PixelCircle
        title: Translation.tr("Appearance & Effects")

        GroupedList {
            ConfigSpinBox {
                icon: "rounded_corner"
                text: Translation.tr("Window Rounding")
                value: Config.options.hyprland.decoration.rounding
                from: 0; to: 30; stepSize: 1
                onValueChanged: {
                    if (value === Config.options.hyprland.decoration.rounding) return
                    Config.options.hyprland.decoration.rounding = value
                    HyprlandConfig.set("decoration:rounding", value)
                }
            }

            ConfigSwitch {
                buttonIcon: "blur_on"
                text: Translation.tr("Blur")
                checked: Config.options.hyprland.decoration.blur.enabled
                onCheckedChanged: {
                    if (checked === Config.options.hyprland.decoration.blur.enabled) return
                    Config.options.hyprland.decoration.blur.enabled = checked
                    HyprlandConfig.set("decoration:blur:enabled", checked ? 1 : 0)
                }
            }

            ConfigSpinBox {
                icon: "blur_circular"
                text: Translation.tr("Blur Size")
                value: Config.options.hyprland.decoration.blur.size
                from: 1; to: 20; stepSize: 1
                onValueChanged: {
                    if (value === Config.options.hyprland.decoration.blur.size) return
                    Config.options.hyprland.decoration.blur.size = value
                    HyprlandConfig.set("decoration:blur:size", value)
                }
            }

            ConfigSpinBox {
                icon: "layers"
                text: Translation.tr("Blur Passes")
                value: Config.options.hyprland.decoration.blur.passes
                from: 1; to: 6; stepSize: 1
                onValueChanged: {
                    if (value === Config.options.hyprland.decoration.blur.passes) return
                    Config.options.hyprland.decoration.blur.passes = value
                    HyprlandConfig.set("decoration:blur:passes", value)
                }
            }

            ConfigSpinBox {
                icon: "border_outer"
                text: Translation.tr("Border Size")
                value: Config.options.hyprland.general.borderSize
                from: 0; to: 10; stepSize: 1
                onValueChanged: {
                    if (value === Config.options.hyprland.general.borderSize) return
                    Config.options.hyprland.general.borderSize = value
                    HyprlandConfig.set("general:border_size", value)
                }
            }

            ConfigSpinBox {
                icon: "margin"
                text: Translation.tr("Gaps In")
                value: Config.options.hyprland.general.gapsIn
                from: 0; to: 40; stepSize: 1
                onValueChanged: {
                    if (value === Config.options.hyprland.general.gapsIn) return
                    Config.options.hyprland.general.gapsIn = value
                    HyprlandConfig.set("general:gaps_in", value)
                }
            }

            ConfigSpinBox {
                icon: "open_in_full"
                text: Translation.tr("Gaps Out")
                value: Config.options.hyprland.general.gapsOut
                from: 0; to: 60; stepSize: 1
                onValueChanged: {
                    if (value === Config.options.hyprland.general.gapsOut) return
                    Config.options.hyprland.general.gapsOut = value
                    HyprlandConfig.set("general:gaps_out", value)
                }
            }

            ConfigSpinBox {
                icon: "opacity"
                text: Translation.tr("Active Opacity")
                value: Math.round(Config.options.hyprland.decoration.activeOpacity * 100)
                from: 10; to: 100; stepSize: 5
                onValueChanged: {
                    const newVal = value / 100.0
                    if (newVal === Config.options.hyprland.decoration.activeOpacity) return
                    Config.options.hyprland.decoration.activeOpacity = newVal
                    HyprlandConfig.set("decoration:active_opacity", newVal)
                }
            }

            ConfigSpinBox {
                icon: "opacity"
                text: Translation.tr("Inactive Opacity")
                value: Math.round(Config.options.hyprland.decoration.inactiveOpacity * 100)
                from: 10; to: 100; stepSize: 5
                onValueChanged: {
                    const newVal = value / 100.0
                    if (newVal === Config.options.hyprland.decoration.inactiveOpacity) return
                    Config.options.hyprland.decoration.inactiveOpacity = newVal
                    HyprlandConfig.set("decoration:inactive_opacity", newVal)
                }
            }
        }
    }
}
