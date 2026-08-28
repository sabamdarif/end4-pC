import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import Quickshell

ContentPage {
    id: page
    forceWidth: true

    ContentSection {
        icon: "widgets"
        shape: MaterialShape.Shape.Pill
        title: Translation.tr("Widgets")

        ContentSubsection {
            title: Translation.tr("Show widgets on")
            visible: Quickshell.screens.length > 1
            Layout.bottomMargin: 10

            WidgetsMonitorSelector {
                configEntry: Config.options.background
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 3
            rowSpacing: 8
            columnSpacing: 8
            Repeater {
                model: [
                    {
                        icon: "weather_mix",
                        name: Translation.tr("Weather"),
                        enabled: Config.options.background.widgets.weather.enable
                    },
                    {
                        icon: "image",
                        name: Translation.tr("Image converter"),
                        enabled: Config.options.background.widgets.images.enable
                    },
                    {
                        icon: "music_note",
                        name: Translation.tr("Media Player"),
                        enabled: Config.options.background.widgets.media.enable
                    },
                    {
                        icon: "memory",
                        name: Translation.tr("Resources"),
                        enabled: Config.options.background.widgets.resources.enable
                    },
                    {
                        icon: "graphic_eq",
                        name: Translation.tr("Visualizer"),
                        enabled: Config.options.background.widgets.visualizer.enable
                    },
                    {
                        icon: "calendar_month",
                        name: Translation.tr("Calendar"),
                        enabled: Config.options.background.widgets.calendar.enable
                    },
                    {
                        icon: "public",
                        name: Translation.tr("World Clock"),
                        enabled: Config.options.background.widgets.worldClock.enable
                    },
                    {
                        icon: "person",
                        name: Translation.tr("User Card"),
                        enabled: Config.options.background.widgets.userCard.enable
                    },
                    {
                        icon: "note_stack_add",
                        name: Translation.tr("Notes"),
                        enabled: Config.options.background.widgets.notes.enable
                    }
                ]
                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 105
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border
                    ColumnLayout {
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 12
                        }
                        spacing: 0
                        RowLayout {
                            Layout.fillWidth: true
                            MaterialSymbol {
                                text: modelData.icon
                                iconSize: Appearance.font.pixelSize.normal + 5
                                color: Appearance.colors.colPrimary
                            }
                            Item { Layout.fillWidth: true }
                            ConfigSwitch {
                                Layout.fillWidth: false
                                checked: modelData.enabled
                                onCheckedChanged: {
                                    if (modelData.icon === "weather_mix")
                                        Config.options.background.widgets.weather.enable = checked
                                    else if (modelData.icon === "image")
                                        Config.options.background.widgets.images.enable = checked
                                    else if (modelData.icon === "music_note")
                                        Config.options.background.widgets.media.enable = checked
                                    else if (modelData.icon === "memory")
                                        Config.options.background.widgets.resources.enable = checked
                                    else if (modelData.icon === "graphic_eq")
                                        Config.options.background.widgets.visualizer.enable = checked
                                    else if (modelData.icon === "calendar_month")
                                        Config.options.background.widgets.calendar.enable = checked
                                    else if (modelData.icon === "public")
                                        Config.options.background.widgets.worldClock.enable = checked
                                    else if (modelData.icon === "person")
                                        Config.options.background.widgets.userCard.enable = checked
                                    else if (modelData.icon === "note_stack_add")
                                        Config.options.background.widgets.notes.enable = checked
                                }
                            }
                        }
                        StyledText {
                            text: modelData.name
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: modelData.enabled ? Translation.tr("Enabled") : Translation.tr("Disabled")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Canvas")
            Layout.bottomMargin: 10

            GroupedList {
                ConfigSwitch {
                    Layout.fillWidth: true
                    buttonIcon: "grid_4x4"
                    text: Translation.tr("Show alignment grid while dragging")
                    checked: Config.options.background.showGrid
                    onCheckedChanged: {
                        Config.options.background.showGrid = checked;
                    }
                }
                ConfigSwitch {
                    Layout.fillWidth: true
                    buttonIcon: "align_horizontal_center"
                    text: Translation.tr("Show snap lines when dropping")
                    checked: Config.options.background.showSnapLines
                    onCheckedChanged: {
                        Config.options.background.showSnapLines = checked;
                    }
                }
            }
        }
    }
}
