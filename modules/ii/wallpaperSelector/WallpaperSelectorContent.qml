import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

MouseArea {
    id: root
    property int columns: Config.options.wallpaperSelector.columns || 4
    property real previewCellAspectRatio: 4 / 3
    property bool useDarkMode: Appearance.m3colors.darkmode
    property string source: "local"
    readonly property bool isLocalSource: root.source === "local" || root.source === "live"
    readonly property bool hasLivePath: Boolean((Config.options.wallpaperSelector.liveWallpapersPath ?? "").trim().length > 0)

    readonly property var providerModel: {
        const list = [
            { value: "local",     displayName: Translation.tr("Local") }
        ];
        if (root.hasLivePath) {
            list.push({ value: "live", displayName: Translation.tr("Local (live)") });
        }
        list.push(
            { value: "wallhaven", displayName: Translation.tr("Wallhaven") },
            { value: "naive",     displayName: Translation.tr("NA-ive") },
            { value: "unsplash",  displayName: Translation.tr("Unsplash") },
            { value: "pexels",    displayName: Translation.tr("Pexels") }
        );
        return list;
    }

    function switchSource(val) {
        root.source = val;
        root.showWallhavenSettings = false;
        if (val === "live") {
            GlobalStates.wallpaperSelectorTarget = "live";
            const livePath = Config.options.wallpaperSelector.liveWallpapersPath;
            Wallpapers.setDirectory((livePath ?? "").trim().length > 0 ? livePath : Wallpapers.defaultFolder);
        } else if (val === "local") {
            GlobalStates.wallpaperSelectorTarget = "wallpaper";
            const userPath = Config.options.wallpaperSelector.userPath;
            Wallpapers.setDirectory((userPath ?? "").trim().length > 0 ? userPath : Wallpapers.defaultFolder);
        }
    }

    onHasLivePathChanged: {
        const idx = root.providerModel.findIndex(m => m.value === root.source);
        if (idx !== -1 && sourceCombo.currentIndex !== idx) {
            sourceCombo.currentIndex = idx;
        }
    }

    property string selectedResolution: "1080p"
    property string selectedColorGroup: ""
    property bool filterFieldFocused: false
    property bool showWallhavenSettings: false

    // Wallhaven palette filter: each swatch maps to a group of hex values (no '#')
    readonly property var wallhavenColorGroups: [
        { hex: "cc0000", name: Translation.tr("Red"),       q: "660000,990000,cc0000,cc3333" },
        { hex: "ff6600", name: Translation.tr("Orange"),    q: "ffcc33,ff9900,ff6600" },
        { hex: "cccc33", name: Translation.tr("Yellow"),    q: "666600,999900,cccc33,ffff00" },
        { hex: "669900", name: Translation.tr("Green"),     q: "77cc33,669900,336600" },
        { hex: "66cccc", name: Translation.tr("Cyan"),      q: "66cccc,0099cc" },
        { hex: "0066cc", name: Translation.tr("Blue"),      q: "0066cc,0099cc,333399" },
        { hex: "663399", name: Translation.tr("Purple"),    q: "ea4c88,993399,663399,333399" },
        { hex: "996633", name: Translation.tr("Brown"),     q: "cc6633,996633,663300" },
        { hex: "999999", name: Translation.tr("Grayscale"), q: "000000,999999,cccccc,ffffff,424153" }
    ]

    readonly property var naiveColorOptions: [
        { value: "",       displayName: Translation.tr("All colors"), color: "transparent", rainbow: true },
        { value: "red",    displayName: Translation.tr("Red"),        color: "#E0483E" },
        { value: "orange", displayName: Translation.tr("Orange"),     color: "#E08A3E" },
        { value: "yellow", displayName: Translation.tr("Yellow"),     color: "#E0C93E" },
        { value: "green",  displayName: Translation.tr("Green"),      color: "#6CBF5C" },
        { value: "blue",   displayName: Translation.tr("Blue"),       color: "#4C7FE0" },
        { value: "purple", displayName: Translation.tr("Purple"),     color: "#8A5CE0" }
    ]
    // Toolbar fields live inside Loaders, so their ids are out of scope here.
    readonly property Item searchField: root.isLocalSource
        ? (localToolbarLoader.item?.searchField ?? null)
        : (onlineToolbarLoader.item?.searchField ?? null)

    function updateThumbnails() {
        const item = gridLoader.item;
        const totalImageMargin = (Appearance.sizes.wallpaperSelectorItemMargins + Appearance.sizes.wallpaperSelectorItemPadding) * 2;
        const cellW = item?.cellWidth ?? (wallpaperGridBackground.width / root.columns);
        const cellH = item?.cellHeight ?? (cellW / root.previewCellAspectRatio);
        const thumbnailSizeName = Images.thumbnailSizeNameForDimensions(cellW - totalImageMargin, cellH - totalImageMargin);
        Qt.callLater(() => Wallpapers.generateThumbnail(thumbnailSizeName));
    }

    function handleFilePasting(event) {
        const currentClipboardEntry = Cliphist.entries[0];
        if (/^\d+\tfile:\/\/\S+/.test(currentClipboardEntry)) {
            const url = StringUtils.cleanCliphistEntry(currentClipboardEntry);
            Wallpapers.setDirectory(FileUtils.trimFileProtocol(decodeURIComponent(url)));
            event.accepted = true;
        } else {
            event.accepted = false;
        }
    }

    function selectWallpaperPath(filePath) {
        if (filePath && filePath.length > 0) {
            if (GlobalStates.wallpaperSelectorTarget === "lockWall") {
                Wallpapers.select(filePath, root.useDarkMode, finalPath => {
                    Config.options.background.lockWall = finalPath;
                    GlobalStates.wallpaperSelectorTarget = "wallpaper";
                    GlobalStates.wallpaperSelectorOpen = false;
                });
            } else {
                // Stop preview FIRST so wallpaperPath reverts to the old wallpaper,
                // then select() sets confirmedPath to the new one — this causes
                // onWallpaperPathChanged to fire with the real transition animation.
                if (Config.options.background.enableWallpaperPreview)
                    Wallpapers.stopPreview();
                Wallpapers.select(filePath, root.useDarkMode);
            }
        }
    }

    acceptedButtons: Qt.BackButton | Qt.ForwardButton
    onPressed: event => {
        if (event.button === Qt.BackButton) {
            Wallpapers.navigateBack();
        } else if (event.button === Qt.ForwardButton) {
            Wallpapers.navigateForward();
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            Wallpapers.stopPreview();
            GlobalStates.wallpaperSelectorOpen = false;
            event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_V) {
            root.handleFilePasting(event);
        } else if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Up) {
            Wallpapers.navigateUp();
            event.accepted = true;
        } else if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Left) {
            Wallpapers.navigateBack();
            event.accepted = true;
        } else if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Right) {
            Wallpapers.navigateForward();
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            if (!root.filterFieldFocused) gridLoader.item?.moveSelection(-1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            if (!root.filterFieldFocused) gridLoader.item?.moveSelection(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            if (!root.filterFieldFocused) gridLoader.item?.moveSelection(-root.columns);
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            if (!root.filterFieldFocused) gridLoader.item?.moveSelection(root.columns);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (!root.filterFieldFocused) gridLoader.item?.activateCurrent();
            event.accepted = true;
        } else if (event.key === Qt.Key_Backspace) {
            if (!root.filterFieldFocused) {
                root.searchField?.forceActiveFocus();
            }
            event.accepted = true;
        } else if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_L) {
            addressBar.focusBreadcrumb();
            event.accepted = true;
        } else if (event.key === Qt.Key_Slash) {
            root.searchField?.forceActiveFocus();
            event.accepted = true;
        } else {
            const searchField = root.searchField;
            if (event.text.length > 0 && !root.filterFieldFocused && searchField) {
                searchField.text += event.text;
                searchField.cursorPosition = searchField.text.length;
                searchField.forceActiveFocus();
            }
            event.accepted = true;
        }
    }

    implicitHeight: mainLayout.implicitHeight
    implicitWidth: mainLayout.implicitWidth

    StyledRectangularShadow {
        target: wallpaperGridBackground
    }
    Rectangle {
        id: wallpaperGridBackground
        anchors {
            fill: parent
            margins: Appearance.sizes.elevationMargin
        }
        focus: true
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        color: Appearance.colors.colLayer0
        radius: Appearance.rounding.screenRounding + 5

        implicitWidth: gridColumnLayout.implicitWidth
        implicitHeight: gridColumnLayout.implicitHeight

        Item {
            anchors { fill: parent; margins: 8 }
            z: 0

            Rectangle {
                anchors.fill: parent
                radius: wallpaperGridBackground.radius - 4
                color: Appearance.colors.colLayer2
                visible: !Config.options.wallpaperSelector.showBlurBackground
            }

            StyledImage {
                id: wallpaperBgImage
                anchors.fill: parent
                visible: Config.options.wallpaperSelector.showBlurBackground
                fillMode: Image.PreserveAspectCrop
                source: Config.options.wallpaperSelector.showBlurBackground ? Config.options.background.wallpaperPath : ""
                // Only shown under a radius 48 blur, so a small decode looks the same
                // and stays small enough for the pixmap cache to keep it between openings
                sourceSize: Qt.size(480, 480)
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: wallpaperGridBackground.width - 16
                        height: wallpaperGridBackground.height - 16
                        radius: wallpaperGridBackground.radius - 4
                    }
                }
            }

            FastBlur {
                anchors.fill: parent
                z: 0
                visible: Config.options.wallpaperSelector.showBlurBackground
                source: wallpaperBgImage
                radius: 48
                layer.enabled: visible
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: wallpaperGridBackground.width - 16
                        height: wallpaperGridBackground.height - 16
                        radius: wallpaperGridBackground.radius - 4
                    }
                }
            }
        }

        RowLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.topMargin: 0
            anchors.bottomMargin: 8
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: -4
            z: 1

            ColumnLayout {
                id: gridColumnLayout
                Layout.fillWidth: true
                Layout.fillHeight: true

                Item {
                    id: topBar
                    Layout.fillWidth: true
                    Layout.margins: 16
                    Layout.leftMargin: 20
                    implicitHeight: 56

                    RowLayout {
                        id: titleRow
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 8

                        MaterialShapeWrappedMaterialSymbol {
                            id: titleIcon
                            wrappedShape: MaterialShape.Shape.Gem
                            text: (GlobalStates.wallpaperSelectorTarget === "live" || root.source === "live") ? "video_library" : "image"
                            iconSize: Appearance.font.pixelSize.larger
                        }

                        // The title text yields its space to a wide wallhaven toolbar;
                        // the icon stays put so the bar never looks empty
                        StyledText {
                            id: titleText
                            visible: topBar.titleAndToolbarFit
                            text: (GlobalStates.wallpaperSelectorTarget === "live" || root.source === "live")
                                ? Translation.tr("Live Wallpaper Selector")
                                : Translation.tr("Wallpaper Selector")
                            font.pixelSize: Appearance.font.pixelSize.large
                        }
                    }

                    // True when the full title, toolbar and source picker all fit side by
                    // side. Uses implicit widths only, so hiding the text can't feed back.
                    readonly property bool titleAndToolbarFit: {
                        const titleW = titleIcon.implicitWidth + 8 + titleText.implicitWidth
                        const needed = titleW + centerToolbar.implicitWidth
                            + sourceControls.implicitWidth + 48
                        return width >= needed
                    }

                    Toolbar {
                        id: centerToolbar
                        // Size to content, centered in the gap between title and source picker
                        anchors.verticalCenter: parent.verticalCenter
                        x: {
                            const left = titleRow.x + titleRow.width + 16
                            const right = sourceControls.x - 12
                            const avail = right - left
                            if (avail <= 0) return left
                            return left + Math.max(0, (avail - width) / 2)
                        }

                        Loader {
                            id: localToolbarLoader
                            active: root.isLocalSource
                            visible: active
                            sourceComponent: RowLayout {
                                property alias searchField: filterField
                                spacing: 4
                                IconToolbarButton {
                                    implicitWidth: height
                                    onClicked: Wallpapers.randomFromCurrentFolder()
                                    text: "ifl"
                                }
                                IconToolbarButton {
                                    implicitWidth: height
                                    onClicked: root.useDarkMode = !root.useDarkMode
                                    text: root.useDarkMode ? "dark_mode" : "light_mode"
                                }
                                IconToolbarButton {
                                    implicitWidth: height
                                    onClicked: root.updateThumbnails()
                                    text: "reset_image"
                                }
                                ToolbarTextField {
                                    id: filterField
                                    placeholderText: Translation.tr("Search wallpapers")
                                    clip: true
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    onTextChanged: Wallpapers.searchQuery = text
                                    onActiveFocusChanged: root.filterFieldFocused = activeFocus
                                    Keys.onPressed: event => {
                                        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_V) {
                                            root.handleFilePasting(event);
                                            event.accepted = true;
                                            return;
                                        }
                                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                            event.accepted = true;
                                            return;
                                        }
                                        if (text.length !== 0) {
                                            if (event.key === Qt.Key_Down) { event.accepted = true; return; }
                                            if (event.key === Qt.Key_Up)   { event.accepted = true; return; }
                                        }
                                        event.accepted = false;
                                    }
                                }
                            }
                        }

                        Loader {
                            id: onlineToolbarLoader
                            active: !root.isLocalSource
                            visible: active
                            sourceComponent: RowLayout {
                                property alias searchField: onlineSearchField
                                spacing: 4
                                Repeater {
                                    model: ["1080p", "2K", "4K"]
                                    delegate: RippleButton {
                                        required property string modelData
                                        visible: root.source !== "naive"
                                        implicitHeight: 38
                                        buttonRadius: height / 2
                                        toggled: root.selectedResolution === modelData
                                        colBackgroundToggled: Appearance.colors.colSecondaryContainer
                                        colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                                        colRippleToggled: Appearance.colors.colSecondaryContainerActive
                                        onClicked: root.selectedResolution = modelData
                                        contentItem: StyledText {
                                            anchors.centerIn: parent
                                            text: modelData
                                            color: parent.toggled
                                                ? Appearance.colors.colOnSecondaryContainer
                                                : Appearance.colors.colOnLayer2
                                        }
                                    }
                                }
                                Loader {
                                    active: root.source === "naive" || root.source === "wallhaven"
                                    visible: active
                                    sourceComponent: CustomColorSelectionArray {
                                        // Wallhaven's 10 swatches don't fit at the default swatch size
                                        swatchSize: root.source === "wallhaven" ? 26 : 40
                                        spacing: root.source === "wallhaven" ? 6 : 10
                                        currentValue: root.source === "wallhaven"
                                            ? OnlineWallpapers.wallhavenColors
                                            : root.selectedColorGroup
                                        options: root.source === "wallhaven"
                                            ? [{ value: "", displayName: Translation.tr("All colors"), color: "transparent", rainbow: true }]
                                                .concat(root.wallhavenColorGroups.map(g => ({ value: g.q, displayName: g.name, color: "#" + g.hex })))
                                            : root.naiveColorOptions
                                        onSelected: newValue => {
                                            if (root.source === "wallhaven") {
                                                // setWallhavenColor toggles: picking the active color clears it.
                                                // Skip only the no-op "All colors" while already clear.
                                                if (newValue === "" && OnlineWallpapers.wallhavenColors === "") return
                                                OnlineWallpapers.setWallhavenColor(newValue)
                                            } else {
                                                root.selectedColorGroup = newValue
                                            }
                                        }
                                    }
                                }
                                IconToolbarButton {
                                    visible: root.source === "wallhaven"
                                    implicitWidth: height
                                    text: "tune"
                                    toggled: root.showWallhavenSettings
                                    onClicked: root.showWallhavenSettings = !root.showWallhavenSettings
                                    StyledToolTip {
                                        text: Translation.tr("Wallhaven search settings")
                                    }
                                }
                                ToolbarTextField {
                                    id: onlineSearchField
                                    placeholderText: Translation.tr("Search online wallpapers")
                                    clip: true
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    property bool _ready: false
                                    Component.onCompleted: Qt.callLater(() => onlineSearchField._ready = true)
                                    onTextChanged: {
                                        if (_ready) {
                                            OnlineWallpapers.query = text
                                            searchDebounce.restart()
                                        }
                                    }
                                    onAccepted: {
                                        searchDebounce.stop()
                                        OnlineWallpapers.fetch()
                                    }
                                    onActiveFocusChanged: root.filterFieldFocused = activeFocus
                                    Keys.onPressed: event => {
                                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                            event.accepted = true
                                            return
                                        }
                                        event.accepted = false
                                    }
                                    Timer {
                                        id: searchDebounce
                                        interval: 500
                                        onTriggered: OnlineWallpapers.fetch()
                                    }
                                }
                                IconToolbarButton {
                                    implicitWidth: height
                                    text: "refresh"
                                    onClicked: OnlineWallpapers.fetch()
                                }
                            }
                        }
                    }

                    RowLayout {
                        id: sourceControls
                        anchors {
                            right: parent.right
                            rightMargin: 8
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 6

                        StyledComboBox {
                            id: sourceCombo
                            implicitWidth: 140
                            model: root.providerModel
                            textRole: "displayName"
                            onActivated: index => {
                                const item = model[index];
                                if (item) {
                                    root.switchSource(item.value);
                                }
                                root.forceActiveFocus();
                            }
                        }

                        RippleButton {
                            implicitWidth: 36
                            implicitHeight: 36
                            buttonRadius: height / 2
                            colBackground: Appearance.colors.colSecondaryContainer
                            onClicked: {
                                Wallpapers.stopPreview();
                                GlobalStates.wallpaperSelectorOpen = false;
                            }
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "close"
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colOnSecondaryContainer
                            }
                        }
                    }
                }

                Item {
                    id: gridDisplayRegion
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // Settings popup anchors inside the grid region so it dims the grid, not the whole shell
                    Loader {
                        id: wallhavenSettingsLoader
                        anchors.fill: parent
                        z: 100
                        active: root.showWallhavenSettings
                        onLoaded: {
                            item.show = true
                            item.forceActiveFocus()
                        }
                        sourceComponent: WallhavenSettingsPopup {
                            onDismiss: {
                                root.showWallhavenSettings = false
                                if (dirty) {
                                    OnlineWallpapers.saveWallhavenConfig()
                                    OnlineWallpapers.fetch()
                                }
                            }
                        }
                    }

                    Loader {
                        id: gridLoader
                        anchors.fill: parent
                        sourceComponent: root.isLocalSource ? localGridComponent : onlineGridComponent
                    }

                    Component {
                        id: localGridComponent
                        LocalWallpaperGrid {
                            columns: root.columns
                            previewCellAspectRatio: root.previewCellAspectRatio
                            onWallpaperSelected: path => root.selectWallpaperPath(path)
                        }
                    }

                    Component {
                        id: onlineGridComponent
                        OnlineWallpaperGrid {
                            provider: root.source
                            resolution: root.selectedResolution
                            colorGroup: root.selectedColorGroup
                            onWallpaperSelected: path => root.selectWallpaperPath(path)
                            onUpdateThumbnailsRequested: root.updateThumbnails()
                        }
                    }

                }
            }
        }
    }

    Connections {
        target: GlobalStates
        function onWallpaperSelectorOpenChanged() {
            if (GlobalStates.wallpaperSelectorOpen) {
                const targetVal = GlobalStates.wallpaperSelectorTarget === "live" ? "live" : "local";
                const targetIdx = root.providerModel.findIndex(m => m.value === targetVal);
                if (targetIdx !== -1) {
                    sourceCombo.currentIndex = targetIdx;
                    root.source = targetVal;
                } else {
                    sourceCombo.currentIndex = 0;
                    root.source = "local";
                }
                if (monitorIsFocused) {
                    if (root.isLocalSource)
                        root.searchField?.forceActiveFocus();
                    else
                        root.forceActiveFocus();
                }
            } else {
                Wallpapers.stopPreview();
                GlobalStates.wallpaperSelectorTarget = "wallpaper";
                root.showWallhavenSettings = false;
                root.source = "local";
                sourceCombo.currentIndex = 0;
            }
        }
    }

    Connections {
        target: Wallpapers
        function onChanged() {
            GlobalStates.wallpaperSelectorOpen = false;
        }
    }
}