import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    ContentSection {
        shape: MaterialShape.Shape.Puffy
        icon: "panorama"
        title: Translation.tr("Wallpaper selector")

        GroupedList {
            ConfigSwitch {
                buttonIcon: "ad"
                text: Translation.tr('Use system file picker')
                checked: Config.options.wallpaperSelector.useSystemFileDialog
                onCheckedChanged: {
                    Config.options.wallpaperSelector.useSystemFileDialog = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "done"
                text: Translation.tr('Close after selection')
                checked: Config.options.wallpaperSelector.closeAfterSelection
                onCheckedChanged: {
                    Config.options.wallpaperSelector.closeAfterSelection = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "blur_on"
                text: Translation.tr('Show blur background')
                checked: Config.options.wallpaperSelector.showBlurBackground
                onCheckedChanged: {
                    Config.options.wallpaperSelector.showBlurBackground = checked;
                }
            }

            ConfigSpinBox {
                icon: "grid_on"
                text: Translation.tr("Columns in grid view")
                value: Config.options.wallpaperSelector.columns
                from: 3
                to: 10
                stepSize: 1
                onValueChanged: {
                    Config.options.wallpaperSelector.columns = value;
                }
            }

            ConfigSpinBox {
                icon: "timer"
                text: Translation.tr("Wallpaper change interval (min)")
                value: Config.options.wallpaperSelector.changeInterval / 60000
                from: 0
                to: 1440
                stepSize: 5
                onValueChanged: {
                    Config.options.wallpaperSelector.changeInterval = value * 60000;
                }
            }
        }
    }
}
