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
        icon: "trackpad_input"
        shape: MaterialShape.Shape.Pentagon
        title: Translation.tr("Touchpad & Mouse")

        ContentSubsection {
            title: Translation.tr("Touchpad")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "touch_app"
                    text: Translation.tr("Tap to click")
                    checked: NiriConfig.options.input.touchpad.tap
                    onCheckedChanged: {
                        if (checked === NiriConfig.options.input.touchpad.tap) return
                        NiriConfig.options.input.touchpad.tap = checked
                    }
                }

                ConfigSwitch {
                    buttonIcon: "swap_vert"
                    text: Translation.tr("Natural scroll")
                    checked: NiriConfig.options.input.touchpad.naturalScroll
                    onCheckedChanged: {
                        if (checked === NiriConfig.options.input.touchpad.naturalScroll) return
                        NiriConfig.options.input.touchpad.naturalScroll = checked
                    }
                }

                ConfigSwitch {
                    buttonIcon: "keyboard_hide"
                    text: Translation.tr("Disable while typing")
                    checked: NiriConfig.options.input.touchpad.disableWhileTyping
                    onCheckedChanged: {
                        if (checked === NiriConfig.options.input.touchpad.disableWhileTyping) return
                        NiriConfig.options.input.touchpad.disableWhileTyping = checked
                    }
                }

                ConfigSpinBox {
                    icon: "swipe"
                    text: Translation.tr("Scroll factor")
                    value: Math.round(NiriConfig.options.input.touchpad.scrollFactor * 10)
                    from: 1; to: 30; stepSize: 1
                    onValueChanged: {
                        const newVal = value / 10.0
                        if (newVal === NiriConfig.options.input.touchpad.scrollFactor) return
                        NiriConfig.options.input.touchpad.scrollFactor = newVal
                    }
                }

                ConfigSpinBox {
                    icon: "speed"
                    text: Translation.tr("Acceleration speed")
                    value: Math.round(NiriConfig.options.input.touchpad.accelSpeed * 10)
                    from: -10; to: 10; stepSize: 1
                    onValueChanged: {
                        const newVal = value / 10.0
                        if (newVal === NiriConfig.options.input.touchpad.accelSpeed) return
                        NiriConfig.options.input.touchpad.accelSpeed = newVal
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Mouse")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "swap_vert"
                    text: Translation.tr("Natural scroll")
                    checked: NiriConfig.options.input.mouse.naturalScroll
                    onCheckedChanged: {
                        if (checked === NiriConfig.options.input.mouse.naturalScroll) return
                        NiriConfig.options.input.mouse.naturalScroll = checked
                    }
                }

                ConfigSpinBox {
                    icon: "speed"
                    text: Translation.tr("Acceleration speed")
                    value: Math.round(NiriConfig.options.input.mouse.accelSpeed * 10)
                    from: -10; to: 10; stepSize: 1
                    onValueChanged: {
                        const newVal = value / 10.0
                        if (newVal === NiriConfig.options.input.mouse.accelSpeed) return
                        NiriConfig.options.input.mouse.accelSpeed = newVal
                    }
                }
            }
        }
    }
}
