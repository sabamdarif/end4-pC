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
                // "When not fullscreen" needs Hyprland's fullscreen state; niri's
                // window IPC exposes no fullscreen flag, so it would behave like "Yes".
                options: NiriData.isNiri ? [
                    { displayName: Translation.tr("No"),  icon: "close", value: 0 },
                    { displayName: Translation.tr("Yes"), icon: "check", value: 1 }
                ] : [
                    { displayName: Translation.tr("No"),                  icon: "close",           value: 0 },
                    { displayName: Translation.tr("Yes"),                 icon: "check",           value: 1 },
                    { displayName: Translation.tr("When not fullscreen"), icon: "fullscreen_exit", value: 2 }
                ]
            }
        }
    }
}
