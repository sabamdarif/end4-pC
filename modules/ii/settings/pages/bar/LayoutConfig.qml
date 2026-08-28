import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Quickshell

ContentPage {
    id: page
    forceWidth: true

    property var allWidgets: [
        { id: "leftSidebarButton", name: Translation.tr("Left Sidebar Button"),  icon: "left_panel_open" },
        { id: "workspaces",        name: Translation.tr("Workspaces"),           icon: "steppers" },
        { id: "weatherBar",        name: Translation.tr("Weather"),              icon: "flare" },
        { id: "media",             name: Translation.tr("Media"),                icon: "music_note" },
        { id: "resources",         name: Translation.tr("Resources"),            icon: "empty_dashboard" },
        { id: "systemIcons",       name: Translation.tr("System Icons"),         icon: "info" },
        { id: "networkSpeed",      name: Translation.tr("Network Speed"),        icon: "network_check" },
        { id: "clockWidget",       name: Translation.tr("Clock"),                icon: "schedule" },
        { id: "utilButtons",       name: Translation.tr("Util Buttons"),         icon: "toggle_on" },
        { id: "sysTray",           name: Translation.tr("Tray"),                 icon: "inbox" },
        { id: "batteryIndicator",  name: Translation.tr("Battery"),              icon: "battery_android_frame_full" },
        { id: "bluetooth",         name: Translation.tr("Bluetooth"),            icon: "bluetooth" },
        { id: "activeWindow",      name: Translation.tr("Active Window"),        icon: "subtitles" },
        { id: "powerButton",       name: Translation.tr("Power Button"),         icon: "power_settings_new" },
        { id: "updatesCount",      name: Translation.tr("Updates"),              icon: "deployed_code_update" },
        { id: "docktoPanel",       name: Translation.tr("Dock to Panel"),        icon: "apps" },
        { id: "visualizer",        name: Translation.tr("Visualizer"),           icon: "graphic_eq" },
        { id: "hyprlandXkbIndicator",   name: Translation.tr("Keyboard Layout"), icon: "keyboard" },
        { id: "divisor",            name: Translation.tr("Divider"),             icon: "horizontal_distribute" },
    ]

    function availableFor() {
        let used = [
            ...Config.options.bar.layouts.leftLayout,
            ...Config.options.bar.layouts.middleLayout,
            ...Config.options.bar.layouts.rightLayout
        ]
        const multipleAllowed = ["visualizer", "divisor"]
        return allWidgets.filter(w => {
            if (w.id === "divisor" && Config.options.bar.borderless !== "transparent") return false
            return !used.includes(w.id) || multipleAllowed.includes(w.id)
        })
    }

    function getWidgetName(id) {
        const w = allWidgets.find(w => w.id === id)
        return w ? w.name : id
    }

    ContentSection {
        icon: "splitscreen_add"
        shape: MaterialShape.Shape.Cookie6Sided
        title: Translation.tr("Bar layout")

        GroupedList {
            LayoutSection {
                sectionTitle: Config.options.bar.vertical ? Translation.tr("Top") : Translation.tr("Left")
                layout: Config.options.bar.layouts.leftLayout
                availableWidgets: page.availableFor()
                getWidgetName: page.getWidgetName
                onUpdate: list => Config.options.bar.layouts.leftLayout = list
            }

            LayoutSection {
                sectionTitle: Translation.tr("Center")
                layout: Config.options.bar.layouts.middleLayout
                availableWidgets: page.availableFor()
                getWidgetName: page.getWidgetName
                onUpdate: list => Config.options.bar.layouts.middleLayout = list
            }

            LayoutSection {
                sectionTitle: Config.options.bar.vertical ? Translation.tr("Bottom") : Translation.tr("Right")
                layout: Config.options.bar.layouts.rightLayout
                availableWidgets: page.availableFor()
                getWidgetName: page.getWidgetName
                onUpdate: list => Config.options.bar.layouts.rightLayout = list
            }
        }
    }
}
