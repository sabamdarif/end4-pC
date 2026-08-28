import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    ContentSection {
        icon: "empty_dashboard"
        shape: MaterialShape.Shape.Burst
        title: Translation.tr("Resources")

        GroupedList {
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "planner_review"
                    text: Translation.tr("CPU")
                    checked: Config.options.bar.resources.alwaysShowCpu
                    onCheckedChanged: { Config.options.bar.resources.alwaysShowCpu = checked }
                }
                ConfigSwitch {
                    buttonIcon: "thermostat"
                    text: Translation.tr("CPU Temperature")
                    checked: Config.options.bar.resources.alwaysShowCpuTemp
                    onCheckedChanged: { Config.options.bar.resources.alwaysShowCpuTemp = checked }
                }
            }
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "memory"
                    text: Translation.tr("RAM")
                    checked: Config.options.bar.resources.alwaysShowRam
                    onCheckedChanged: { Config.options.bar.resources.alwaysShowRam = checked }
                }
                ConfigSwitch {
                    buttonIcon: "storage"
                    text: Translation.tr("Disk")
                    checked: Config.options.bar.resources.alwaysShowDisk
                    onCheckedChanged: { Config.options.bar.resources.alwaysShowDisk = checked }
                }
            }
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "swap_horiz"
                    text: Translation.tr("Swap")
                    checked: Config.options.bar.resources.alwaysShowSwap
                    onCheckedChanged: { Config.options.bar.resources.alwaysShowSwap = checked }
                }
            }
            ConfigSelectionArray {
                text: Translation.tr("Style")
                icon: "style"
                currentValue: Config.options.bar.resources.style
                onSelected: newValue => { Config.options.bar.resources.style = newValue; }
                options: [
                    { displayName: Translation.tr("Filled"),    icon: "incomplete_circle",  value: "filled" },
                    { displayName: Translation.tr("Outline"),   icon: "circles",            value: "outline" }
                ]
            }
            ConfigSwitch {
                buttonIcon: "decimal_increase"; text: Translation.tr("Show Percentage")
                checked: Config.options.bar.resources.showValue
                onCheckedChanged: { Config.options.bar.resources.showValue = checked; }
            }
            ConfigSpinBox {
                icon: "av_timer"
                text: Translation.tr("Polling interval (ms)")
                value: Config.options.resources.updateInterval
                from: 100
                to: 10000
                stepSize: 100
                onValueChanged: {
                    Config.options.resources.updateInterval = value;
                }
            }
        }
    }
}
