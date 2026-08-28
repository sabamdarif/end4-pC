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
        icon: "deployed_code_update"
        title: Translation.tr("System updates (Arch only)")

        GroupedList {
            ConfigSwitch {
                buttonIcon: "update"
                text: Translation.tr("Enable update checks")
                checked: Config.options.updates.enableCheck
                onCheckedChanged: {
                    Config.options.updates.enableCheck = checked;
                }
            }

            ConfigSpinBox {
                icon: "av_timer"
                text: Translation.tr("Check interval (mins)")
                value: Config.options.updates.checkInterval
                from: 60
                to: 1440
                stepSize: 60
                onValueChanged: {
                    Config.options.updates.checkInterval = value;
                }
            }
        }
    }
}
