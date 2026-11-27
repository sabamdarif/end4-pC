import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page

    component SmallLightDarkPreferenceButton: RippleButton {
        id: smallLightDarkPreferenceButton
        required property bool dark
        property color colText: toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
        buttonRadius: Appearance.rounding.large
        padding: 8
        Layout.fillWidth: true
        toggled: Appearance.m3colors.darkmode === dark
        colBackground: Appearance.colors.colLayer2
        onClicked: {
            Quickshell.execDetached(["bash", Directories.wallpaperSwitchScriptPath, "--mode", dark ? "dark" : "light", "--noswitch"]);
        }
        contentItem: ColumnLayout {
            spacing: 2
            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                iconSize: 28
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

    ContentSection {
        icon: "screenshot_monitor"
        title: Translation.tr("Colors & Theme")
        shape: MaterialShape.Shape.Puffy
        Layout.fillWidth: true

        GridLayout {
            id: themeLayout
            Layout.fillWidth: true
            columns: width >= 800 ? 2 : 1
            columnSpacing: 16
            rowSpacing: 16

            Rectangle {
                id: wallpaperPreview
                Layout.fillWidth: true
                Layout.preferredWidth: 420
                Layout.maximumWidth: 420
                Layout.preferredHeight: width * 2 / 3
                Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
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
                            width: wallpaperPreview.width
                            height: wallpaperPreview.height
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
                        text: Translation.tr("Change accent color")
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    uniformCellSizes: true
                    SmallLightDarkPreferenceButton { dark: false }
                    SmallLightDarkPreferenceButton { dark: true }
                }
                GridLayout {
                    id: schemeGrid
                    Layout.fillWidth: true
                    columns: width >= 360 ? 3 : 2
                    rowSpacing: 8
                    columnSpacing: 8
                    uniformCellWidths: true
                    uniformCellHeights: true

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
                            { value: "scheme-vibrant",     displayName: Translation.tr("Vibrant"),     icon: "colors" },
                        ]

                        delegate: RippleButton {
                            id: schemeCard
                            required property var modelData
                            readonly property bool isSelected: Config.options.appearance.palette.type === modelData.value

                            Layout.fillWidth: true
                            implicitWidth: 120
                            implicitHeight: Math.max(72, schemeIcon.implicitHeight + schemeLabel.implicitHeight + 24)
                            padding: 0
                            buttonRadius: Appearance.rounding.large
                            buttonRadiusPressed: Appearance.rounding.small
                            toggled: isSelected
                            colBackground: Appearance.colors.colSecondaryContainer
                            colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                            colRipple: Appearance.colors.colSecondaryContainerActive
                            colBackgroundToggled: Appearance.colors.colPrimary
                            colBackgroundToggledHover: Appearance.colors.colPrimaryHover
                            colRippleToggled: Appearance.colors.colPrimaryActive

                            onClicked: {
                                Config.options.appearance.palette.type = modelData.value
                                Quickshell.execDetached(["bash", Directories.wallpaperSwitchScriptPath, "--noswitch"])
                            }

                            contentItem: Item {
                                anchors.fill: parent

                                MaterialSymbol {
                                    id: schemeIcon
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.margins: 10
                                    text: schemeCard.modelData.icon
                                    iconSize: Appearance.font.pixelSize.larger
                                    fill: schemeCard.isSelected ? 1 : 0
                                    color: schemeCard.isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer

                                    Behavior on color {
                                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                    }
                                }

                                StyledText {
                                    id: schemeLabel
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.margins: 10
                                    text: schemeCard.modelData.displayName
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    font.weight: schemeCard.isSelected ? Font.DemiBold : Font.Medium
                                    horizontalAlignment: Text.AlignRight
                                    wrapMode: Text.Wrap
                                    color: schemeCard.isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer

                                    Behavior on color {
                                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                    }
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
        }

        ContentSubsection {
            title: Translation.tr("App color templates (matugen)")

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Math.max(64, matugenTogglesCol.implicitHeight + 28)
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1

                ColumnLayout {
                    id: matugenTogglesCol
                    anchors { fill: parent; margins: 14 }
                    spacing: 4

                    StyledText {
                        visible: SystemTheming.matugenTemplates.length === 0
                        Layout.leftMargin: 8
                        Layout.fillHeight: SystemTheming.matugenTemplates.length === 0
                        verticalAlignment: Text.AlignVCenter
                        text: Translation.tr("No matugen config found (~/.config/matugen/config.toml)")
                        color: Appearance.colors.colSubtext
                    }

                    Repeater {
                        model: SystemTheming.matugenTemplates
                        delegate: ConfigSwitch {
                            required property var modelData
                            buttonIcon: "colors"
                            text: modelData.name
                            enabled: modelData.name !== "quickshell"
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
