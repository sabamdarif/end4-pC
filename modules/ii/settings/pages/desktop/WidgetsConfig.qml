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
                    },
                    {
                        icon: "text_fields",
                        name: Translation.tr("Text"),
                        enabled: Config.options.background.widgets.customText.enable
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
                                    else if (modelData.icon === "text_fields")
                                        Config.options.background.widgets.customText.enable = checked
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

        // From https://github.com/pctrade/end4-pC/pull/151 by @SDcold
        ContentSection {
            id: settingsVisualizer
            icon: "graphic_eq"
            shape: MaterialShape.Shape.Burst
            title: Translation.tr("Visualizer")
            visible: settingsVisualizer.entry.enable

            readonly property var entry: Config.options.background.widgets.visualizer
            readonly property bool bandStyle: ["mirror", "aurora", "dots"].includes(entry.style)

            ContentSubsection {
                title: Translation.tr("Style")

                ConfigSelectionArray {
                    currentValue: settingsVisualizer.entry.style
                    onSelected: newValue => {
                        settingsVisualizer.entry.style = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Classic"),
                            icon: "bar_chart",
                            value: "bars"
                        },
                        {
                            displayName: Translation.tr("Mirror"),
                            icon: "equalizer",
                            value: "mirror"
                        },
                        {
                            displayName: Translation.tr("Aurora"),
                            icon: "waves",
                            value: "aurora"
                        },
                        {
                            displayName: Translation.tr("Ring"),
                            icon: "album",
                            value: "ring"
                        },
                        {
                            displayName: Translation.tr("Dots"),
                            icon: "grid_on",
                            value: "dots"
                        }
                    ]
                }
            }

            NoticeBox {
                Layout.fillWidth: true
                visible: settingsVisualizer.entry.style === "ring"
                materialIcon: "touch_app"
                text: Translation.tr("Drag the ring on your desktop to move it, drag its corner to resize it")
            }

            ConfigSelectionArray {
                visible: settingsVisualizer.entry.style !== "bars"
                text: Translation.tr("Colors")
                icon: "palette"
                currentValue: settingsVisualizer.entry.colorSource
                onSelected: newValue => {
                    settingsVisualizer.entry.colorSource = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Theme"),
                        icon: "palette",
                        value: "theme"
                    },
                    {
                        displayName: Translation.tr("Album cover"),
                        icon: "album",
                        value: "cover"
                    }
                ]
            }

            GroupedList {
                visible: settingsVisualizer.entry.style !== "bars"

                ConfigSlider {
                    text: Translation.tr("Sensitivity (%)")
                    buttonIcon: "tune"
                    usePercentTooltip: false
                    value: settingsVisualizer.entry.sensitivity * 100
                    from: 50
                    to: 300
                    stopIndicatorValues: [100]
                    onValueChanged: {
                        settingsVisualizer.entry.sensitivity = Math.round(value) / 100;
                    }
                }
                ConfigSlider {
                    visible: settingsVisualizer.bandStyle
                    text: Translation.tr("Height")
                    buttonIcon: "height"
                    usePercentTooltip: false
                    value: settingsVisualizer.entry.height
                    from: 120
                    to: 600
                    stopIndicatorValues: [260]
                    onValueChanged: {
                        settingsVisualizer.entry.height = Math.round(value);
                    }
                }
                ConfigSlider {
                    visible: settingsVisualizer.entry.style === "ring"
                    text: Translation.tr("Size")
                    buttonIcon: "aspect_ratio"
                    usePercentTooltip: false
                    value: settingsVisualizer.entry.ringSize
                    from: 200
                    to: 900
                    stopIndicatorValues: [380]
                    onValueChanged: {
                        settingsVisualizer.entry.ringSize = Math.round(value);
                    }
                }
            }
        }

        // From https://github.com/pctrade/end4-pC/pull/147 by @SDcold
        ContentSection {
            id: settingsCustomText
            icon: "text_fields"
            shape: MaterialShape.Shape.Cookie4Sided
            title: Translation.tr("Text")
            visible: settingsCustomText.entry.enable

            readonly property var entry: Config.options.background.widgets.customText

            GroupedList {
                ConfigSwitch {
                    Layout.fillWidth: true
                    buttonIcon: "shadow"
                    text: Translation.tr("Shadow")
                    checked: settingsCustomText.entry.shadow
                    onCheckedChanged: {
                        settingsCustomText.entry.shadow = checked;
                    }
                }
            }

            NoticeBox {
                Layout.fillWidth: true
                materialIcon: "touch_app"
                text: Translation.tr("Double-click the text on your desktop to edit it, drag its corner to resize it")
            }

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Text to display")
                text: settingsCustomText.entry.content
                wrapMode: TextEdit.Wrap

                Timer {
                    id: customTextContentDebounce
                    interval: 500
                    repeat: false
                    onTriggered: {
                        settingsCustomText.entry.content = parent.text
                    }
                }

                onTextChanged: {
                    if (activeFocus) customTextContentDebounce.restart()
                }
            }

            ContentSubsection {
                title: Translation.tr("Font")

                ConfigSelectionArray {
                    currentValue: settingsCustomText.entry.fontFamily
                    onSelected: newValue => {
                        settingsCustomText.entry.fontFamily = newValue;
                    }
                    options: Fonts.handwritingFamilies.map(family => ({
                        displayName: family,
                        value: family
                    }))
                }

                MaterialTextArea {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    placeholderText: Translation.tr("Other font (any installed font family)")
                    text: Fonts.handwritingFamilies.includes(settingsCustomText.entry.fontFamily) ? "" : settingsCustomText.entry.fontFamily
                    wrapMode: TextEdit.Wrap

                    Timer {
                        id: customTextFontDebounce
                        interval: 500
                        repeat: false
                        onTriggered: {
                            if (parent.text.trim() !== "")
                                settingsCustomText.entry.fontFamily = parent.text.trim()
                        }
                    }

                    onTextChanged: {
                        if (activeFocus) customTextFontDebounce.restart()
                    }
                }
            }

            GroupedList {
                ConfigSlider {
                    text: Translation.tr("Font size")
                    value: settingsCustomText.entry.fontSize
                    usePercentTooltip: false
                    buttonIcon: "format_size"
                    from: 12
                    to: 400
                    stopIndicatorValues: [72]
                    onValueChanged: {
                        settingsCustomText.entry.fontSize = Math.round(value);
                    }
                }
            }

            ConfigSelectionArray {
                text: Translation.tr("Alignment")
                icon: "format_align_center"
                currentValue: settingsCustomText.entry.alignment
                onSelected: newValue => {
                    settingsCustomText.entry.alignment = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Left"),
                        icon: "format_align_left",
                        value: "left"
                    },
                    {
                        displayName: Translation.tr("Center"),
                        icon: "format_align_center",
                        value: "center"
                    },
                    {
                        displayName: Translation.tr("Right"),
                        icon: "format_align_right",
                        value: "right"
                    }
                ]
            }

            GroupedList {
                ConfigSwitch {
                    id: customTextAutoColorSwitch
                    buttonIcon: "auto_awesome"
                    text: Translation.tr("Automatic colors")
                    checked: settingsCustomText.entry.color === ""
                    onCheckedChanged: {
                        if (checked) {
                            settingsCustomText.entry.color = ""
                        }
                    }
                }

                ColorSelectionArray {
                    icon: "palette"
                    text: Translation.tr("Color")
                    currentValue: settingsCustomText.entry.color
                    onSelected: newValue => {
                        settingsCustomText.entry.color = newValue
                        customTextAutoColorSwitch.checked = false
                    }
                }
            }
        }
    }
}
