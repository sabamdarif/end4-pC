import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    ContentSection {
        icon: "rounded_corner"
        shape: MaterialShape.Shape.ClamShell
        title: Translation.tr("Screen Corners")

        GroupedList {
            ConfigSelectionArray {
                text: Translation.tr("Screen round corner")
                icon: "rounded_corner"
                currentValue: Config.options.appearance.fakeScreenRounding
                onSelected: newValue => { Config.options.appearance.fakeScreenRounding = newValue; }
                options: [
                    { displayName: Translation.tr("No"),                  icon: "close",           value: 0 },
                    { displayName: Translation.tr("Yes"),                 icon: "check",           value: 1 },
                    { displayName: Translation.tr("When not fullscreen"), icon: "fullscreen_exit", value: 2 }
                ]
            }
        }
    }
}
