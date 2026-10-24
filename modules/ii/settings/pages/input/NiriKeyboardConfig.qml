import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    NiriIncludeNotice {}

    // Common xkb layouts; anything else (e.g. "us,ru") gets the custom field.
    readonly property var layoutPresets: [
        "us", "gb", "de", "fr", "es", "latam", "br", "it", "pt",
        "ru", "ua", "pl", "tr", "in", "jp", "kr", "cn", "ara"
    ]
    readonly property bool layoutIsPreset: layoutPresets.includes(NiriConfig.options.input.kbLayout)
    // True when focus-follows-mouse came from the user's own niri config. niri
    // has no way to turn the flag back off from a later include, so the switch
    // is read-only then (a hint explains how to disable it by hand).
    property bool focusFollowsMouseOwnedByConfig: false

    // niri reads `numlock` only at startup, so the config write alone never
    // lights the LED. Tap Num_Lock through a virtual keyboard to toggle it now.
    function applyNumlockNow(enable) {
        if (KeyLocks.ready && KeyLocks.numLock === enable) return
        Quickshell.execDetached(["wtype", "-k", "Num_Lock"])
    }

    // The shell only persists its own JSON, so the switch can't see a
    // focus-follows-mouse set by hand in config.kdl / config.d. Read the last
    // uncommented one (niri merges includes in order) so the switch shows the
    // real state, and keep any max-scroll-amount parameter it carries.
    Process {
        id: ffmProbeProc
        command: ["sh", "-c", `grep -hE '^[ \\t]*focus-follows-mouse' "$HOME/.config/niri/config.kdl" "$HOME/.config/niri/config.d"/*.kdl 2>/dev/null | grep -v '^[ \\t]*//' | tail -1`]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim()
                page.focusFollowsMouseOwnedByConfig = line !== ""
                if (line === "") return
                const m = line.match(/max-scroll-amount\s*=\s*"([^"]*)"/)
                if (m) NiriConfig.options.input.focusFollowsMouseMaxScroll = m[1]
                NiriConfig.options.input.focusFollowsMouse = true
            }
        }
    }

    Component.onCompleted: ffmProbeProc.running = true

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
                    // Already enabled by the user's own niri config, which the
                    // shell cannot turn back off.
                    enabled: !page.focusFollowsMouseOwnedByConfig
                    checked: NiriConfig.options.input.focusFollowsMouse
                    onCheckedChanged: {
                        if (checked === NiriConfig.options.input.focusFollowsMouse) return
                        NiriConfig.options.input.focusFollowsMouse = checked
                    }
                }
            }
        }

        ConfigTextArea {
            visible: !page.layoutIsPreset
            Layout.fillWidth: true
            buttonIcon: "keyboard"
            text: Translation.tr("Keyboard layout (custom)")
            placeholderText: Translation.tr("e.g., us, es, latam")
            Component.onCompleted: value = NiriConfig.options.input.kbLayout
            onValueChanged: kbLayoutDebounceTimer.restart()

            Timer {
                id: kbLayoutDebounceTimer
                interval: 1000
                repeat: false
                onTriggered: {
                    NiriConfig.options.input.kbLayout = value
                }
            }
        }

        StyledText {
            visible: page.focusFollowsMouseOwnedByConfig
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
