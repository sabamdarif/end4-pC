pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Scope {
    id: root

    function openCentered(shouldOpen) {
        if (!shouldOpen) {
            GlobalStates.desktopMenuOpen = false
            return
        }
        const focusedName = Hyprland.focusedMonitor?.name
        const screen = Quickshell.screens.find(s => s.name === focusedName) ?? Quickshell.screens[0]
        GlobalStates.desktopMenuScreen = screen
        GlobalStates.desktopMenuX = screen.width / 2
        GlobalStates.desktopMenuY = screen.height / 2
        GlobalStates.desktopMenuOpen = true
    }

    function displayPathFor(path) {
        if (!path) return path
        // Videos are displayed via the thumbnail switchwall.sh keeps per file
        return /\.(mp4|webm|mkv|avi|mov)$/i.test(path)
            ? `${FileUtils.trimFileProtocol(Directories.config)}/hypr/custom/scripts/mpvpaper_thumbnails/${path.split("/").pop()}.jpg`
            : path
    }

    property bool useDarkMode: Appearance.m3colors.darkmode
    // Last 5 used wallpapers, current one first
    property var recentWallpapers: {
        const recents = Config.options.background.recentWallpapers
        if (recents.length > 0) return recents.map(p => FileUtils.trimFileProtocol(p))
        const current = FileUtils.trimFileProtocol(Config.options.background.wallpaperPath)
        return current && current.length > 0 ? [current] : []
    }
    property var carouselModel: recentWallpapers.map(p => root.displayPathFor(p))

    // Folder picker for the wallpaper/live wallpaper path selection
    Process {
        id: folderPickProc
        property string targetKey: "userPath"
        function pick(key) {
            folderPickProc.targetKey = key
            folderPickProc.exec(["yad", "--file", "--directory", "--title", "Choose wallpaper folder", `--filename=${FileUtils.trimFileProtocol(Directories.home)}/`])
        }
        stdout: StdioCollector {
            onStreamFinished: {
                const dir = text.trim()
                if (dir.length === 0) return
                if (folderPickProc.targetKey === "liveWallpapersPath")
                    Config.options.wallpaperSelector.liveWallpapersPath = dir
                else
                    Config.options.wallpaperSelector.userPath = dir
            }
        }
    }

    // Menu window
    Loader {
        active: GlobalStates.desktopMenuOpen
        sourceComponent: PanelWindow {
            id: menuWindow

            screen: GlobalStates.desktopMenuScreen ?? Quickshell.screens[0]

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:desktopMenu"
            WlrLayershell.layer: WlrLayer.Overlay

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            property Component openSubmenuComponent: null
            property real submenuAnchorY: 0
            property real submenuWidth: 284

            Timer {
                id: submenuCloseTimer
                interval: 250
                onTriggered: menuWindow.openSubmenuComponent = null
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: GlobalStates.desktopMenuOpen = false
            }

            // Menu card 
            Rectangle {
                id: menuCard
                width: 348
                implicitHeight: menuCol.implicitHeight + 16
                x: Math.min(Math.max(GlobalStates.desktopMenuX - width / 2, 8), menuWindow.width - width - 8)
                y: Math.min(Math.max(GlobalStates.desktopMenuY - implicitHeight / 2, 8), menuWindow.height - implicitHeight - 8)
                radius: Appearance.rounding.verylarge
                color: "transparent"

                scale: 0.85
                opacity: 0
                transformOrigin: Item.Center

                Component.onCompleted: {
                    scale = 1.0
                    opacity = 1.0
                }

                Behavior on scale {
                    animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
                }
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                }

                ColumnLayout {
                    id: menuCol
                    anchors { fill: parent; margins: 8 }
                    spacing: 4

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 160
                        radius: Appearance.rounding.verylarge
                        color: Appearance.colors.colLayer0
                        clip: true

                        Carousel {
                            anchors.fill: parent
                            anchors.margins: 10
                            model: root.carouselModel
                            // Apply the real path (videos display as thumbnails), by index
                            clickAction: (index, modelData) => {
                                const real = root.recentWallpapers[index]
                                if (!real) return
                                Wallpapers.select(real, Appearance.m3colors.darkmode)
                                GlobalStates.desktopMenuOpen = false
                            }
                        }
                    }

                    GroupedList {
                        Layout.fillWidth: true
                        itemVerticalPadding: 16
                        bgcolor: Appearance.colors.colLayer0

                        // Wallpapers
                        RippleButton {
                            id: wallpaperRow
                            implicitHeight: 40
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colLayer2
                            contentItem: RowLayout {
                                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                spacing: 12
                                MaterialSymbol { text: "format_paint"; iconSize: Appearance.font.pixelSize.larger; color: Appearance.colors.colOnLayer1 }
                                StyledText { Layout.fillWidth: true; text: "Wallpaper & style"; font.pixelSize: Appearance.font.pixelSize.normal; color: Appearance.colors.colOnLayer1 }
                                MaterialSymbol { text: "chevron_right"; iconSize: Appearance.font.pixelSize.normal; color: Appearance.colors.colOnLayer1; opacity: 0.4 }
                            }
                            Component {
                                id: wallpaperSubmenu
                                WallpaperSubmenu {}
                            }
                            HoverHandler {
                                onHoveredChanged: {
                                    if (hovered) {
                                        submenuCloseTimer.stop()
                                        menuWindow.submenuAnchorY = menuCard.y + wallpaperRow.mapToItem(menuCard, 0, 0).y
                                        menuWindow.openSubmenuComponent = wallpaperSubmenu
                                    } else {
                                        submenuCloseTimer.restart()
                                    }
                                }
                            }
                            onClicked: GlobalStates.desktopMenuOpen = false
                        }

                        // Change wallpaper (or select the wallpaper folder first)
                        RippleButton {
                            id: changeWallpaperRow
                            property bool hasPath: (Config.options.wallpaperSelector.userPath ?? "").trim().length > 0
                            implicitHeight: 40
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colLayer2
                            contentItem: RowLayout {
                                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                spacing: 12
                                MaterialSymbol { text: "wallpaper"; iconSize: Appearance.font.pixelSize.larger; color: Appearance.colors.colOnLayer1 }
                                StyledText { Layout.fillWidth: true; text: changeWallpaperRow.hasPath ? "Change wallpaper" : "Select wallpaper path"; font.pixelSize: Appearance.font.pixelSize.normal; color: Appearance.colors.colOnLayer1 }
                            }
                            onClicked: {
                                GlobalStates.desktopMenuOpen = false
                                if (!hasPath) {
                                    folderPickProc.pick("userPath")
                                    return
                                }
                                Wallpapers.setDirectory(Config.options.wallpaperSelector.userPath)
                                GlobalStates.wallpaperSelectorTarget = "wallpaper"
                                GlobalStates.wallpaperSelectorOpen = true
                            }
                        }

                        // Widgets
                        RippleButton {
                            id: widgetsRow
                            implicitHeight: 40
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colLayer2
                            contentItem: RowLayout {
                                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                spacing: 12
                                MaterialSymbol { text: "widgets"; iconSize: Appearance.font.pixelSize.larger; color: Appearance.colors.colOnLayer1 }
                                StyledText { Layout.fillWidth: true; text: "Widgets"; font.pixelSize: Appearance.font.pixelSize.normal; color: Appearance.colors.colOnLayer1 }
                                MaterialSymbol { text: "chevron_right"; iconSize: Appearance.font.pixelSize.normal; color: Appearance.colors.colOnLayer1; opacity: 0.4 }
                            }

                            Component {
                                id: widgetsSubmenu
                                WidgetsSubmenu {}
                            }

                            HoverHandler {
                                onHoveredChanged: {
                                    if (hovered) {
                                        submenuCloseTimer.stop()
                                        menuWindow.submenuAnchorY = menuCard.y + widgetsRow.mapToItem(menuCard, 0, 0).y
                                        menuWindow.openSubmenuComponent = widgetsSubmenu
                                    } else {
                                        submenuCloseTimer.restart()
                                    }
                                }
                            }
                        }

                        RippleButton {
                            implicitHeight: 40
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colLayer2
                            contentItem: RowLayout {
                                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                spacing: 12
                                MaterialSymbol { text: "stacks"; iconSize: Appearance.font.pixelSize.larger; color: Appearance.colors.colOnLayer1 }
                                StyledText { Layout.fillWidth: true; text: "DropShelf"; font.pixelSize: Appearance.font.pixelSize.normal; color: Appearance.colors.colOnLayer1 }
                                StyledText {
                                    visible: DropShelf.items.length > 0
                                    text: DropShelf.items.length
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colOnLayer1
                                    opacity: 0.6
                                }
                                MaterialSymbol {
                                    visible: DropShelf.items.length === 0
                                    text: "chevron_right"
                                    iconSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnLayer1
                                    opacity: 0.4
                                }
                            }
                            onClicked: {
                                GlobalStates.desktopMenuOpen = false
                                GlobalStates.dropShelfX = GlobalStates.desktopMenuX
                                GlobalStates.dropShelfY = GlobalStates.desktopMenuY
                                GlobalStates.dropShelfOpen = true
                            }
                        }

                        RippleButton {
                            id: liveWallpaperRow
                            property bool hasPath: (Config.options.wallpaperSelector.liveWallpapersPath ?? "").trim().length > 0
                            implicitHeight: 40
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colLayer2
                            contentItem: RowLayout {
                                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                spacing: 12
                                MaterialSymbol { text: "video_template"; iconSize: Appearance.font.pixelSize.larger; color: Appearance.colors.colOnLayer1 }
                                StyledText { Layout.fillWidth: true; text: liveWallpaperRow.hasPath ? "Live Wallpaper" : "Select live wallpaper path"; font.pixelSize: Appearance.font.pixelSize.normal; color: Appearance.colors.colOnLayer1 }
                            }
                            onClicked: {
                                GlobalStates.desktopMenuOpen = false
                                if (!hasPath) {
                                    folderPickProc.pick("liveWallpapersPath")
                                    return
                                }
                                GlobalStates.wallpaperSelectorTarget = "live"
                                Wallpapers.setDirectory(Config.options.wallpaperSelector.liveWallpapersPath)
                                GlobalStates.wallpaperSelectorOpen = true
                            }
                        }

                        RippleButton {
                            implicitHeight: 40
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colLayer2
                            contentItem: RowLayout {
                                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                spacing: 12
                                MaterialSymbol { text: "settings"; iconSize: Appearance.font.pixelSize.larger; color: Appearance.colors.colOnLayer1 }
                                StyledText { Layout.fillWidth: true; text: "Settings"; font.pixelSize: Appearance.font.pixelSize.normal; color: Appearance.colors.colOnLayer1 }
                            }
                            onClicked: {
                                GlobalStates.desktopMenuOpen = false
                                GlobalStates.settingsOpen = true
                                Qt.callLater(() => GlobalStates.settingsPage = "Desktop")
                            }
                        }
                    }
                }
            }

            // SubMenu
            Loader {
                id: submenuLoader
                active: menuWindow.openSubmenuComponent !== null
                width: menuWindow.submenuWidth
                sourceComponent: menuWindow.openSubmenuComponent

                x: (menuCard.x + menuCard.width + 8 + menuWindow.submenuWidth > menuWindow.width)
                    ? menuCard.x - menuWindow.submenuWidth - 8
                    : menuCard.x + menuCard.width + 8

                y: Math.min(
                    Math.max(menuWindow.submenuAnchorY, 8),
                    menuWindow.height - (item?.implicitHeight ?? 0) - 8
                )

                scale: active ? 1.0 : 0.9
                opacity: active ? 1.0 : 0.0
                transformOrigin: Item.Center

                Behavior on scale {
                    animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
                }
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                HoverHandler {
                    onHoveredChanged: {
                        if (hovered) submenuCloseTimer.stop()
                        else submenuCloseTimer.restart()
                    }
                }
            }
        }
    }
}