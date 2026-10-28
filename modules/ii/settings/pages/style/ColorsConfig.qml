import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true
    baseWidth: 720

    function saveScheme() {
        const name = customSchemeNameField.value.trim();
        if (name === "") return;
        if (SystemTheming.saveCustomScheme(name, customSchemeType.pendingValue, customSchemeAccentField.value)) {
            customSchemeNameField.value = "";
            customSchemeAccentField.value = "";
        }
    }

    component SmallLightDarkPreferenceButton: RippleButton {
        id: smallLightDarkPreferenceButton
        required property bool dark
        property color colText: toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
        padding: 5
        Layout.fillWidth: true
        Layout.fillHeight: true
        toggled: Appearance.m3colors.darkmode === dark
        colBackground: Appearance.colors.colLayer2
        onClicked: {
            Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --mode ${dark ? "dark" : "light"} --noswitch`]);
        }
        contentItem: Item {
            anchors.centerIn: parent
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0
                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    iconSize: 30
                    text: dark ? "dark_mode" : "light_mode"
                    color: smallLightDarkPreferenceButton.colText
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: dark ? Translation.tr("Dark") : Translation.tr("Light")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: smallLightDarkPreferenceButton.colText
                }
            }
        }
    }

    ContentSection {
        icon: "screenshot_monitor"
        title: Translation.tr("Colors & Theme")
        shape: MaterialShape.Shape.Puffy
        Layout.fillWidth: true

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Rectangle {
                Layout.preferredWidth: 420
                Layout.preferredHeight: 280
                radius: Appearance.rounding.large - 3
                color: Appearance.colors.colLayer2
                clip: true

                StyledImage {
                    anchors.fill: parent
                    sourceSize.width: 420
                    sourceSize.height: 280
                    fillMode: Image.PreserveAspectCrop
                    source: /\.(mp4|webm|mkv|avi|mov)$/i.test(Config.options.background.wallpaperPath)
                        ? Config.options.background.thumbnailPath
                        : Config.options.background.wallpaperPath
                    cache: false
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: 420; height: 280
                            radius: Appearance.rounding.large - 3
                        }
                    }
                }

                ToolbarPairedFab {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.margins: 8
                    iconText: "colorize"
                    onClicked: {
                        Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--noswitch", "--color"]);
                    }
                    StyledToolTip {
                        text: "Change accent color"
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 2
                    uniformCellSizes: true
                    SmallLightDarkPreferenceButton { dark: false }
                    SmallLightDarkPreferenceButton { dark: true }
                }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    rowSpacing: 2
                    columnSpacing: 2

                    Repeater {
                        model: [
                            { value: "auto",               displayName: Translation.tr("Auto"),        icon: "auto_awesome" },
                            { value: "scheme-content",     displayName: Translation.tr("Content"),     icon: "image" },
                            { value: "scheme-expressive",  displayName: Translation.tr("Expressive"),  icon: "palette" },
                            { value: "scheme-fidelity",    displayName: Translation.tr("Fidelity"),    icon: "equal" },
                            { value: "scheme-fruit-salad", displayName: Translation.tr("Fruit Salad"), icon: "nutrition" },
                            { value: "scheme-monochrome",  displayName: Translation.tr("Monochrome"),  icon: "invert_colors" },
                            { value: "scheme-neutral",     displayName: Translation.tr("Neutral"),     icon: "tonality" },
                            { value: "scheme-rainbow",     displayName: Translation.tr("Rainbow"),     icon: "gradient" },
                            { value: "scheme-tonal-spot",  displayName: Translation.tr("Tonal Spot"),  icon: "lens" },
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: width * 0.6
                            radius: Appearance.rounding.normal

                            property bool isSelected: Config.options.appearance.palette.type === modelData.value
                            property bool hovered: hoverArea.containsMouse

                            color: isSelected ? Appearance.colors.colPrimary 
                                : hovered ? Appearance.colors.colSecondaryContainerHover 
                                : Appearance.colors.colSecondaryContainer

                            MaterialSymbol {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.margins: 8
                                text: modelData.icon
                                iconSize: Appearance.font.pixelSize.larger
                                color: parent.isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnPrimaryContainer
                            }

                            StyledText {
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right
                                anchors.margins: 8
                                text: modelData.displayName
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: Font.Medium
                                color: parent.isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnPrimaryContainer
                            }

                            MouseArea {
                                id: hoverArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Config.options.appearance.palette.type = modelData.value
                                    Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --noswitch`])
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "colors"
        title: Translation.tr("Color generation")
        shape: MaterialShape.Shape.VerySunny

        GroupedList {
            ConfigSwitch {
                buttonIcon: "hardware"
                text: Translation.tr("Shell & utilities")
                checked: Config.options.appearance.wallpaperTheming.enableAppsAndShell
                onCheckedChanged: { Config.options.appearance.wallpaperTheming.enableAppsAndShell = checked }
            }
            ConfigSwitch {
                buttonIcon: "tv_options_input_settings"
                text: Translation.tr("Qt apps")
                checked: Config.options.appearance.wallpaperTheming.enableQtApps
                onCheckedChanged: { Config.options.appearance.wallpaperTheming.enableQtApps = checked }
            }
            ConfigSwitch {
                buttonIcon: "terminal"
                text: Translation.tr("Terminal")
                checked: Config.options.appearance.wallpaperTheming.enableTerminal
                onCheckedChanged: { Config.options.appearance.wallpaperTheming.enableTerminal = checked }
            }
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "dark_mode"
                    text: Translation.tr("Force dark mode in terminal")
                    checked: Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode
                    onCheckedChanged: { Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode = checked }
                }
            }
            ConfigSpinBox {
                icon: "invert_colors"
                text: Translation.tr("Terminal: Harmony (%)")
                value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony * 100
                from: 0; to: 100; stepSize: 10
                onValueChanged: { Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony = value / 100 }
            }
            ConfigSpinBox {
                icon: "gradient"
                text: Translation.tr("Terminal: Harmonize threshold")
                value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold
                from: 0; to: 100; stepSize: 10
                onValueChanged: { Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold = value }
            }
            ConfigSpinBox {
                icon: "format_color_text"
                text: Translation.tr("Terminal: Foreground boost (%)")
                value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost * 100
                from: 0; to: 100; stepSize: 10
                onValueChanged: { Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost = value / 100 }
            }
        }

        ContentSubsection {
            title: Translation.tr("Saved matugen schemes")

            GroupedList {
                ConfigTextArea {
                    id: customSchemeNameField
                    buttonIcon: "bookmark_add"
                    text: Translation.tr("Scheme name")
                    placeholderText: Translation.tr("e.g. Soft night")
                    textArea.Keys.onReturnPressed: (event) => {
                        page.saveScheme();
                        event.accepted = true;
                    }
                }

                ConfigComboBox {
                    id: customSchemeType
                    property string pendingValue: Config.options.appearance.palette.type
                    buttonIcon: "palette"
                    text: Translation.tr("Scheme type")
                    model: SystemTheming.matugenSchemeOptions
                    currentValue: pendingValue
                    onSelected: newValue => pendingValue = newValue
                }

                ConfigTextArea {
                    id: customSchemeAccentField
                    buttonIcon: "colorize"
                    text: Translation.tr("Accent color")
                    description: Translation.tr("Optional six-digit hex color, for example #89b4fa")
                    placeholderText: Translation.tr("Leave empty to use the wallpaper")
                    value: ""
                    textArea.Keys.onReturnPressed: (event) => {
                        page.saveScheme();
                        event.accepted = true;
                    }
                }

                RowLayout {
                    spacing: 10
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8

                    MaterialSymbol {
                        text: "bookmark_add"
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnSecondaryContainer
                        opacity: customSchemeNameField.value.trim().length > 0 ? 1 : 0.4
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("Save as new custom scheme")
                        color: Appearance.colors.colOnSecondaryContainer
                        opacity: customSchemeNameField.value.trim().length > 0 ? 1 : 0.4
                    }

                    RippleButtonWithIcon {
                        Layout.preferredHeight: 36
                        buttonRadius: Appearance.rounding.small
                        materialIcon: "save"
                        mainText: Translation.tr("Save")
                        enabled: customSchemeNameField.value.trim().length > 0
                        opacity: enabled ? 1 : 0.4
                        onClicked: page.saveScheme()
                    }
                }
            }

            ContentSubsectionLabel {
                visible: Config.options.appearance.palette.customSchemes.length > 0
                Layout.topMargin: 8
                text: Translation.tr("Saved schemes")
            }

            Rectangle {
                Layout.fillWidth: true
                visible: Config.options.appearance.palette.customSchemes.length > 0
                implicitHeight: savedSchemesColumn.implicitHeight + 24
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1

                ColumnLayout {
                    id: savedSchemesColumn
                    anchors { fill: parent; margins: 12 }
                    spacing: 8

                    Repeater {
                        model: Config.options.appearance.palette.customSchemes
                        delegate: RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 10

                            MaterialSymbol {
                                text: "palette"
                                iconSize: Appearance.font.pixelSize.larger
                                color: (modelData.accentColor && modelData.accentColor !== "")
                                    ? modelData.accentColor
                                    : Appearance.colors.colPrimary
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                StyledText {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colOnLayer1
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: {
                                        const typeOption = SystemTheming.matugenSchemeOptions.find(o => o.value === modelData.type);
                                        const typeName = typeOption ? typeOption.displayName : (modelData.type ?? "auto");
                                        return (modelData.accentColor && modelData.accentColor !== "")
                                            ? `${typeName} • ${modelData.accentColor}`
                                            : `${typeName} • ${Translation.tr("Wallpaper")}`;
                                    }
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                    elide: Text.ElideRight
                                }
                            }

                            RippleButtonWithIcon {
                                materialIcon: "play_arrow"
                                mainText: Translation.tr("Apply")
                                onClicked: SystemTheming.applyCustomScheme(modelData)
                            }

                            RippleButtonWithIcon {
                                materialIcon: "delete"
                                mainText: Translation.tr("Remove")
                                onClicked: SystemTheming.removeCustomScheme(modelData.name)
                            }
                        }
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("App color templates (matugen)")

            // Templates parsed live from ~/.config/matugen/config.toml.orig — nothing hardcoded
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: matugenTogglesCol.implicitHeight + 28
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1

                ColumnLayout {
                    id: matugenTogglesCol
                    anchors { fill: parent; margins: 14 }
                    spacing: 4

                    StyledText {
                        visible: SystemTheming.matugenTemplates.length === 0
                        Layout.leftMargin: 8
                        text: Translation.tr("No matugen config found (~/.config/matugen/config.toml)")
                        color: Appearance.colors.colSubtext
                    }

                    Repeater {
                        model: SystemTheming.matugenTemplates
                        delegate: ConfigSwitch {
                            required property var modelData
                            buttonIcon: "colors"
                            text: modelData.name
                            checked: SystemTheming.templateEnabled(modelData.name)
                            onCheckedChanged: SystemTheming.setTemplateEnabled(modelData.name, checked)
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    Layout.leftMargin: 8
                    Layout.fillWidth: true
                    text: Translation.tr("Toggles apply on the next wallpaper change, or regenerate now")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.Wrap
                }
                RippleButtonWithIcon {
                    Layout.rightMargin: 6
                    Layout.preferredHeight: 40
                    buttonRadius: Appearance.rounding.normal
                    materialIcon: "refresh"
                    mainText: Translation.tr("Regenerate now")
                    onClicked: SystemTheming.regenerateColors()
                }
            }
        }
    }
}
