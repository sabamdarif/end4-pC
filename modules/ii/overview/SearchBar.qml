pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Rectangle {
    id: root
    implicitHeight: 60
    implicitWidth: 520
    radius: 30
    color: Appearance.colors.colSurfaceContainerHigh
    border.color: searchInput.activeFocus ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colOutline, 0.65)
    border.width: searchInput.activeFocus ? 2 : 1

    Behavior on border.color {
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }

    property bool animateWidth: false
    property alias searchInput: searchInput
    property string searchingText
    signal submitted

    function forceFocus() {
        searchInput.forceActiveFocus();
    }

    enum SearchPrefixType { Action, App, Emojis, Symbols, Math, ShellCommand, WebSearch, Keybinds, DefaultSearch }

    property var searchPrefixType: {
        if (root.searchingText.startsWith(Config.options.search.prefix.action)) return SearchBar.SearchPrefixType.Action;
        if (root.searchingText.startsWith(Config.options.search.prefix.app)) return SearchBar.SearchPrefixType.App;
        if (root.searchingText.startsWith(Config.options.search.prefix.emojis)) return SearchBar.SearchPrefixType.Emojis;
        if (root.searchingText.startsWith(Config.options.search.prefix.symbols)) return SearchBar.SearchPrefixType.Symbols;
        if (root.searchingText.startsWith(Config.options.search.prefix.math)) return SearchBar.SearchPrefixType.Math;
        if (root.searchingText.startsWith(Config.options.search.prefix.shellCommand)) return SearchBar.SearchPrefixType.ShellCommand;
        if (root.searchingText.startsWith(Config.options.search.prefix.webSearch)) return SearchBar.SearchPrefixType.WebSearch;
        if (root.searchingText.startsWith(Config.options.search.prefix.keybinds ?? "<")) return SearchBar.SearchPrefixType.Keybinds;
        return SearchBar.SearchPrefixType.DefaultSearch;
    }

    function getPrefixIcon(text, prefixType) {
        if (text === "") return "center_focus_weak";
        switch (prefixType) {
            case SearchBar.SearchPrefixType.Action: return "settings_suggest";
            case SearchBar.SearchPrefixType.App: return "apps";
            case SearchBar.SearchPrefixType.Emojis: return "add_reaction";
            case SearchBar.SearchPrefixType.Symbols: return "interests";
            case SearchBar.SearchPrefixType.Math: return "calculate";
            case SearchBar.SearchPrefixType.ShellCommand: return "terminal";
            case SearchBar.SearchPrefixType.WebSearch: return "travel_explore";
            default: return "center_focus_weak";
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        // Left Lens / Search Action Button
        RippleButton {
            id: lensBtn
            Layout.preferredWidth: 44
            Layout.preferredHeight: 44
            Layout.alignment: Qt.AlignVCenter
            buttonRadius: 22
            colBackground: Appearance.colors.colSecondaryContainer
            colBackgroundHover: Appearance.colors.colPrimaryContainer
            colRipple: Appearance.colors.colPrimaryContainer

            scale: lensBtn.down ? 0.85 : (lensBtn.hovered ? 1.08 : 1.0)
            Behavior on scale {
                NumberAnimation {
                    duration: lensBtn.down ? 90 : 250
                    easing.type: lensBtn.down ? Easing.OutCubic : Easing.OutBack
                    easing.overshoot: 1.4
                }
            }

            onClicked: {
                GlobalStates.overviewOpen = false;
                Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "search"]);
            }

            contentItem: MaterialShapeWrappedMaterialSymbol {
                anchors.centerIn: parent
                iconSize: 22
                shape: MaterialShape.Shape.Cookie4Sided
                color: Appearance.colors.colSecondaryContainer
                colSymbol: Appearance.colors.colOnSecondaryContainer
                text: root.getPrefixIcon(root.searchingText, root.searchPrefixType)
            }

            StyledToolTip {
                text: Translation.tr("Google Lens / Region Search")
            }
        }

        // Central Search Text Input
        ToolbarTextField {
            id: searchInput
            Layout.fillWidth: true
            Layout.fillHeight: true
            focus: GlobalStates.overviewOpen
            font.pixelSize: Appearance.font.pixelSize.normal
            placeholderText: Translation.tr("Search apps...")

            onTextChanged: LauncherSearch.query = text
            onAccepted: root.submitted()

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Tab) {
                    if (LauncherSearch.results.length === 0) return;
                    const tabbedText = LauncherSearch.results[0].name;
                    LauncherSearch.query = tabbedText;
                    searchInput.text = tabbedText;
                    event.accepted = true;
                }
            }
        }

        // Right Song Recognition / Voice Button
        RippleButton {
            id: songRecButton
            Layout.preferredWidth: 44
            Layout.preferredHeight: 44
            Layout.alignment: Qt.AlignVCenter
            buttonRadius: 22
            readonly property bool toggled: SongRec.running
            colBackground: toggled ? Appearance.colors.colPrimary : Appearance.colors.colTertiaryContainer
            colBackgroundHover: toggled ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimaryContainer
            colRipple: Appearance.colors.colPrimaryContainer

            scale: songRecButton.down ? 0.85 : (songRecButton.hovered ? 1.08 : 1.0)
            Behavior on scale {
                NumberAnimation {
                    duration: songRecButton.down ? 90 : 250
                    easing.type: songRecButton.down ? Easing.OutCubic : Easing.OutBack
                    easing.overshoot: 1.4
                }
            }

            onClicked: SongRec.toggleRunning()

            contentItem: MaterialShapeWrappedMaterialSymbol {
                anchors.centerIn: parent
                iconSize: 22
                shape: songRecButton.toggled ? MaterialShape.Shape.SoftBurst : MaterialShape.Shape.Cookie4Sided
                color: songRecButton.toggled ? Appearance.colors.colPrimary : Appearance.colors.colTertiaryContainer
                colSymbol: songRecButton.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnTertiaryContainer
                text: songRecButton.toggled ? "graphic_eq" : "mic"

                RotationAnimation on rotation {
                    running: songRecButton.toggled
                    duration: 2000
                    easing.type: Easing.Linear
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                }
            }

            StyledToolTip {
                text: Translation.tr("Recognize Music / Voice")
            }
        }
    }
}

