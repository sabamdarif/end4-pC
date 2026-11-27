pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import "." as ShortcutComponents
import "../../../../../services/NiriShortcuts.js" as Shortcuts

ContentPage {
    id: page
    maxContentWidth: 900
    bottomContentPadding: 100

    property string searchText: ""
    property string selectedCategory: ""
    property var filteredGroups: []
    property var editingGroup: null
    property int editingKeyIndex: -1
    property bool editorMounted: false
    property string pendingRemoval: ""
    property string revealAction: ""
    property Item returnFocus: null
    readonly property var groups: NiriKeybinds.groups
    readonly property var categories: [
        { key: "", title: Translation.tr("All") },
        { key: "overrides", title: Translation.tr("Overrides") },
        { key: "shell", title: Translation.tr("Shell") },
        { key: "apps", title: Translation.tr("Applications") },
        { key: "window", title: Translation.tr("Windows") },
        { key: "workspace", title: Translation.tr("Workspaces") },
        { key: "monitor", title: Translation.tr("Monitors") },
        { key: "screenshot", title: Translation.tr("Screenshots") },
        { key: "other", title: Translation.tr("Other") }
    ].filter(c => c.key === "" || c.key === "overrides" || page.groups.some(g => g.category === c.key))

    function categoryLabel(key) {
        return page.categories.find(c => c.key === key)?.title || ""
    }

    function updateFilter() {
        page.filteredGroups = page.groups.filter(g =>
            (page.selectedCategory === "" || (page.selectedCategory === "overrides"
                ? g.keys.some(k => k.isOverride) : g.category === page.selectedCategory)) &&
            Shortcuts.matchesSearch(g, page.searchText, NiriKeybinds.modKey))
    }

    function edit(group, keyIndex) {
        page.returnFocus = page.Window.window?.activeFocusItem ?? null
        page.editingGroup = group
        page.editingKeyIndex = keyIndex
        page.editorMounted = true
    }

    function remove(key) {
        page.pendingRemoval = key
        removeDialog.open()
    }

    Component.onCompleted: {
        NiriKeybinds.refresh()
        page.updateFilter()
    }
    onGroupsChanged: {
        page.updateFilter()
        if (page.categories && !page.categories.some(c => c.key === page.selectedCategory)) page.selectedCategory = ""
        if (page.revealAction !== "") Qt.callLater(page.revealSavedRow)
    }
    onSelectedCategoryChanged: {
        page.updateFilter()
        page.contentY = 0
    }
    onVisibleChanged: {
        if (visible) NiriKeybinds.refresh()
        else if (editorLoader.item && !NiriConfig.savingBind) editorLoader.item.close()
    }

    function revealSavedRow() {
        const index = page.filteredGroups.findIndex(g => g.action === page.revealAction)
        const row = rows.itemAt(index)
        if (!row) return
        page.revealAction = ""
        page.contentY = Math.max(0, page.contentY + row.mapToItem(page, 0, 0).y - page.height / 2)
    }

    Timer {
        id: searchDelay
        interval: 120
        onTriggered: {
            page.updateFilter()
            page.contentY = 0
        }
    }

    ShortcutInhibitor {
        id: searchInhibitor
        window: searchField.QsWindow.window
        enabled: page.visible && searchField.activeFocus
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        ToolbarTextField {
            id: searchField
            objectName: "shortcutSearchField"
            Layout.fillWidth: true
            Layout.fillHeight: false
            implicitHeight: 44
            leadingIcon: "search"
            clearable: true
            colBackground: Appearance.colors.colLayer2
            colBackgroundFocused: Appearance.colors.colLayer3
            placeholderText: searchInhibitor.active
                ? Translation.tr("Search or press a shortcut…") : Translation.tr("Search shortcuts…")
            onTextChanged: {
                page.searchText = text
                searchDelay.restart()
            }
            Keys.onPressed: event => {
                const combo = Shortcuts.searchCombo(event, NiriKeybinds.modKey)
                if (!combo) return
                event.accepted = true
                text = combo
            }
        }
        RippleButton {
            objectName: "shortcutReloadButton"
            implicitWidth: searchField.height
            implicitHeight: searchField.height
            Layout.preferredWidth: searchField.height
            Layout.preferredHeight: searchField.height
            Layout.alignment: Qt.AlignVCenter
            padding: 0
            buttonRadius: Appearance.rounding.full
            buttonRadiusPressed: Appearance.rounding.small
            colBackground: Appearance.colors.colLayer2
            colBackgroundHover: Appearance.colors.colLayer2Hover
            colRipple: Appearance.colors.colLayer2Active
            contentItem: MaterialSymbol {
                text: "refresh"
                iconSize: Appearance.font.pixelSize.huge
                color: Appearance.colors.colOnLayer2
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            enabled: !NiriKeybinds.loading
            Accessible.name: Translation.tr("Reload shortcuts")
            onClicked: NiriKeybinds.refresh()
            StyledToolTip { text: Translation.tr("Reload shortcuts") }
        }
        RippleButtonWithIcon {
            Layout.preferredHeight: searchField.height
            Layout.alignment: Qt.AlignVCenter
            materialIcon: "keyboard"
            mainText: page.width > 640 ? Translation.tr("Cheatsheet") : ""
            buttonRadius: Appearance.rounding.full
            buttonRadiusPressed: Appearance.rounding.small
            colBackground: Appearance.colors.colLayer2
            colBackgroundHover: Appearance.colors.colLayer2Hover
            colRipple: Appearance.colors.colLayer2Active
            Accessible.name: Translation.tr("Cheatsheet")
            onClicked: Quickshell.execDetached(["niri", "msg", "action", "show-hotkey-overlay"])
            StyledToolTip { text: Translation.tr("Show niri hotkey cheatsheet") }
        }
    }

    Flow {
        Layout.fillWidth: true
        spacing: 8
        Repeater {
            model: page.categories
            delegate: RippleButton {
                id: chip
                required property var modelData
                implicitWidth: chipLabel.implicitWidth + 28
                implicitHeight: 36
                buttonRadius: height / 2
                buttonRadiusPressed: Appearance.rounding.small
                toggled: page.selectedCategory === modelData.key
                colBackground: Appearance.colors.colLayer1
                colBackgroundHover: Appearance.colors.colLayer1Hover
                colRipple: Appearance.colors.colLayer1Active
                colBackgroundToggled: Appearance.colors.colSecondaryContainer
                colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                colRippleToggled: Appearance.colors.colSecondaryContainerActive
                Accessible.name: modelData.title
                Accessible.role: Accessible.RadioButton
                Accessible.checked: page.selectedCategory === modelData.key
                onClicked: page.selectedCategory = modelData.key
                contentItem: StyledText {
                    id: chipLabel
                    text: chip.modelData.title
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.weight: chip.toggled ? Font.DemiBold : Font.Normal
                    color: Appearance.colors.colOnSecondaryContainer
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: notice.implicitHeight + 32
        radius: Appearance.rounding.normal
        color: Appearance.colors.colSecondaryContainer
        visible: !NiriKeybinds.loading && (!NiriKeybinds.included || NiriKeybinds.overriddenBy > 0)
        RowLayout {
            id: notice
            anchors { fill: parent; margins: 16 }
            spacing: 12
            MaterialSymbol { text: "info"; iconSize: Appearance.font.pixelSize.larger }
            ColumnLayout {
                Layout.fillWidth: true
                StyledText {
                    Layout.fillWidth: true
                    text: !NiriKeybinds.included ? Translation.tr("First time setup") : Translation.tr("Possible override conflicts")
                    font.weight: Font.Medium
                    wrapMode: Text.Wrap
                }
                StyledText {
                    Layout.fillWidth: true
                    text: !NiriKeybinds.included
                        ? Translation.tr("Add the copied include lines at the end of %1 to apply shortcut edits.").arg(NiriConfig.configPath)
                        : Translation.tr("%1 overrides are replaced by config binds after the include. Move the shortcut include to the end of your config.").arg(NiriKeybinds.overriddenBy)
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    wrapMode: Text.Wrap
                }
            }
            DialogButton {
                visible: !NiriKeybinds.included
                buttonText: Translation.tr("Copy includes")
                onClicked: Quickshell.clipboardText = NiriConfig.includeLines
            }
        }
    }

    ContentSection {
        icon: "keyboard"
        shape: MaterialShape.Shape.Gem
        title: Translation.tr("Shortcuts (%1)").arg(page.filteredGroups.length)

        MaterialLoadingIndicator {
            Layout.alignment: Qt.AlignHCenter
            visible: NiriKeybinds.loading
            loading: NiriKeybinds.loading
        }
        StyledText {
            Layout.fillWidth: true
            visible: NiriKeybinds.errorText !== "" || (NiriConfig.bindError !== "" && !page.editorMounted)
            text: NiriKeybinds.errorText || NiriConfig.bindError
            color: Appearance.m3colors.m3error
            wrapMode: Text.Wrap
        }
        StyledText {
            Layout.fillWidth: true
            visible: !NiriKeybinds.loading && page.filteredGroups.length === 0
            text: page.searchText !== "" ? Translation.tr("No shortcuts match \"%1\"").arg(page.searchText) : Translation.tr("No keybinds found")
            color: Appearance.colors.colSubtext
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Repeater {
                id: rows
                model: page.filteredGroups
                delegate: ShortcutComponents.ShortcutRow {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    bindData: modelData
                    categoryLabel: page.categoryLabel(modelData.category)
                    firstInGroup: index === 0
                    lastInGroup: index === page.filteredGroups.length - 1
                    onEditRequested: keyIndex => page.edit(modelData, keyIndex)
                    onRemoveRequested: key => page.remove(key)
                }
            }
        }
    }

    Item {
        parent: page
        anchors { right: parent.right; bottom: parent.bottom; margins: 20 }
        implicitWidth: addShortcutFab.implicitWidth
        implicitHeight: addShortcutFab.implicitHeight

        StyledRectangularShadow {
            target: addShortcutFab
        }

        FloatingActionButton {
            id: addShortcutFab
            anchors.fill: parent
            expanded: true
            iconText: "add"
            buttonText: Translation.tr("Add shortcut")
            enabled: NiriConfig.ready && !NiriConfig.savingBind
            onClicked: page.edit(null, -1)
        }
    }

    Loader {
        id: editorLoader
        active: page.editorMounted
        sourceComponent: ShortcutComponents.ShortcutEditorDialog {
            onClosed: {
                page.editorMounted = false
                if (page.returnFocus?.visible && page.returnFocus.enabled) page.returnFocus.forceActiveFocus()
                page.returnFocus = null
            }
            onSaved: action => {
                if (!page.editingGroup) page.selectedCategory = ""
                page.revealAction = action
                page.searchText = ""
                searchField.text = ""
                searchDelay.stop()
                page.updateFilter()
                Qt.callLater(page.revealSavedRow)
                NiriKeybinds.refresh()
            }
        }
        onLoaded: item.present(page.editingGroup, page.editingKeyIndex)
    }

    Dialog {
        id: removeDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(440, parent.width - 32)
        modal: true
        padding: 24
        closePolicy: NiriConfig.savingBind ? Popup.NoAutoClose : Popup.CloseOnEscape | Popup.CloseOnPressOutside
        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
        }
        background: Item {
            StyledRectangularShadow { target: removeDialogBg }
            Rectangle {
                id: removeDialogBg
                anchors.fill: parent
                color: Appearance.colors.colLayer1
                radius: Appearance.rounding.large
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
            }
        }
        contentItem: ColumnLayout {
            spacing: 16
            StyledText { text: Translation.tr("Remove shortcut?"); font.pixelSize: Appearance.font.pixelSize.larger }
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Remove the override for %1? Any original config shortcut on this key will become active again.").arg(page.pendingRemoval)
                wrapMode: Text.Wrap
            }
            StyledText { Layout.fillWidth: true; visible: NiriConfig.bindError !== ""; text: NiriConfig.bindError; wrapMode: Text.Wrap; color: Appearance.m3colors.m3error }
            RowLayout {
                Item { Layout.fillWidth: true }
                DialogButton { buttonText: Translation.tr("Cancel"); enabled: !NiriConfig.savingBind; onClicked: removeDialog.close() }
                DialogButton {
                    buttonText: Translation.tr("Remove")
                    enabled: !NiriConfig.savingBind
                    colText: Appearance.m3colors.m3error
                    onClicked: NiriConfig.removeBindOverride(page.pendingRemoval, NiriKeybinds.modKey)
                }
            }
        }
        onOpened: NiriConfig.bindError = ""
    }
    Connections {
        target: NiriConfig
        function onBindSaveCompleted(success) {
            if (success && removeDialog.visible) {
                removeDialog.close()
                NiriKeybinds.refresh()
            }
        }
    }
}
