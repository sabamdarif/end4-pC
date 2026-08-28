import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    ContentSection {
        icon: "pivot_table_chart"
        shape: MaterialShape.Shape.Gem
        title: Translation.tr("Positioning & Styles")
        GroupedList {
            ConfigSelectionArray {
                text: Translation.tr("Bar position")
                icon: "swap_vert"
                currentValue: (Config.options.bar.bottom ? 1 : 0) | (Config.options.bar.vertical ? 2 : 0)
                onSelected: newValue => {
                    Config.options.bar.bottom = (newValue & 1) !== 0;
                    Config.options.bar.vertical = (newValue & 2) !== 0;
                }
                options: [
                    { displayName: Translation.tr("Top"),    icon: "arrow_upward",   value: 0 },
                    { displayName: Translation.tr("Left"),   icon: "arrow_back",     value: 2 },
                    { displayName: Translation.tr("Bottom"), icon: "arrow_downward", value: 1 },
                    { displayName: Translation.tr("Right"),  icon: "arrow_forward",  value: 3 }
                ]
            }
            ConfigSelectionArray {
                text: Translation.tr("Bar style")
                icon: "style"
                currentValue: Config.options.bar.cornerStyle
                onSelected: newValue => { Config.options.bar.cornerStyle = newValue; }
                options: [
                    { displayName: Translation.tr("Hug"),     icon: "line_curve", value: 0 },
                    { displayName: Translation.tr("Float"),   icon: "view_day",   value: 1 },
                    { displayName: Translation.tr("Islands"), icon: "crop_3_2",   value: 2 },
                    { displayName: Translation.tr("M3"), icon: "interests",   value: 3 }
                ]
            }
            ConfigSelectionArray {
                text: Translation.tr("Group style")
                icon: "tab_group"
                currentValue: Config.options.bar.borderless
                onSelected: newValue => { Config.options.bar.borderless = newValue; }
                options: [
                    { displayName: Translation.tr(""),          icon: "block",          value: "transparent" },
                    { displayName: Translation.tr("Pills"),     icon: "pill",           value: "pills" },
                    { displayName: Translation.tr("Separated"), icon: "view_column_2",  value: "separated" }
                ]
            }
            ConfigRow{
                uniform: true
                ConfigSwitch {
                    buttonIcon: "variable_insert"
                    text: Translation.tr("Show Background")
                    enabled: Config.options.bar.cornerStyle === 0 || Config.options.bar.cornerStyle === 1
                    checked: Config.options.bar.showBackground
                    onCheckedChanged: { Config.options.bar.showBackground = checked; }
                }
                ConfigSelectionArray {
                    text: Translation.tr("Autohide")
                    icon: "preview_off"
                    currentValue: Config.options.bar.autoHide.enable
                    onSelected: newValue => { Config.options.bar.autoHide.enable = newValue; }
                    options: [
                        { displayName: Translation.tr("No"),  icon: "close", value: false },
                        { displayName: Translation.tr("Yes"), icon: "check", value: true }
                    ]
                }
            }
        }
    }
}
