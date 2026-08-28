import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    ContentSection {
        icon: "battery_android_full"
        shape: MaterialShape.Shape.SemiCircle
        title: Translation.tr("Battery")
        visible: Battery.available

        GroupedList {
            ConfigRow {
                uniform: true
                ConfigSpinBox {
                    icon: "warning"
                    text: Translation.tr("Low warning")
                    value: Config.options.battery.low
                    from: 0
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.options.battery.low = value;
                    }
                }
                ConfigSpinBox {
                    icon: "dangerous"
                    text: Translation.tr("Critical warning")
                    value: Config.options.battery.critical
                    from: 0
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.options.battery.critical = value;
                    }
                }
            }
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "pause"
                    text: Translation.tr("Automatic suspend")
                    checked: Config.options.battery.automaticSuspend
                    onCheckedChanged: {
                        Config.options.battery.automaticSuspend = checked;
                    }
                }
                ConfigSpinBox {
                    enabled: Config.options.battery.automaticSuspend
                    text: Translation.tr("at")
                    value: Config.options.battery.suspend
                    from: 0
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.options.battery.suspend = value;
                    }
                }
            }
            ConfigRow {
                uniform: true
                ConfigSpinBox {
                    icon: "charger"
                    text: Translation.tr("Full warning")
                    value: Config.options.battery.full
                    from: 0
                    to: 101
                    stepSize: 5
                    onValueChanged: {
                        Config.options.battery.full = value;
                    }
                }
            }
        }
    }
}
