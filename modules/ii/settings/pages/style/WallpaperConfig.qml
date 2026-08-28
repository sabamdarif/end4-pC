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

    function displayPathFor(path) {
        return /\.(mp4|webm|mkv|avi|mov)$/i.test(path)
            ? Config.options.background.thumbnailPath
            : path
    }

    ContentSection {
        icon: "panorama"
        title: Translation.tr("Wallpaper")
        shape: MaterialShape.Shape.Clover4Leaf

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: wrapperCol.implicitHeight + 16
            topLeftRadius: Appearance.rounding.verylarge
            topRightRadius: Appearance.rounding.verylarge
            bottomLeftRadius: Appearance.rounding.normal
            bottomRightRadius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1

            ColumnLayout {
                id: wrapperCol
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Carousel {
                    Layout.fillWidth: true
                    implicitHeight: 280
                    largeItemWidthRatio: 0.5
                    mediumItemWidthRatio: 0.485
                    itemSpacing: 8
                    model: [
                        page.displayPathFor(Config.options.background.wallpaperPath),
                        page.displayPathFor(
                            Config.options.background.lockWall !== ""
                                ? Config.options.background.lockWall
                                : Config.options.background.wallpaperPath
                        )
                    ]
                    wheelEnabled: false
                    dragEnabled: false
                    clickAction: (index, modelData) => {
                        GlobalStates.wallpaperSelectorTarget = index === 1 ? "lockWall" : "wallpaper"
                        GlobalStates.wallpaperSelectorOpen = true
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 24
                        radius: Appearance.rounding.normal
                        color: "transparent"

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            MaterialSymbol {
                                text: "desktop_windows"
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colPrimary
                            }
                            StyledText {
                                text: Translation.tr("Desktop")
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 24
                        radius: Appearance.rounding.normal
                        color: "transparent"

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            MaterialSymbol {
                                text: "lock"
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colPrimary
                            }
                            StyledText {
                                text: Translation.tr("Lockscreen")
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                    }
                }
            }
        }

        GroupedList {
            Layout.topMargin: -2

            ConfigSwitch {
                id: syncWallpaperSwitch
                buttonIcon: "sync"
                text: Translation.tr("Use same wallpaper for both")
                checked: Config.options.background.lockWall === ""
                onCheckedChanged: {
                    if (checked) {
                        Config.options.background.lockWall = "";
                    }
                }
            }

            ConfigSwitch {
                buttonIcon: "preview"
                text: Translation.tr("Preview wallpaper")
                checked: Config.options.background.enableWallpaperPreview
                onCheckedChanged: {
                    Config.options.background.enableWallpaperPreview = checked;
                }
            }

            ConfigComboBox {
                Layout.fillWidth: true
                buttonIcon: "texture"
                text: Translation.tr("Transitions")
                fieldWidth: 50
                model: [
                    { displayName: Translation.tr("None"), icon: "block", value: "" },
                    { displayName: Translation.tr("Circle"), icon: "circle", value: "circleSelect" },
                    { displayName: Translation.tr("Circle Pit"), icon: "blur_circular", value: "circlePit" },
                    { displayName: Translation.tr("Magic"), icon: "auto_awesome", value: "magic" },
                    { displayName: Translation.tr("Doom"), icon: "whatshot", value: "Doom" },
                    { displayName: Translation.tr("Peel"), icon: "layers", value: "Peel" },
                    { displayName: Translation.tr("Fade"), icon: "gradient", value: "transition" },
                    { displayName: Translation.tr("Pixelate"), icon: "grain", value: "pixelate" },
                    { displayName: Translation.tr("Stripes"), icon: "texture_minus", value: "stripes" },
                    { displayName: Translation.tr("Random"), icon: "shuffle", value: "random" },
                ]
                currentValue: Config.options.background.wallpaperAnimation
                onSelected: newValue => {
                    Config.options.background.wallpaperAnimation = newValue;
                }
            }
        }

        Connections {
            target: Config.options.background
            function onLockWallChanged() {
                syncWallpaperSwitch.checked = Qt.binding(() => Config.options.background.lockWall === "")
            }
        }

        ContentSubsection {
            title: Translation.tr("Wallpaper folders")
            Layout.fillWidth: true

            GroupedList {
                ConfigTextArea {
                    id: userPathField
                    Layout.fillWidth: true
                    buttonIcon: "wallpaper"
                    text: Translation.tr("Wallpaper path")
                    placeholderText: Translation.tr("e.g., /home/user/Pictures/wallpapers")
                    fieldWidth: 300
                    value: Config.options.wallpaperSelector.userPath ?? ""
                    confirmButtonVisible: true
                    confirmButtonIcon: "folder_open"
                    onConfirmClicked: Wallpapers.pickFolder("userPath")
                    onValueChanged: userPathDebounceTimer.restart()
                    Timer {
                        id: userPathDebounceTimer
                        interval: 1000
                        onTriggered: Config.options.wallpaperSelector.userPath = userPathField.value
                    }
                }
                ConfigTextArea {
                    id: liveWallpapersPathField
                    Layout.fillWidth: true
                    buttonIcon: "video_template"
                    text: Translation.tr("Live wallpaper path")
                    placeholderText: Translation.tr("e.g., /home/user/Videos/Wallpapers")
                    fieldWidth: 300
                    value: Config.options.wallpaperSelector.liveWallpapersPath ?? ""
                    confirmButtonVisible: true
                    confirmButtonIcon: "folder_open"
                    onConfirmClicked: Wallpapers.pickFolder("liveWallpapersPath")
                    onValueChanged: liveWallpapersPathDebounceTimer.restart()
                    Timer {
                        id: liveWallpapersPathDebounceTimer
                        interval: 1000
                        onTriggered: Config.options.wallpaperSelector.liveWallpapersPath = liveWallpapersPathField.value
                    }
                }
            }

            // Refresh the fields when the folder picker writes the config
            Connections {
                target: Config.options.wallpaperSelector
                function onUserPathChanged() {
                    userPathField.value = Config.options.wallpaperSelector.userPath
                }
                function onLiveWallpapersPathChanged() {
                    liveWallpapersPathField.value = Config.options.wallpaperSelector.liveWallpapersPath
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Centered wallpaper")
            Layout.fillWidth: true

            GroupedList {
                ConfigSwitch {
                    Layout.fillWidth: true
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.background.centeredWallpaper
                    onClicked: {
                        Config.options.background.centeredWallpaper = !Config.options.background.centeredWallpaper;
                    }
                }
                ConfigSwitch {
                    Layout.fillWidth: true
                    buttonIcon: "lock"
                    text: Translation.tr("Show only when locked")
                    checked: Config.options.background.centeredWallpaperOnlyWhenLocked
                    onCheckedChanged: {
                        Config.options.background.centeredWallpaperOnlyWhenLocked = checked;
                    }
                    enabled: Config.options.background.centeredWallpaper
                }
            }

            GroupedList {
                Layout.topMargin: 0
                visible: Config.options.background.centeredWallpaper
                ConfigSelectionShapeArray {
                    currentValue: Config.options.background.centeredWallpaperShape
                    shapeColor: Appearance.colors.colPrimary
                    backgroundColor: Appearance.colors.colPrimaryContainer
                    options: [
                        "Circle", "Square", "Slanted", "Arch", "Arrow", "SemiCircle", "Oval", "Pill",
                        "Triangle", "Diamond", "ClamShell", "Pentagon", "Gem", "Sunny", "VerySunny",
                        "Cookie4Sided", "Cookie6Sided", "Cookie7Sided", "Cookie9Sided", "Cookie12Sided",
                        "Ghostish", "Clover4Leaf", "Clover8Leaf", "Burst", "SoftBurst", "Flower",
                        "Puffy", "PuffyDiamond", "PixelCircle", "Bun", "Heart"
                    ]
                    onSelected: newValue => {
                        Config.options.background.centeredWallpaperShape = newValue
                    }
                }
                ColorSelectionArray {
                    visible: Config.options.background.centeredWallpaper
                    icon: "palette"
                    text: Translation.tr("Background Color")
                    currentValue: Config.options.background.centeredWallpaperColor
                    onSelected: newValue => {
                        Config.options.background.centeredWallpaperColor = newValue
                    }
                }
                ConfigSlider {
                    visible: Config.options.background.centeredWallpaper
                    text: Translation.tr("Size")
                    value: Config.options.background.centeredWallpaperSize
                    usePercentTooltip: false
                    buttonIcon: "aspect_ratio"
                    from: 400
                    to: 800
                    stopIndicatorValues: [400]
                    onValueChanged: {
                        Config.options.background.centeredWallpaperSize = value;
                    }
                }
            }
        }
    }
}
