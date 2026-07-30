import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string provider: "wallhaven"
    property string resolution: "1080p"
    property int columns: Config.options.wallpaperSelector.columns || 4
    property real previewCellAspectRatio: 4 / 3
    property var hoveredItem: null

    signal wallpaperSelected(string path)
    signal updateThumbnailsRequested()

    readonly property bool unsplashMissingKey:
        root.provider === "unsplash" &&
        (KeyringStorage.keyringData?.apiKeys?.unsplash ?? "").length === 0

    readonly property bool pexelsMissingKey:
        root.provider === "pexels" &&
        (KeyringStorage.keyringData?.apiKeys?.pexels ?? "").length === 0
        
    readonly property bool missingKey: root.unsplashMissingKey || root.pexelsMissingKey

    onProviderChanged:   { root.hoveredItem = null; _syncAndFetch() }
    onResolutionChanged: _syncAndFetch()

    function _syncAndFetch() {
        if (root.missingKey) return
        OnlineWallpapers.provider   = root.provider
        OnlineWallpapers.resolution = root.resolution
        OnlineWallpapers.fetch()
    }

    function moveSelection(delta) {
        grid.currentIndex = Math.max(0, Math.min(wallpaperModel.count - 1, grid.currentIndex + delta))
        grid.positionViewAtIndex(grid.currentIndex, GridView.Contain)
    }

    // Applied wallpapers go to the cache (kept while in the last-5 recents);
    // explicit downloads (right-click) go to the local wallpaper collection.
    function download(item, applyAfter) {
        const urlLower = item.full.toLowerCase().split("?")[0]
        const ext = urlLower.includes(".png") ? "png"
            : urlLower.includes(".webp") ? "webp"
            : "jpg"
        const fileName = `${item.provider}-${item.id}.${ext}`
        const dir = applyAfter
            ? Wallpapers.onlineCacheDir
            : `${Directories.pictures.toString().replace("file://", "")}/Wallpapers`
        const fullPath = `${dir}/${fileName}`
        downloadProc.filePath = fullPath
        downloadProc.applyAfter = applyAfter
        downloadProc.command = ["bash", "-c",
            `mkdir -p '${dir}' && curl -L --silent '${item.full}' -o '${fullPath}'`
        ]
        downloadProc.running = true
    }

    function activateCurrent() {
        const item = wallpaperModel.get(grid.currentIndex)
        if (!item) return
        root.download(item, true)
    }

    Component.onCompleted: _syncAndFetch()

    ListModel { id: wallpaperModel }

    Connections {
        target: OnlineWallpapers
        function onFetched() {
            if (!OnlineWallpapers.appending) {
                wallpaperModel.clear()
                root.hoveredItem = null
            }
            const startIndex = wallpaperModel.count
            for (const item of OnlineWallpapers.results.slice(startIndex)) {
                wallpaperModel.append(item)
            }
        }
        function onFetchError(message) {
            console.log("[OnlineWallpaperGrid] Error:", message)
        }
    }

    Process {
        id: downloadProc
        property string filePath: ""
        property bool applyAfter: false

        stdout: SplitParser {
            onRead: data => console.log("[download]", data)
        }

        onExited: (exitCode) => {
            if (exitCode === 0) {
                if (applyAfter) {
                    root.wallpaperSelected(filePath)
                } else {
                    Wallpapers.setDirectory(Wallpapers.effectiveDirectory)
                    Qt.callLater(() => root.updateThumbnailsRequested())
                }
                Quickshell.execDetached(["notify-send",
                    applyAfter ? Translation.tr("Wallpaper applied") : Translation.tr("Download complete"),
                    filePath, "-a", "Shell"
                ])
            } else {
                Quickshell.execDetached(["notify-send",
                    Translation.tr("Download failed"), filePath, "-a", "Shell"
                ])
            }
        }
    }

    // Missing key
    Item {
        anchors.fill: parent
        visible: root.missingKey

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 16

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: "key_off"
                iconSize: 48
                color: Appearance.colors.colOnLayer1
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                text: root.unsplashMissingKey
                    ? Translation.tr("Unsplash API key not set")
                    : Translation.tr("Pexels API key not set")
                font.pixelSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnLayer1
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 12

                MaterialTextField {
                    id: apiKeyField
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 320
                    placeholderText: Translation.tr("Paste your API key here")
                    onAccepted: saveKeyButton.clicked()
                }

                RippleButton {
                    id: saveKeyButton
                    Layout.alignment: Qt.AlignHCenter
                    implicitHeight: 40
                    implicitWidth: Math.max(implicitContentWidth, 96)
                    buttonRadius: height / 2
                    colBackground: Appearance.colors.colPrimary
                    colBackgroundHover: Appearance.colors.colPrimaryHover
                    onClicked: {
                        const key = apiKeyField.text.trim()
                        if (key.length === 0) return
                        KeyringStorage.setNestedField(["apiKeys", root.provider], key)
                        apiKeyField.text = ""
                        Qt.callLater(() => root._syncAndFetch())
                    }
                    contentItem: StyledText {
                        anchors.centerIn: parent
                        leftPadding: 16
                        rightPadding: 16
                        text: Translation.tr("Save & use")
                        color: Appearance.colors.colOnPrimary
                    }
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                text: root.unsplashMissingKey
                    ? Translation.tr("Get your free key at unsplash.com/developers")
                    : Translation.tr("Get your free key at pexels.com/api")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.small
            }
        }
    }

    // Loading
    StyledIndeterminateProgressBar {
        visible: OnlineWallpapers.loading
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            leftMargin: 4
            rightMargin: 4
        }
    }

    // Grid online
    Item {
        id: gridContainer
        anchors.fill: parent
        visible: !root.missingKey

        GridView {
            id: grid
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            visible: wallpaperModel.count > 0

            property int currentIndex: 0

            cellWidth: width / root.columns
            cellHeight: cellWidth / root.previewCellAspectRatio
            interactive: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            model: wallpaperModel

            delegate: Item {
                id: delegateItem
                required property var model
                required property int index

                width: grid.cellWidth
                height: grid.cellHeight

                Image {
                    id: thumb
                    anchors.fill: parent
                    anchors.margins: Appearance.sizes.wallpaperSelectorItemMargins
                    source: delegateItem.model.thumb
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: thumb.width
                            height: thumb.height
                            radius: Appearance.rounding.normal
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Appearance.rounding.normal
                        color: delegateItem.index === grid.currentIndex
                            ? Qt.rgba(
                                Appearance.colors.colPrimary.r,
                                Appearance.colors.colPrimary.g,
                                Appearance.colors.colPrimary.b, 0.35)
                            : "transparent"
                        border.width: delegateItem.index === grid.currentIndex ? 2 : 0
                        border.color: Appearance.colors.colPrimary
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Appearance.rounding.normal
                        color: Appearance.colors.colLayer2
                        visible: thumb.status !== Image.Ready
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "image"
                            iconSize: 32
                            color: Appearance.colors.colSubtext
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onEntered: {
                        grid.currentIndex = delegateItem.index
                        root.hoveredItem = delegateItem.model
                        root.forceActiveFocus()
                    }
                    onClicked: event => {
                        root.download(delegateItem.model, event.button === Qt.LeftButton)
                    }
                }
            }

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: grid.width
                    height: grid.height
                    radius: Appearance.rounding.screenRounding + 5
                }
            }
            onContentYChanged: {
                if (!OnlineWallpapers.loading
                    && contentY + height >= contentHeight - cellHeight * 1.5) {
                    OnlineWallpapers.nextPage()
                }
            }
        }

        // Empty state
        ColumnLayout {
            anchors.centerIn: parent
            visible: wallpaperModel.count === 0 && !OnlineWallpapers.loading
            spacing: 12

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: "cloud_off"
                iconSize: 48
                color: Appearance.colors.colSubtext
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                text: Translation.tr("No results — try fetching again")
                color: Appearance.colors.colSubtext
            }

            RippleButton {
                Layout.alignment: Qt.AlignHCenter
                implicitHeight: 36
                buttonRadius: height / 2
                colBackground: Appearance.colors.colSecondaryContainer
                onClicked: OnlineWallpapers.fetch()
                contentItem: RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    MaterialSymbol {
                        text: "refresh"
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnSecondaryContainer
                    }
                    StyledText {
                        text: Translation.tr("Retry")
                        color: Appearance.colors.colOnSecondaryContainer
                    }
                }
            }
        }
    }
}