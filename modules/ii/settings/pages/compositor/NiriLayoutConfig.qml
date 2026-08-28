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
}
