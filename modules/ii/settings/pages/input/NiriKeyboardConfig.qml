import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page

    NiriIncludeNotice {}

    // Common xkb layouts; anything else (e.g. "us,ru") gets the custom field.
    readonly property var layoutPresets: [
        "us", "gb", "de", "fr", "es", "latam", "br", "it", "pt",
        "ru", "ua", "pl", "tr", "in", "jp", "kr", "cn", "ara"
    ]
    readonly property bool layoutIsPreset: layoutPresets.includes(NiriConfig.options.input.kbLayout)

    // niri reads `numlock` only at startup, so the config write alone never
    // lights the LED. Tap Num_Lock through a virtual keyboard to toggle it now.
    function applyNumlockNow(enable) {
        if (KeyLocks.ready && KeyLocks.numLock === enable) return
        Quickshell.execDetached(["wtype", "-k", "Num_Lock"])
    }

    ContentSection {
        icon: "keyboard"
        shape: MaterialShape.Shape.Pentagon
        title: Translation.tr("Keyboard")

        ContentSubsection {
            title: Translation.tr("Keyboard")

            GroupedList {
                // GroupedList's Repeater reparents children and ignores their
                // `visible`, so a hidden row would still take a slot. Move the
                // fallback text field out of the list entirely.
                ConfigComboBox {
                    Layout.fillWidth: true
                    buttonIcon: "keyboard"
                    text: Translation.tr("Keyboard layout")
                    model: page.layoutPresets.map(l => ({ displayName: l, value: l }))
                    currentValue: NiriConfig.options.input.kbLayout
                    onSelected: (value) => {
                        NiriConfig.options.input.kbLayout = value
                    }
                }

                ConfigSwitch {
                    buttonIcon: "numbers"
                    text: Translation.tr("Numlock by default")
                    checked: NiriConfig.options.input.numlock
                    onCheckedChanged: {
                        if (checked === NiriConfig.options.input.numlock) return
                        NiriConfig.options.input.numlock = checked
                        page.applyNumlockNow(checked)
                    }
                }

                ConfigSpinBox {
                    icon: "keyboard_return"
                    text: Translation.tr("Repeat delay (ms)")
                    value: NiriConfig.options.input.repeatDelay
                    from: 100; to: 1000; stepSize: 10
                    onValueModified: {
                        if (value === NiriConfig.options.input.repeatDelay) return
                        NiriConfig.options.input.repeatDelay = value
                    }
                }

                ConfigSpinBox {
                    icon: "speed"
                    text: Translation.tr("Repeat rate")
                    value: NiriConfig.options.input.repeatRate
                    from: 10; to: 100; stepSize: 1
                    onValueModified: {
                        if (value === NiriConfig.options.input.repeatRate) return
                        NiriConfig.options.input.repeatRate = value
                    }
                }

                ConfigSwitch {
                    buttonIcon: "mouse"
                    text: Translation.tr("Focus follows mouse")
                    // Already enabled by the user's own niri config, which the
                    // shell cannot turn back off.
                    enabled: !NiriConfig.focusFollowsMouseOwnedByConfig
                    checked: NiriConfig.options.input.focusFollowsMouse
                    onCheckedChanged: {
                        if (checked === NiriConfig.options.input.focusFollowsMouse) return
                        NiriConfig.options.input.focusFollowsMouse = checked
                    }
                }
            }
        }

        Revealer {
            vertical: true
            reveal: !page.layoutIsPreset
            Layout.fillWidth: true

            ConfigTextArea {
                id: customKbField
                width: parent.width
                buttonIcon: "keyboard"
                text: Translation.tr("Keyboard layout (custom)")
                placeholderText: Translation.tr("e.g., us, es, latam")
                value: NiriConfig.options.input.kbLayout
                onValueChanged: {
                    if (value !== NiriConfig.options.input.kbLayout) kbLayoutDebounceTimer.restart()
                }

                Timer {
                    id: kbLayoutDebounceTimer
                    interval: 1000
                    repeat: false
                    onTriggered: {
                        NiriConfig.options.input.kbLayout = customKbField.value
                    }
                }
            }
        }

        StyledText {
            visible: NiriConfig.focusFollowsMouseOwnedByConfig
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.bottomMargin: 8
            text: Translation.tr("Focus follows mouse is enabled in your own niri config (config.d). niri cannot turn that flag off from another file, so remove the line there to manage it here.")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }
    }
}
