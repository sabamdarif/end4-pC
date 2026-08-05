pragma ComponentBehavior: Bound

import Qt.labs.synchronizer
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models
import qs.modules.common.functions

Item { // Wrapper
    id: root

    readonly property int gridColumns: 5
    readonly property int tileSize: 116
    readonly property int tileHeight: 126
    readonly property int iconSize: 40

    property string searchingText: LauncherSearch.query
    property bool showResults: searchingText != ""
    property string activeCategory: "All"

    readonly property var categories: ["All", "Work", "Social", "Tools", "Media", "System"]

    readonly property var organicShapes: [
        MaterialShape.Shape.Gem,
        MaterialShape.Shape.Cookie4Sided,
        MaterialShape.Shape.Sunny,
        MaterialShape.Shape.Cookie7Sided,
        MaterialShape.Shape.Clover4Leaf,
        MaterialShape.Shape.Triangle,
        MaterialShape.Shape.Square,
        MaterialShape.Shape.Slanted,
        MaterialShape.Shape.Arch,
        MaterialShape.Shape.Puffy,
        MaterialShape.Shape.PuffyDiamond,
        MaterialShape.Shape.Bun,
        MaterialShape.Shape.SoftBurst
    ]

    readonly property var shapeColors: [
        Appearance.colors.colPrimaryContainer,
        Appearance.colors.colSecondaryContainer,
        Appearance.colors.colTertiaryContainer,
        Appearance.colors.colSurfaceContainerHigh,
        Appearance.colors.colSurfaceContainerHighest
    ]

    function matchesCategory(entry, cat) {
        if (cat === "All") return true;
        const text = (entry.name + " " + (entry.id ?? "") + " " + (entry.comment ?? "")).toLowerCase();
        if (cat === "Work") {
            return text.match(/office|word|writer|calc|sheet|presentation|slide|code|dev|editor|project|kate|nvim|emacs|idea|studio|work|pdf/) !== null;
        } else if (cat === "Social") {
            return text.match(/network|chat|message|messenger|social|discord|telegram|slack|signal|element|matrix|email|mail|thunderbird|social|browser|firefox|chrome|zen|vesktop|web/) !== null;
        } else if (cat === "Tools") {
            return text.match(/utility|tool|calc|clock|counter|convert|archiv|terminal|foot|kitty|alacritty|wezterm|ghostty|hread|gnome-calculator|st/) !== null;
        } else if (cat === "Media") {
            return text.match(/audio|video|music|player|mpv|vlc|spotify|cider|rhythmbox|gimp|inkscape|blender|draw|photo|gallery|media|obs|camera|feh|imv/) !== null;
        } else if (cat === "System") {
            return text.match(/system|setting|config|control|manager|file|nemo|nautilus|thunar|dolphin|htop|btop|gparted|btrfs|store|discover/) !== null;
        }
        return true;
    }

    function getShapeForApp(index, name) {
        let codeSum = 0;
        for (let i = 0; i < name.length; i++) {
            codeSum += name.charCodeAt(i);
        }
        return organicShapes[(index + codeSum) % organicShapes.length];
    }

    function getColorForApp(index, name) {
        let codeSum = 0;
        for (let i = 0; i < name.length; i++) {
            codeSum += name.charCodeAt(i);
        }
        return shapeColors[(index + codeSum) % shapeColors.length];
    }

    property var items: {
        if (root.showResults)
            return LauncherSearch.results ?? [];
        return AppSearch.list
            .slice()
            .filter(entry => root.matchesCategory(entry, root.activeCategory))
            .sort((a, b) => a.name.localeCompare(b.name))
            .map(entry => ({
                name: entry.name,
                iconName: entry.icon,
                iconType: LauncherSearchResult.IconType.System,
                execute: () => {
                    if (!entry.runInTerminal)
                        entry.execute();
                    else
                        Quickshell.execDetached(["bash", "-c", `${Config.options.apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(entry.command.join(' '))}'`]);
                }
            }));
    }

    implicitWidth: root.tileSize * root.gridColumns + Appearance.sizes.elevationMargin * 2 + 40
    implicitHeight: Math.min(620, Math.max(380, Screen.height * 0.68)) + Appearance.sizes.elevationMargin * 2

    function focusFirstItem() {
        grid.currentIndex = 0;
    }

    function focusSearchInput() {
        searchBar.forceFocus();
    }

    function disableExpandAnimation() {}

    function cancelSearch() {
        searchBar.searchInput.text = "";
        LauncherSearch.query = "";
        root.activeCategory = "All";
    }

    function setSearchingText(text) {
        searchBar.searchInput.text = text;
        LauncherSearch.query = text;
    }

    function launch(item) {
        if (!item?.execute)
            return;
        GlobalStates.overviewOpen = false;
        item.execute();
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape)
            return;

        if (event.key === Qt.Key_Backspace) {
            if (!searchBar.searchInput.activeFocus) {
                root.focusSearchInput();
                let ti = searchBar.searchInput;
                if (ti.cursorPosition > 0) {
                    ti.text = ti.text.slice(0, ti.cursorPosition - 1) + ti.text.slice(ti.cursorPosition);
                }
                ti.cursorPosition = ti.text.length;
                event.accepted = true;
            }
            return;
        }

        if (event.text && event.text.length === 1 && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Return && event.key !== Qt.Key_Delete && event.text.charCodeAt(0) >= 0x20) {
            if (!searchBar.searchInput.activeFocus) {
                root.focusSearchInput();
                searchBar.searchInput.text += event.text;
                searchBar.searchInput.cursorPosition = searchBar.searchInput.text.length;
                event.accepted = true;
            }
        }
    }

    StyledRectangularShadow {
        target: searchWidgetContent
    }

    Rectangle { // Main Glassmorphic Container
        id: searchWidgetContent
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: Appearance.sizes.elevationMargin
        }
        clip: true
        implicitWidth: root.implicitWidth - Appearance.sizes.elevationMargin * 2
        implicitHeight: root.implicitHeight - Appearance.sizes.elevationMargin * 2
        radius: 30
        color: Appearance.colors.colBackgroundSurfaceContainer
        border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.72)
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            SearchBar {
                id: searchBar
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter

                Synchronizer on searchingText {
                    property alias source: root.searchingText
                }

                onSubmitted: root.launch(root.items[Math.max(0, grid.currentIndex)])

                Component.onCompleted: {
                    searchInput.Keys.downPressed.connect(() => {
                        grid.forceActiveFocus();
                        grid.currentIndex = 0;
                    });
                }
            }

            // Category Filter Pills Bar
            RowLayout {
                id: categoriesRow
                Layout.alignment: Qt.AlignHCenter
                visible: !root.showResults
                spacing: 10

                Repeater {
                    model: root.categories

                    delegate: RippleButton {
                        id: catBtn
                        required property string modelData
                        readonly property bool isActive: root.activeCategory === modelData

                        buttonRadius: 18
                        padding: 0
                        leftPadding: 16
                        rightPadding: 16
                        topPadding: 0
                        bottomPadding: 0
                        implicitHeight: 36

                        scale: catBtn.down ? 0.88 : (catBtn.hovered ? 1.05 : 1.0)
                        Behavior on scale {
                            NumberAnimation {
                                duration: catBtn.down ? 90 : 250
                                easing.type: catBtn.down ? Easing.OutCubic : Easing.OutBack
                                easing.overshoot: 1.4
                            }
                        }

                        colBackground: isActive ? Appearance.colors.colPrimary : Appearance.colors.colLayer1
                        colBackgroundHover: isActive ? Appearance.colors.colPrimaryHover : Appearance.colors.colLayer2
                        colRipple: Appearance.colors.colPrimaryContainer

                        onClicked: root.activeCategory = modelData

                        contentItem: StyledText {
                            text: catBtn.modelData
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: catBtn.isActive ? Font.Bold : Font.Normal
                            color: catBtn.isActive ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurface
                        }
                    }
                }
            }

            // App Grid with Organic Shapes
            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: Math.floor(width / root.gridColumns)
                cellHeight: root.tileHeight
                model: root.items
                currentIndex: 0
                highlightMoveDuration: 120
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: StyledScrollBar {}

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.launch(root.items[grid.currentIndex]);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up && grid.currentIndex < root.gridColumns) {
                        root.focusSearchInput();
                        event.accepted = true;
                    }
                }

                delegate: Item {
                    id: tileWrap
                    required property int index
                    required property var modelData
                    width: grid.cellWidth
                    height: grid.cellHeight
                    readonly property bool selected: tileMouse.containsMouse || (GridView.isCurrentItem && grid.activeFocus)
                    readonly property var shapeType: root.getShapeForApp(index, modelData.name)
                    readonly property color shapeColor: root.getColorForApp(index, modelData.name)

                    MouseArea {
                        id: tileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.launch(tileWrap.modelData)
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 8

                        // Organic Material Shape Frame
                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 66
                            implicitHeight: 66
                            scale: tileMouse.pressed ? 0.85 : (tileWrap.selected ? 1.08 : 1.0)

                            Behavior on scale {
                                NumberAnimation {
                                    duration: tileMouse.pressed ? 90 : 280
                                    easing.type: tileMouse.pressed ? Easing.OutCubic : Easing.OutBack
                                    easing.overshoot: 1.5
                                }
                            }

                            MaterialShape {
                                id: shapeCanvas
                                anchors.fill: parent
                                shape: tileWrap.shapeType
                                color: tileWrap.selected ? Appearance.colors.colPrimaryContainerHover : tileWrap.shapeColor
                                borderWidth: 0

                                Behavior on color {
                                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                }
                            }

                            // App Icon
                            Loader {
                                anchors.centerIn: parent
                                sourceComponent: tileWrap.modelData.iconType === LauncherSearchResult.IconType.Material
                                    ? materialIcon
                                    : (tileWrap.modelData.iconType === LauncherSearchResult.IconType.Text ? textIcon : systemIcon)

                                Component {
                                    id: systemIcon
                                    IconImage {
                                        implicitSize: root.iconSize
                                        source: Quickshell.iconPath(tileWrap.modelData.iconName, "image-missing")
                                    }
                                }
                                Component {
                                    id: materialIcon
                                    MaterialSymbol {
                                        iconSize: root.iconSize
                                        text: tileWrap.modelData.iconName
                                        color: tileWrap.selected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSurface
                                    }
                                }
                                Component {
                                    id: textIcon
                                    StyledText {
                                        font.pixelSize: root.iconSize
                                        text: tileWrap.modelData.iconName
                                        color: tileWrap.selected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSurface
                                    }
                                }
                            }
                        }

                        // App Label Text
                        StyledText {
                            Layout.fillWidth: true
                            Layout.leftMargin: 2
                            Layout.rightMargin: 2
                            horizontalAlignment: Text.AlignHCenter
                            maximumLineCount: 1
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: tileWrap.selected ? Font.Bold : Font.Normal
                            color: tileWrap.selected ? Appearance.colors.colPrimary : Appearance.colors.colOnSurface
                            text: tileWrap.modelData.name

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



