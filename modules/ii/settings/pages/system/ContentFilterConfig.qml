import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    ContentSection {
        icon: "work_alert"
        shape: MaterialShape.Shape.PuffyDiamond
        title: Translation.tr("Work safety")
        GroupedList {
            ConfigSwitch {
                buttonIcon: "assignment"
                text: Translation.tr("Hide clipboard images copied from sussy sources")
                checked: Config.options.workSafety.enable.clipboard
                onCheckedChanged: {
                    Config.options.workSafety.enable.clipboard = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "wallpaper"
                text: Translation.tr("Hide sussy/anime wallpapers")
                checked: Config.options.workSafety.enable.wallpaper
                onCheckedChanged: {
                    Config.options.workSafety.enable.wallpaper = checked;
                }
            }
        }
    }
}
