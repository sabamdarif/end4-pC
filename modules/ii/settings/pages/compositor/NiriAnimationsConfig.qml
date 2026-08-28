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
        icon: "animation"
        shape: MaterialShape.Shape.Oval
        title: Translation.tr("Animations")
        GroupedList {
            ConfigSwitch {
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: NiriConfig.options.animations.enable
                onCheckedChanged: {
                    if (checked === NiriConfig.options.animations.enable) return
                    NiriConfig.options.animations.enable = checked
                }
            }

            ConfigSpinBox {
                icon: "speed"
                text: Translation.tr("Slowdown (×10)")
                value: Math.round(NiriConfig.options.animations.slowdown * 10)
                from: 1; to: 50; stepSize: 1
                onValueChanged: {
                    const newVal = value / 10.0
                    if (newVal === NiriConfig.options.animations.slowdown) return
                    NiriConfig.options.animations.slowdown = newVal
                }
            }
        }
    }
}
