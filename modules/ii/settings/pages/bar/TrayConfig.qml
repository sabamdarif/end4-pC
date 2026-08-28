import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    ContentSection {
        shape: MaterialShape.Shape.Square
        icon: "inbox_customize"
        title: Translation.tr("Tray")
        GroupedList {
            ConfigSwitch {
                buttonIcon: "keep"; text: Translation.tr("Make icons pinned by default")
                checked: Config.options.tray.invertPinnedItems
                onCheckedChanged: { Config.options.tray.invertPinnedItems = checked; }
            }
            ConfigSwitch {
                buttonIcon: "colors"; text: Translation.tr("Tint icons")
                checked: Config.options.tray.monochromeIcons
                onCheckedChanged: { Config.options.tray.monochromeIcons = checked; }
            }
        }
    }
}
