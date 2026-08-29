import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    // SystemTheming.applyCursorTheme also writes NiriConfig.options.cursor, so
    // SystemTheming is the single source of truth on both compositors.
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
