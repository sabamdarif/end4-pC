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
        icon: "voting_chip"
        shape: MaterialShape.Shape.Sunny
        title: Translation.tr("On-screen display")
        GroupedList {
            ConfigSpinBox {
                icon: "av_timer"
                text: Translation.tr("Timeout (ms)")
                value: Config.options.osd.timeout
                from: 100
                to: 3000
                stepSize: 100
                onValueChanged: {
                    Config.options.osd.timeout = value;
                }
            }
        }
    }
}
