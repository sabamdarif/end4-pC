import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    NiriIncludeNotice {}

    ContentSection {
        icon: "deblur"
        shape: MaterialShape.Shape.PixelCircle
        title: Translation.tr("Appearance & Effects")

        GroupedList {
            ConfigSpinBox {
                icon: "rounded_corner"
                text: Translation.tr("Window Rounding")
                value: NiriConfig.options.decoration.rounding
                from: 0; to: 30; stepSize: 1
                onValueChanged: {
                    if (value === NiriConfig.options.decoration.rounding) return
                    NiriConfig.options.decoration.rounding = value
                }
            }

            ConfigSwitch {
                buttonIcon: "border_outer"
                text: Translation.tr("Border")
                checked: NiriConfig.options.decoration.border.enable
                onCheckedChanged: {
                    if (checked === NiriConfig.options.decoration.border.enable) return
                    NiriConfig.options.decoration.border.enable = checked
                }
            }

            ConfigSpinBox {
                icon: "border_outer"
                text: Translation.tr("Border Size")
                value: NiriConfig.options.decoration.border.width
                from: 0; to: 10; stepSize: 1
                onValueChanged: {
                    if (value === NiriConfig.options.decoration.border.width) return
                    NiriConfig.options.decoration.border.width = value
                }
            }

            ConfigSwitch {
                buttonIcon: "center_focus_strong"
                text: Translation.tr("Focus ring")
                checked: NiriConfig.options.decoration.focusRing.enable
                onCheckedChanged: {
                    if (checked === NiriConfig.options.decoration.focusRing.enable) return
                    NiriConfig.options.decoration.focusRing.enable = checked
                }
            }

            ConfigSpinBox {
                icon: "center_focus_weak"
                text: Translation.tr("Focus ring width")
                value: NiriConfig.options.decoration.focusRing.width
                from: 0; to: 10; stepSize: 1
                onValueChanged: {
                    if (value === NiriConfig.options.decoration.focusRing.width) return
                    NiriConfig.options.decoration.focusRing.width = value
                }
            }

            ConfigSwitch {
                buttonIcon: "ev_shadow"
                text: Translation.tr("Shadows")
                checked: NiriConfig.options.decoration.shadow.enable
                onCheckedChanged: {
                    if (checked === NiriConfig.options.decoration.shadow.enable) return
                    NiriConfig.options.decoration.shadow.enable = checked
                }
            }

            ConfigSpinBox {
                icon: "blur_linear"
                text: Translation.tr("Shadow softness")
                value: NiriConfig.options.decoration.shadow.softness
                from: 0; to: 100; stepSize: 5
                onValueChanged: {
                    if (value === NiriConfig.options.decoration.shadow.softness) return
                    NiriConfig.options.decoration.shadow.softness = value
                }
            }

            ConfigSpinBox {
                icon: "expand_all"
                text: Translation.tr("Shadow spread")
                value: NiriConfig.options.decoration.shadow.spread
                from: 0; to: 50; stepSize: 1
                onValueChanged: {
                    if (value === NiriConfig.options.decoration.shadow.spread) return
                    NiriConfig.options.decoration.shadow.spread = value
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Blur")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "blur_on"
                    text: Translation.tr("Blur")
                    checked: NiriConfig.options.decoration.blur.enable
                    onCheckedChanged: {
                        if (checked === NiriConfig.options.decoration.blur.enable) return
                        NiriConfig.options.decoration.blur.enable = checked
                    }
                }

                ConfigSpinBox {
                    icon: "layers"
                    text: Translation.tr("Blur Passes")
                    value: NiriConfig.options.decoration.blur.passes
                    from: 1; to: 6; stepSize: 1
                    onValueChanged: {
                        if (value === NiriConfig.options.decoration.blur.passes) return
                        NiriConfig.options.decoration.blur.passes = value
                    }
                }

                ConfigSpinBox {
                    icon: "blur_circular"
                    text: Translation.tr("Blur Offset")
                    value: Math.round(NiriConfig.options.decoration.blur.offset * 10)
                    from: 0; to: 100; stepSize: 5
                    onValueChanged: {
                        const newVal = value / 10.0
                        if (newVal === NiriConfig.options.decoration.blur.offset) return
                        NiriConfig.options.decoration.blur.offset = newVal
                    }
                }

                ConfigSpinBox {
                    icon: "grain"
                    text: Translation.tr("Blur Noise (%)")
                    value: Math.round(NiriConfig.options.decoration.blur.noise * 100)
                    from: 0; to: 20; stepSize: 1
                    onValueChanged: {
                        const newVal = value / 100.0
                        if (newVal === NiriConfig.options.decoration.blur.noise) return
                        NiriConfig.options.decoration.blur.noise = newVal
                    }
                }

                ConfigSpinBox {
                    icon: "palette"
                    text: Translation.tr("Blur Saturation (%)")
                    value: Math.round(NiriConfig.options.decoration.blur.saturation * 100)
                    from: 0; to: 300; stepSize: 10
                    onValueChanged: {
                        const newVal = value / 100.0
                        if (newVal === NiriConfig.options.decoration.blur.saturation) return
                        NiriConfig.options.decoration.blur.saturation = newVal
                    }
                }
            }
        }
    }
}
