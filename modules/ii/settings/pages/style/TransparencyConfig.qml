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
        icon: "motion_mode"
        shape: MaterialShape.Shape.Puffy
        title: Translation.tr("Transparency")

        GroupedList {
            ConfigSwitch {
                buttonIcon: "motion_mode"
                text: Translation.tr("Transparency")
                checked: Config.options.appearance.transparency.enable
                onCheckedChanged: { Config.options.appearance.transparency.enable = checked; }
            }
            ConfigSwitch {
                buttonIcon: "autofps_select"
                enabled: Config.options.appearance.transparency.enable
                text: Translation.tr("Automatic")
                checked: Config.options.appearance.transparency.automatic
                onCheckedChanged: { Config.options.appearance.transparency.automatic = checked; }
            }
        }
    }
}
