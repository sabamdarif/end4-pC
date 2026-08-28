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
        icon: "palette"
        title: Translation.tr("Icons & App Themes")
        shape: MaterialShape.Shape.Slanted

        GroupedList {
            ConfigComboBox {
                buttonIcon: "interests"
                text: Translation.tr("Icon theme")
                model: SystemTheming.iconThemes.map(t => ({ displayName: t, value: t }))
                currentValue: SystemTheming.currentIconTheme
                onSelected: newValue => SystemTheming.applyIconTheme(newValue)
            }
            ConfigComboBox {
                buttonIcon: "brush"
                text: Translation.tr("GTK theme")
                description: Translation.tr("Base widget theme; colors come from wallpaper theming")
                model: SystemTheming.gtkThemes.map(t => ({ displayName: t, value: t }))
                currentValue: SystemTheming.currentGtkTheme
                onSelected: newValue => SystemTheming.applyGtkTheme(newValue)
            }
                                        }
    }
}
