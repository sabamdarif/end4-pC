import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

/**
 * Keyboard Shortcuts page (niri).
 *
 * Viewer: services/NiriKeybinds.qml runs scripts/niri/list-binds.py, which
 * parses config.kdl + every include (the user keeps binds in
 * config.d/keybinding.kdl) and qssettings/binds.kdl. The service exposes one
 * effective bind per key (in niri the LAST bind for a key wins).
 *
 * Editor: overrides are persisted in NiriConfig.options.bindOverrides and
 * generated into qssettings/binds.kdl (generate-don't-edit, same pattern as
 * autostart.kdl). Because binds.kdl is included at the END of config.kdl,
 * an override simply shadows the user's own bind for that key — the user's
 * keybinding.kdl is NEVER touched. Requires the qssettings include lines
 * (Setup button on the Niri page).
 *
 * Key capture converts Qt key events to niri's Mod+/Ctrl+/Alt+/Shift+ format
 * for a small honest set of keys (letters, digits, F-keys, common named
 * keys); anything else can be typed into the same field manually.
 */
ContentPage {
    id: page
    forceWidth: true

    property string searchText: ""
    // Key of the bind whose inline editor is open ("" = none)
    property string editingKey: ""

    readonly property var categories: [
        { id: "apps",      icon: "apps",       title: Translation.tr("Applications"), shape: MaterialShape.Shape.Circle },
        { id: "window",    icon: "select_window", title: Translation.tr("Windows"),   shape: MaterialShape.Shape.Arch },
        { id: "workspace", icon: "workspaces", title: Translation.tr("Workspaces"),   shape: MaterialShape.Shape.Pill },
        { id: "other",     icon: "keyboard",   title: Translation.tr("Other"),        shape: MaterialShape.Shape.Clover4Leaf }
    ]

    Component.onCompleted: {
        if (NiriData.isNiri) NiriKeybinds.refresh()
    }

    function goTo(term) {
        const t = term.toLowerCase().trim()

        function findTarget(rootItem) {
            for (let i = 0; i < rootItem.children.length; i++) {
                let child = rootItem.children[i]
                if (child.title && child.title.toLowerCase().includes(t)) {
                    return child
                }
            }
            for (let i = 0; i < rootItem.children.length; i++) {
                let found = findTarget(rootItem.children[i])
                if (found) return found
            }
            return null
        }

        let target = findTarget(mainLayout)
        if (target) {
            let pos = target.mapToItem(mainLayout, 0, 0)
            page.contentY = Math.max(0, pos.y - 0)
        }
    }

    function matchesSearch(bind) {
        const q = page.searchText.toLowerCase().trim()
        if (q === "") return true
        const hay = `${bind.key} ${bind.title} ${bind.action}`.toLowerCase()
        return q.split(/\s+/).every(tok => hay.includes(tok))
    }

    function bindsFor(categoryId) {
        return NiriKeybinds.binds.filter(b =>
            NiriKeybinds.categoryOf(b) === categoryId && page.matchesSearch(b))
    }

    function fileBadge(source) {
        return String(source ?? "").split("/").pop()
    }

    // Strip .desktop Exec field codes (%U, %f, ...) to get a runnable command
    function execOf(entry) {
        let cmd = String(entry?.execString ?? "").replace(/%[a-zA-Z]/g, "").trim()
        if (cmd === "") cmd = entry?.id ?? ""
        return cmd
    }

    // ── Override persistence (rebuild-and-assign so JsonAdapter saves) ───
    function overrideList() {
        return (NiriConfig.options.bindOverrides ?? []).map(e => ({
            key: e?.key ?? "",
            action: e?.action ?? "",
            title: e?.title ?? ""
        }))
    }

    function hasOverride(key) {
        return (NiriConfig.options.bindOverrides ?? []).some(e => (e?.key ?? "") === key)
    }

    function saveOverride(key, action, title) {
        const k = String(key ?? "").trim()
        const a = String(action ?? "").trim()
        if (k === "" || a === "") return
        const list = page.overrideList()
        const entry = { key: k, action: a, title: String(title ?? "").trim() }
        const idx = list.findIndex(e => e.key === k)
        if (idx >= 0) list[idx] = entry
        else list.push(entry)
        NiriConfig.options.bindOverrides = list
    }

    function removeOverride(key) {
        NiriConfig.options.bindOverrides = page.overrideList().filter(e => e.key !== key)
    }

    // ── Key capture: Qt key event -> niri bind format ─────────────────────
    // Small honest mapping; unmapped keys leave the text field editable so
    // anything niri accepts (any XKB keysym name) can still be typed.
    function qtKeyToNiriName(k) {
        if (k >= Qt.Key_A && k <= Qt.Key_Z) return String.fromCharCode(65 + (k - Qt.Key_A))
        if (k >= Qt.Key_0 && k <= Qt.Key_9) return String.fromCharCode(48 + (k - Qt.Key_0))
        if (k >= Qt.Key_F1 && k <= Qt.Key_F35) return "F" + (k - Qt.Key_F1 + 1)
        switch (k) {
        case Qt.Key_Return:
        case Qt.Key_Enter: return "Return"
        case Qt.Key_Space: return "Space"
        case Qt.Key_Tab:
        case Qt.Key_Backtab: return "Tab"
        case Qt.Key_Backspace: return "BackSpace"
        case Qt.Key_Delete: return "Delete"
        case Qt.Key_Insert: return "Insert"
        case Qt.Key_Home: return "Home"
        case Qt.Key_End: return "End"
        case Qt.Key_PageUp: return "Page_Up"
        case Qt.Key_PageDown: return "Page_Down"
        case Qt.Key_Left: return "Left"
        case Qt.Key_Right: return "Right"
        case Qt.Key_Up: return "Up"
        case Qt.Key_Down: return "Down"
        case Qt.Key_Print: return "Print"
        case Qt.Key_Comma: return "Comma"
        case Qt.Key_Period: return "Period"
        case Qt.Key_Slash: return "Slash"
        case Qt.Key_Minus: return "Minus"
        case Qt.Key_Equal: return "Equal"
        case Qt.Key_Semicolon: return "semicolon"
        case Qt.Key_Apostrophe: return "apostrophe"
        case Qt.Key_QuoteLeft: return "grave"
        case Qt.Key_Backslash: return "backslash"
        case Qt.Key_BracketLeft: return "bracketleft"
        case Qt.Key_BracketRight: return "bracketright"
        }
        return ""
    }

    function keyEventToNiri(event) {
        const name = page.qtKeyToNiriName(event.key)
        if (name === "") return ""
        let parts = []
        if (event.modifiers & Qt.MetaModifier) parts.push("Mod")
        if (event.modifiers & Qt.ControlModifier) parts.push("Ctrl")
        if (event.modifiers & Qt.AltModifier) parts.push("Alt")
        if (event.modifiers & Qt.ShiftModifier) parts.push("Shift")
        parts.push(name)
        return parts.join("+")
    }

    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        // ── Header: search + refresh ─────────────────────────────────────
        ContentSection {
            icon: "keyboard"
            shape: MaterialShape.Shape.Clover4Leaf
            title: Translation.tr("Shortcuts")

            StyledText {
                visible: !NiriData.isNiri
                Layout.leftMargin: 8
                Layout.fillWidth: true
                text: Translation.tr("The shortcuts editor is only available on niri. On Hyprland, use the cheatsheet (Super+/).")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }

            StyledText {
                visible: NiriData.isNiri
                Layout.leftMargin: 8
                Layout.fillWidth: true
                text: Translation.tr("Read from config.kdl and its included files. Edits are saved as overrides to ~/.config/niri/qssettings/binds.kdl (later binds win per key) — your own config files are never modified. Requires the qssettings include lines: see the Setup button on the Niri page.")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }

            RowLayout {
                visible: NiriData.isNiri
                Layout.fillWidth: true
                spacing: 10

                MaterialTextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Search shortcuts (key, description or action)")
                    onTextChanged: page.searchText = text
                }
                RippleButtonWithIcon {
                    materialIcon: "refresh"
                    mainText: Translation.tr("Reload")
                    onClicked: NiriKeybinds.refresh()
                    StyledToolTip {
                        text: Translation.tr("Re-read binds from the niri config")
                    }
                }
            }

            StyledText {
                visible: NiriData.isNiri
                Layout.leftMargin: 8
                text: Translation.tr("%1 shortcuts • %2 overrides")
                    .arg(NiriKeybinds.binds.length)
                    .arg((NiriConfig.options.bindOverrides ?? []).length)
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }

        // ── Add a shortcut ───────────────────────────────────────────────
        ContentSection {
            visible: NiriData.isNiri
            icon: "add_circle"
            shape: MaterialShape.Shape.Circle
            title: Translation.tr("Add a shortcut")

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: addCol.implicitHeight + 28
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1

                ColumnLayout {
                    id: addCol
                    anchors { fill: parent; margins: 14 }
                    spacing: 8

                    // Bind currently in effect for the captured key, if any
                    readonly property var existing: NiriKeybinds.binds.find(b => b.key === newKeyField.text.trim()) ?? null

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        MaterialTextField {
                            id: newKeyField
                            Layout.fillWidth: true
                            placeholderText: Translation.tr("Key combo (e.g. Mod+Shift+T)")
                            property bool capturing: false
                            Keys.onPressed: event => {
                                if (!newKeyField.capturing) return
                                event.accepted = true
                                if (event.key === Qt.Key_Escape) {
                                    newKeyField.capturing = false
                                    return
                                }
                                const combo = page.keyEventToNiri(event)
                                if (combo !== "") {
                                    newKeyField.text = combo
                                    newKeyField.capturing = false
                                }
                            }
                            onActiveFocusChanged: if (!activeFocus) capturing = false
                        }

                        RippleButtonWithIcon {
                            materialIcon: "keyboard"
                            mainText: newKeyField.capturing
                                ? Translation.tr("Press keys…")
                                : Translation.tr("Capture")
                            onClicked: {
                                newKeyField.capturing = !newKeyField.capturing
                                if (newKeyField.capturing) newKeyField.forceActiveFocus()
                            }
                            StyledToolTip {
                                text: Translation.tr("Press the shortcut you want (Esc cancels). Unrecognized keys can be typed manually — any XKB key name works.")
                            }
                        }
                    }

                    ConfigComboBox {
                        id: newAppCombo
                        Layout.fillWidth: true
                        buttonIcon: "apps"
                        text: Translation.tr("Launch an application")
                        model: [{ displayName: Translation.tr("Pick an application…"), value: "" }]
                            .concat(AppSearch.list
                                .filter(a => !a.noDisplay)
                                .map(a => ({ displayName: a.name, value: a.id }))
                                .sort((x, y) => x.displayName.localeCompare(y.displayName)))
                        currentValue: ""
                        onSelected: newValue => {
                            if (newValue === "") return
                            const entry = DesktopEntries.byId(newValue)
                            newRawSwitch.checked = false
                            newCommandField.text = page.execOf(entry)
                            if (newTitleField.text.trim() === "")
                                newTitleField.text = entry?.name ?? ""
                        }
                    }

                    MaterialTextField {
                        id: newCommandField
                        Layout.fillWidth: true
                        placeholderText: newRawSwitch.checked
                            ? Translation.tr("Raw niri action, e.g. focus-workspace 2 or toggle-overview")
                            : Translation.tr("Command to run, e.g. kitty -e btop")
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        StyledSwitch {
                            id: newRawSwitch
                            checked: false
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: Translation.tr("Raw niri action instead of a command")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            wrapMode: Text.Wrap
                        }
                    }

                    MaterialTextField {
                        id: newTitleField
                        Layout.fillWidth: true
                        placeholderText: Translation.tr("Description (shown in the hotkey overlay — optional)")
                    }

                    StyledText {
                        visible: addCol.existing !== null
                        Layout.fillWidth: true
                        text: Translation.tr("%1 is already bound to \"%2\" (%3) — saving will shadow it")
                            .arg(newKeyField.text.trim())
                            .arg(addCol.existing?.title ?? "")
                            .arg(page.fileBadge(addCol.existing?.source ?? ""))
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.m3colors.m3error
                        wrapMode: Text.Wrap
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Item { Layout.fillWidth: true }
                        DialogButton {
                            buttonText: Translation.tr("Clear")
                            onClicked: {
                                newKeyField.text = ""
                                newCommandField.text = ""
                                newTitleField.text = ""
                                newRawSwitch.checked = false
                            }
                        }
                        DialogButton {
                            buttonText: Translation.tr("Add")
                            enabled: newKeyField.text.trim() !== "" && newCommandField.text.trim() !== ""
                            onClicked: {
                                const cmd = newCommandField.text.trim()
                                // spawn takes argv, so route commands through
                                // sh -c to keep pipes/env vars/~ working —
                                // same trick as the generated autostart.kdl
                                const action = newRawSwitch.checked
                                    ? cmd
                                    : `spawn "sh" "-c" "${NiriConfig.kdlEscape(cmd)}"`
                                page.saveOverride(newKeyField.text, action, newTitleField.text)
                                newKeyField.text = ""
                                newCommandField.text = ""
                                newTitleField.text = ""
                                newRawSwitch.checked = false
                            }
                        }
                    }
                }
            }
        }

        // ── Category sections ────────────────────────────────────────────
        Repeater {
            model: page.categories

            delegate: ContentSection {
                id: catSection
                required property var modelData
                readonly property var catBinds: page.bindsFor(modelData.id)
                visible: NiriData.isNiri && catBinds.length > 0
                icon: modelData.icon
                shape: modelData.shape
                title: modelData.title

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: catCol.implicitHeight + 20
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1

                    ColumnLayout {
                        id: catCol
                        anchors { fill: parent; margins: 10 }
                        spacing: 2

                        Repeater {
                            model: catSection.catBinds

                            delegate: ColumnLayout {
                                id: bindRow
                                required property var modelData
                                readonly property bool expanded: page.editingKey === modelData.key
                                Layout.fillWidth: true
                                spacing: 2

                                RippleButton {
                                    Layout.fillWidth: true
                                    implicitHeight: Math.max(42, rowContent.implicitHeight + 12)
                                    buttonRadius: Appearance.rounding.small
                                    colBackground: "transparent"
                                    onClicked: page.editingKey = bindRow.expanded ? "" : bindRow.modelData.key

                                    contentItem: RowLayout {
                                        id: rowContent
                                        spacing: 10

                                        RowLayout {
                                            spacing: 3
                                            Repeater {
                                                model: bindRow.modelData.key.split("+")
                                                delegate: KeyboardKey {
                                                    required property var modelData
                                                    key: modelData
                                                }
                                            }
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: bindRow.modelData.title
                                            elide: Text.ElideRight
                                            color: Appearance.colors.colOnSecondaryContainer
                                        }

                                        MaterialSymbol {
                                            visible: bindRow.modelData.conflict
                                            text: "warning"
                                            iconSize: Appearance.font.pixelSize.larger
                                            color: Appearance.m3colors.m3error
                                            MouseArea {
                                                id: conflictHoverArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                acceptedButtons: Qt.NoButton
                                                StyledToolTip {
                                                    extraVisibleCondition: false
                                                    alternativeVisibleCondition: conflictHoverArea.containsMouse
                                                    text: Translation.tr("Shadows \"%1\" from %2")
                                                        .arg(bindRow.modelData.shadowedTitle)
                                                        .arg(page.fileBadge(bindRow.modelData.shadowedSource))
                                                }
                                            }
                                        }

                                        Rectangle {
                                            visible: bindRow.modelData.isOverride
                                            implicitWidth: overrideBadgeText.implicitWidth + 16
                                            implicitHeight: overrideBadgeText.implicitHeight + 6
                                            radius: height / 2
                                            color: Appearance.colors.colSecondaryContainer
                                            StyledText {
                                                id: overrideBadgeText
                                                anchors.centerIn: parent
                                                text: Translation.tr("override")
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                color: Appearance.colors.colOnSecondaryContainer
                                            }
                                        }

                                        Rectangle {
                                            visible: !bindRow.modelData.isOverride
                                            implicitWidth: sourceBadgeText.implicitWidth + 16
                                            implicitHeight: sourceBadgeText.implicitHeight + 6
                                            radius: height / 2
                                            color: Appearance.colors.colLayer2
                                            StyledText {
                                                id: sourceBadgeText
                                                anchors.centerIn: parent
                                                text: page.fileBadge(bindRow.modelData.source)
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                color: Appearance.colors.colSubtext
                                            }
                                            MouseArea {
                                                id: sourceHoverArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                acceptedButtons: Qt.NoButton
                                                StyledToolTip {
                                                    extraVisibleCondition: false
                                                    alternativeVisibleCondition: sourceHoverArea.containsMouse
                                                    text: bindRow.modelData.source
                                                }
                                            }
                                        }
                                    }
                                }

                                // ── Inline editor ────────────────────────
                                ColumnLayout {
                                    id: editor
                                    visible: bindRow.expanded
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 12
                                    Layout.rightMargin: 12
                                    Layout.bottomMargin: 8
                                    spacing: 8

                                    function prefill() {
                                        keyField.capturing = false
                                        keyField.text = bindRow.modelData.key
                                        actionField.text = bindRow.modelData.action
                                        titleField.text = bindRow.modelData.title
                                    }
                                    // Delegates can be (re)created with the
                                    // editor already open (refresh after save)
                                    Component.onCompleted: if (visible) editor.prefill()
                                    onVisibleChanged: if (visible) editor.prefill()

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10

                                        MaterialTextField {
                                            id: keyField
                                            Layout.fillWidth: true
                                            placeholderText: Translation.tr("Key combo (e.g. Mod+Shift+T)")
                                            property bool capturing: false
                                            Keys.onPressed: event => {
                                                if (!keyField.capturing) return
                                                event.accepted = true
                                                if (event.key === Qt.Key_Escape) {
                                                    keyField.capturing = false
                                                    return
                                                }
                                                const combo = page.keyEventToNiri(event)
                                                if (combo !== "") {
                                                    keyField.text = combo
                                                    keyField.capturing = false
                                                }
                                            }
                                            onActiveFocusChanged: {
                                                if (!activeFocus) capturing = false
                                            }
                                        }

                                        RippleButtonWithIcon {
                                            materialIcon: "keyboard"
                                            mainText: keyField.capturing
                                                ? Translation.tr("Press keys…")
                                                : Translation.tr("Capture")
                                            onClicked: {
                                                keyField.capturing = !keyField.capturing
                                                if (keyField.capturing) keyField.forceActiveFocus()
                                            }
                                            StyledToolTip {
                                                text: Translation.tr("Capture a key combination (Esc cancels). Unrecognized keys can be typed manually — any XKB key name works.")
                                            }
                                        }
                                    }

                                    MaterialTextField {
                                        id: actionField
                                        Layout.fillWidth: true
                                        placeholderText: Translation.tr("Action (raw niri syntax, e.g. spawn \"kitty\" or focus-workspace 2)")
                                    }

                                    MaterialTextField {
                                        id: titleField
                                        Layout.fillWidth: true
                                        placeholderText: Translation.tr("Description (shown in the hotkey overlay — optional)")
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: Translation.tr("Saved as an override — applies live if the include lines are set up")
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.colors.colSubtext
                                            elide: Text.ElideRight
                                        }
                                        DialogButton {
                                            visible: page.hasOverride(bindRow.modelData.key)
                                            buttonText: Translation.tr("Reset override")
                                            colText: Appearance.m3colors.m3error
                                            onClicked: {
                                                page.removeOverride(bindRow.modelData.key)
                                                page.editingKey = ""
                                            }
                                        }
                                        DialogButton {
                                            buttonText: Translation.tr("Cancel")
                                            onClicked: page.editingKey = ""
                                        }
                                        DialogButton {
                                            buttonText: Translation.tr("Save")
                                            enabled: keyField.text.trim() !== "" && actionField.text.trim() !== ""
                                            onClicked: {
                                                page.saveOverride(keyField.text, actionField.text, titleField.text)
                                                page.editingKey = ""
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── No results ───────────────────────────────────────────────────
        StyledText {
            visible: NiriData.isNiri && page.searchText.trim() !== ""
                && page.categories.every(c => page.bindsFor(c.id).length === 0)
            Layout.leftMargin: 8
            text: Translation.tr("No shortcuts match \"%1\"").arg(page.searchText)
            color: Appearance.colors.colSubtext
        }
    }
}
