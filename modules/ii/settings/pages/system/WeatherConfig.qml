import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true
    bottomContentPadding: 15

    ContentSection {
        icon: "weather_mix"
        shape: MaterialShape.Shape.Pill
        title: Translation.tr("Weather")
        GroupedList {
            ConfigSwitch {
                buttonIcon: "assistant_navigation"
                text: Translation.tr("Enable GPS based location")
                checked: Config.options.bar.weather.enableGPS
                onCheckedChanged: {
                    Config.options.bar.weather.enableGPS = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "thermometer"
                text: Translation.tr("Fahrenheit unit")
                checked: Config.options.bar.weather.useUSCS
                onCheckedChanged: {
                    Config.options.bar.weather.useUSCS = checked;
                }
            }
            ConfigSpinBox {
                icon: "av_timer"
                text: Translation.tr("Polling interval (m)")
                value: Config.options.bar.weather.fetchInterval
                from: 5
                to: 50
                stepSize: 5
                onValueChanged: {
                    Config.options.bar.weather.fetchInterval = value;
                }
            }
            ConfigTextArea {
                id: cityField
                Layout.fillWidth: true
                buttonIcon: "location_city"
                text: Translation.tr("City name")
                value: Config.options.bar.weather.city
                onValueChanged: cityDebounceTimer.restart()

                Timer {
                    id: cityDebounceTimer
                    interval: 1000
                    running: false
                    onTriggered: Config.options.bar.weather.city = cityField.value
                }
            }
        }
    }
}
