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
        icon: "keyboard"
        shape: MaterialShape.Shape.Pentagon
        title: Translation.tr("Keyboard")

        ContentSubsection {
            title: Translation.tr("Keyboard")

            GroupedList {
                ConfigTextArea {
                    id: kbLayoutField
                    Layout.fillWidth: true
                    buttonIcon: "keyboard"
                    text: Translation.tr("Keyboard layout")
                    placeholderText: Translation.tr("e.g., us, es, latam")
                    Component.onCompleted: value = Config.options.hyprland.input.kbLayout
                    onValueChanged: kbLayoutDebounceTimer.restart()

                    Timer {
                        id: kbLayoutDebounceTimer
                        interval: 1000
                        repeat: false
                        onTriggered: {
                            Config.options.hyprland.input.kbLayout = kbLayoutField.value
                            HyprlandConfig.set("input:kb_layout", kbLayoutField.value)
                        }
                    }
                }
                ConfigSwitch {
                    buttonIcon: "numbers"
                    text: Translation.tr("Numlock by default")
                    checked: Config.options.hyprland.input.numlock
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.input.numlock) return
                        Config.options.hyprland.input.numlock = checked
                        HyprlandConfig.set("input:numlock_by_default", checked ? 1 : 0)
                    }
                }

                ConfigSpinBox {
                    icon: "keyboard_return"
                    text: Translation.tr("Repeat delay (ms)")
                    value: Config.options.hyprland.input.repeatDelay
                    from: 100; to: 1000; stepSize: 10
                    onValueChanged: {
                        if (value === Config.options.hyprland.input.repeatDelay) return
                        Config.options.hyprland.input.repeatDelay = value
                        HyprlandConfig.set("input:repeat_delay", value)
                    }
                }

                ConfigSpinBox {
                    icon: "speed"
                    text: Translation.tr("Repeat rate")
                    value: Config.options.hyprland.input.repeatRate
                    from: 10; to: 100; stepSize: 1
                    onValueChanged: {
                        if (value === Config.options.hyprland.input.repeatRate) return
                        Config.options.hyprland.input.repeatRate = value
                        HyprlandConfig.set("input:repeat_rate", value)
                    }
                }
                ConfigSelectionArray {
                    text: Translation.tr("Follow mouse")
                    icon: "mouse"
                    currentValue: Config.options.hyprland.input.followMouse
                    onSelected: newValue => {
                        Config.options.hyprland.input.followMouse = newValue
                        HyprlandConfig.set("input:follow_mouse", newValue)
                    }
                    options: [
                        { displayName: Translation.tr("Disabled"), icon: "mouse",     value: 0 },
                        { displayName: Translation.tr("Full"),     icon: "open_with",  value: 1 },
                        { displayName: Translation.tr("Loose"),    icon: "drag_pan",   value: 2 },
                        { displayName: Translation.tr("Explicit"), icon: "ads_click",  value: 3 },
                    ]
                }
            }
        }
    }
}
