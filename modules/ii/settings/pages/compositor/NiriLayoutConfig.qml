import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page

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
                onValueModified: {
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
        StyledText {
            Layout.fillWidth: true
            visible: NiriConfig.options.layout.defaultColumnWidth < 0
            text: Translation.tr("Custom column width: %1").arg(NiriConfig.defaultColumnWidthKdl)
            textFormat: Text.PlainText
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
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
                enabled: !NiriConfig.focusFollowsMouseOwnedByConfig
                checked: NiriConfig.options.input.focusFollowsMouse
                onCheckedChanged: {
                    if (checked === NiriConfig.options.input.focusFollowsMouse) return
                    NiriConfig.options.input.focusFollowsMouse = checked
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
