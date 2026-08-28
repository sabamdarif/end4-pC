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
                    Component.onCompleted: value = NiriConfig.options.input.kbLayout
                    onValueChanged: kbLayoutDebounceTimer.restart()

                    Timer {
                        id: kbLayoutDebounceTimer
                        interval: 1000
                        repeat: false
                        onTriggered: {
                            NiriConfig.options.input.kbLayout = kbLayoutField.value
                        }
                    }
                }

                ConfigSwitch {
                    buttonIcon: "numbers"
                    text: Translation.tr("Numlock by default")
                    checked: NiriConfig.options.input.numlock
                    onCheckedChanged: {
                        if (checked === NiriConfig.options.input.numlock) return
                        NiriConfig.options.input.numlock = checked
                    }
                }

                ConfigSpinBox {
                    icon: "keyboard_return"
                    text: Translation.tr("Repeat delay (ms)")
                    value: NiriConfig.options.input.repeatDelay
                    from: 100; to: 1000; stepSize: 10
                    onValueChanged: {
                        if (value === NiriConfig.options.input.repeatDelay) return
                        NiriConfig.options.input.repeatDelay = value
                    }
                }

                ConfigSpinBox {
                    icon: "speed"
                    text: Translation.tr("Repeat rate")
                    value: NiriConfig.options.input.repeatRate
                    from: 10; to: 100; stepSize: 1
                    onValueChanged: {
                        if (value === NiriConfig.options.input.repeatRate) return
                        NiriConfig.options.input.repeatRate = value
                    }
                }

                ConfigSwitch {
                    buttonIcon: "mouse"
                    text: Translation.tr("Focus follows mouse")
                    checked: NiriConfig.options.input.focusFollowsMouse
                    onCheckedChanged: {
                        if (checked === NiriConfig.options.input.focusFollowsMouse) return
                        NiriConfig.options.input.focusFollowsMouse = checked
                    }
                }
            }
        }
    }
}
