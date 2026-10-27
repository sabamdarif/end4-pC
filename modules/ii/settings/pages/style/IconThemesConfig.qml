import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    ContentSection {
        icon: "palette"
        title: Translation.tr("Icons & App Themes")
        shape: MaterialShape.Shape.Slanted

        GroupedList {
            ConfigComboBox {
                buttonIcon: "interests"
                text: Translation.tr("Icon theme")
                model: SystemTheming.iconThemes.map(t => ({ displayName: t, value: t }))
                currentValue: SystemTheming.currentIconTheme
                onSelected: newValue => SystemTheming.applyIconTheme(newValue)
            }
            ConfigComboBox {
                buttonIcon: "brush"
                text: Translation.tr("GTK theme")
                model: SystemTheming.gtkThemes.map(t => ({ displayName: t, value: t }))
                currentValue: SystemTheming.currentGtkTheme
                onSelected: newValue => SystemTheming.applyGtkTheme(newValue)
            }
            ConfigComboBox {
                buttonIcon: "format_paint"
                text: Translation.tr("Qt / Kvantum theme")
                enabled: false
                model: [{ displayName: Translation.tr("Default (WIP)"), value: "" }]
                currentValue: ""
            }
        }
    }

    ContentSection {
        icon: "mouse"
        shape: MaterialShape.Shape.Arrow
        title: Translation.tr("Cursor")

        GroupedList {
            ConfigComboBox {
                buttonIcon: "mouse"
                text: Translation.tr("Cursor theme")
                model: [{ displayName: Translation.tr("Default"), value: "" }]
                    .concat(SystemTheming.cursorThemes.map(t => ({ displayName: t, value: t })))
                currentValue: SystemTheming.currentCursorTheme
                onSelected: newValue => SystemTheming.applyCursorTheme(newValue, SystemTheming.currentCursorSize)
            }

            ConfigSpinBox {
                id: cursorSizeSpin
                icon: "zoom_in"
                text: Translation.tr("Cursor size")
                value: SystemTheming.currentCursorSize
                from: 16; to: 64; stepSize: 2
                onValueChanged: {
                    if (value === SystemTheming.currentCursorSize) return
                    cursorSizeDebounceTimer.restart()
                }
                Timer {
                    id: cursorSizeDebounceTimer
                    interval: 500
                    repeat: false
                    onTriggered: SystemTheming.applyCursorTheme(SystemTheming.currentCursorTheme, cursorSizeSpin.value)
                }
            }

            ConfigSwitch {
                buttonIcon: "keyboard_hide"
                text: Translation.tr("Hide while typing")
                checked: NiriConfig.options.cursor.hideWhenTyping
                onCheckedChanged: {
                    if (checked === NiriConfig.options.cursor.hideWhenTyping) return
                    NiriConfig.options.cursor.hideWhenTyping = checked
                }
            }
        }
    }
}
