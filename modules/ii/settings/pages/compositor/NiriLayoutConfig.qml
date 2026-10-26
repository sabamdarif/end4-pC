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

    property bool focusFollowsMouseOwnedByConfig: false

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

    NiriIncludeNotice {}

    ContentSection {
        icon: "auto_awesome_mosaic"
        shape: MaterialShape.Shape.Gem
        title: Translation.tr("Layout")

        GroupedList {
            ConfigSpinBox {
                icon: "margin"
                text: Translation.tr("Gaps")
                value: NiriConfig.options.layout.gaps
                from: 0; to: 60; stepSize: 1
                onValueChanged: {
                    if (value === NiriConfig.options.layout.gaps) return
                    NiriConfig.options.layout.gaps = value
                }
            }

            ConfigSelectionArray {
                text: Translation.tr("Center focused column")
                icon: "align_horizontal_center"
                currentValue: NiriConfig.options.layout.centerFocusedColumn
                onSelected: newValue => {
                    NiriConfig.options.layout.centerFocusedColumn = newValue
                }
                options: [
                    { displayName: Translation.tr("Never"),       icon: "close",                       value: "never" },
                    { displayName: Translation.tr("On overflow"), icon: "keyboard_double_arrow_right", value: "on-overflow" },
                    { displayName: Translation.tr("Always"),      icon: "align_horizontal_center",     value: "always" },
                ]
            }

            ConfigSelectionArray {
                text: Translation.tr("Default column width")
                icon: "width"
                currentValue: NiriConfig.options.layout.defaultColumnWidth
                onSelected: newValue => {
                    NiriConfig.options.layout.defaultColumnWidth = newValue
                }
                options: [
                    { displayName: "⅓", icon: "crop_portrait", value: 0.33333 },
                    { displayName: "½", icon: "crop_square",   value: 0.5 },
                    { displayName: "⅔", icon: "crop_landscape", value: 0.66667 },
                ]
            }
        }
    }

    ContentSection {
        icon: "mouse"
        shape: MaterialShape.Shape.Pentagon
        title: Translation.tr("Focus")

        GroupedList {
            ConfigSwitch {
                buttonIcon: "mouse"
                text: Translation.tr("Focus follows mouse")
                enabled: !page.focusFollowsMouseOwnedByConfig
                checked: NiriConfig.options.input.focusFollowsMouse
                onCheckedChanged: {
                    if (checked === NiriConfig.options.input.focusFollowsMouse) return
                    NiriConfig.options.input.focusFollowsMouse = checked
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
