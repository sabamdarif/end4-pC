import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    ContentSection {
        shape: MaterialShape.Shape.Cookie12Sided
        icon: "steppers"; title: Translation.tr("Workspaces")
        GroupedList {
            ConfigSwitch {
                buttonIcon: "counter_1"; text: Translation.tr("Always show numbers")
                checked: Config.options.bar.workspaces.alwaysShowNumbers
                onCheckedChanged: { Config.options.bar.workspaces.alwaysShowNumbers = checked; }
            }
            ConfigSelectionArray {
                text: Translation.tr("Numbers style")
                icon: "looks_3"
                currentValue: JSON.stringify(Config.options.bar.workspaces.numberMap)
                onSelected: newValue => {
                    Config.options.bar.workspaces.numberMap = JSON.parse(newValue)
                }
                options: [
                    { displayName: Translation.tr("Normal"),    icon: "timer_10",        value: '[]' },
                    { displayName: Translation.tr("Han chars"), icon: "glyphs",          value: '["一","二","三","四","五","六","七","八","九","十","十一","十二","十三","十四","十五","十六","十七","十八","十九","二十"]' },
                    { displayName: Translation.tr("Roman"),     icon: "account_balance", value: '["I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII","XIII","XIV","XV","XVI","XVII","XVIII","XIX","XX"]' }
                ]
            }
            ConfigSwitch {
                buttonIcon: "award_star"; text: Translation.tr("Show app icons")
                checked: Config.options.bar.workspaces.showAppIcons
                onCheckedChanged: { Config.options.bar.workspaces.showAppIcons = checked; }
            }
            ConfigSelectionArray {
                text: Translation.tr("Indicator style")
                icon: "page_control"
                currentValue: Config.options.bar.workspaces.indicatorStyle ?? "icon"
                onSelected: newValue => {
                    Config.options.bar.workspaces.indicatorStyle = newValue
                }
                options: [
                    { displayName: Translation.tr("Dots"),  icon: "radio_button_checked",   value: "dot" },
                    { displayName: Translation.tr("Icons"), icon: "interests",              value: "icon" },
                ]
            }
        }
    }
}
