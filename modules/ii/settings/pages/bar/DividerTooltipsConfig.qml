import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    ContentSection {
        icon: "vertical_align_center"
        shape: MaterialShape.Shape.Diamond
        title: Translation.tr("Divider")

        GroupedList {
            ConfigSelectionArray {
                text: Translation.tr("Style")
                icon: "style"
                currentValue: Config.options.bar.divider.style
                onSelected: newValue => { Config.options.bar.divider.style = newValue; }
                options: [
                    { displayName: Translation.tr("Line"),  icon: "more_vert",       value: "rect" },
                    { displayName: Translation.tr("Dot"),   icon: "fiber_manual_record", value: "dot" },
                    { displayName: Translation.tr("Space"), icon: "space_bar",       value: "space" }
                ]
            }
            ConfigSpinBox {
                icon: "width"
                enabled: Config.options.bar.divider.style === "space"
                text: Translation.tr("Space width (px)")
                value: Config.options.bar.divider.spacing
                from: 4
                to: 100
                stepSize: 2
                onValueChanged: {
                    Config.options.bar.divider.spacing = value;
                }
            }
        }
    }

    ContentSection {
        shape: MaterialShape.Shape.Puffy
        icon: "tooltip"; title: Translation.tr("Tooltips")
        GroupedList {
            ConfigSwitch {
                buttonIcon: "ads_click"; text: Translation.tr("Click to show")
                checked: Config.options.bar.tooltips.clickToShow
                onCheckedChanged: { Config.options.bar.tooltips.clickToShow = checked; }
            }
        }
    }
}
