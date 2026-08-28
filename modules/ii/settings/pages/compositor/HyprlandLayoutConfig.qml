import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    HyprlandConfigSync {}

    ContentSection {
        icon: "auto_awesome_mosaic"
        shape: MaterialShape.Shape.Gem
        title: Translation.tr("Layout")

        GroupedList {
            ConfigSelectionArray {
                text: Translation.tr("Tiling Layout")
                icon: "responsive_layout"
                currentValue: Config.options.hyprland.general.layout
                onSelected: newValue => {
                    Config.options.hyprland.general.layout = newValue
                    HyprlandConfig.set("general:layout", newValue)
                }
                options: [
                    { displayName: Translation.tr("Dwindle"),   icon: "browse",             value: "dwindle"   },
                    { displayName: Translation.tr("Master"),    icon: "auto_awesome_mosaic", value: "master"    },
                    { displayName: Translation.tr("Scrolling"), icon: "view_carousel",       value: "scrolling" },
                ]
            }
        }
    }
}
