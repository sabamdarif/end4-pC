import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    ContentSection {
        icon: "buttons_alt"
        shape: MaterialShape.Shape.SoftBurst
        title: Translation.tr("Utility buttons")

        GroupedList {
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "screenshot_region"
                    text: Translation.tr("Screen snip")
                    checked: Config.options.bar.utilButtons.showScreenSnip
                    onCheckedChanged: { Config.options.bar.utilButtons.showScreenSnip = checked }
                }
                ConfigSwitch {
                    buttonIcon: "colorize"
                    text: Translation.tr("Color picker")
                    checked: Config.options.bar.utilButtons.showColorPicker
                    onCheckedChanged: { Config.options.bar.utilButtons.showColorPicker = checked }
                }
            }
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "mic"
                    text: Translation.tr("Mic toggle")
                    checked: Config.options.bar.utilButtons.showMicToggle
                    onCheckedChanged: { Config.options.bar.utilButtons.showMicToggle = checked }
                }
                ConfigSwitch {
                    buttonIcon: "dark_mode"
                    text: Translation.tr("Dark/Light toggle")
                    checked: Config.options.bar.utilButtons.showDarkModeToggle
                    onCheckedChanged: { Config.options.bar.utilButtons.showDarkModeToggle = checked }
                }
            }
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "speed"
                    text: Translation.tr("Performance Profile")
                    checked: Config.options.bar.utilButtons.showPerformanceProfileToggle
                    onCheckedChanged: { Config.options.bar.utilButtons.showPerformanceProfileToggle = checked }
                }
                ConfigSwitch {
                    buttonIcon: "screen_record"
                    text: Translation.tr("Record Screen")
                    checked: Config.options.bar.utilButtons.showScreenRecord
                    onCheckedChanged: { Config.options.bar.utilButtons.showScreenRecord = checked }
                }
            }
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "imagesmode"
                    text: Translation.tr("Wallpapers Toggle")
                    checked: Config.options.bar.utilButtons.showWallpaperToggle
                    onCheckedChanged: { Config.options.bar.utilButtons.showWallpaperToggle = checked }
                }
            }
        }
    }
}
