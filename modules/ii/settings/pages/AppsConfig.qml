import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

/**
 * Apps page — default applications (xdg), niri-native autostart,
 * app ID substitutions for bar/dock icons, clipboard history settings.
 *
 * - Default apps: services/DefaultApps.qml (xdg-settings / xdg-mime +
 *   mimeinfo.cache candidates). Terminal stays Config.options.apps.terminal
 *   (shell-side setting, not an xdg mimetype).
 * - Autostart: NiriConfig.options.autostart -> qssettings/autostart.kdl
 *   (spawn-at-startup), regenerated on every change. Needs the include
 *   lines from the Niri page's Setup button; applies on the next niri start.
 * - Dynamic lists use Rectangle card + ColumnLayout + Repeater (GroupedList
 *   reparents static children only and breaks with Repeater inside).
 */
ContentPage {
    id: page
    forceWidth: true

    property string appSearchQuery: ""
    readonly property var filteredApps: {
        const query = appSearchQuery.toLowerCase().trim()
        const list = query === "" ? AppInventory.apps : AppInventory.apps.filter(app =>
            `${app.name} ${app.id} ${app.comment} ${app.source}`.toLowerCase().includes(query))
        return list.slice(0, 100)
    }

    readonly property var defaultAppRoles: [
        { key: "browser", icon: "language",       label: Translation.tr("Web browser") },
        { key: "mail",    icon: "mail",           label: Translation.tr("Mail client") },
        { key: "files",   icon: "folder",         label: Translation.tr("File manager") },
        { key: "editor",  icon: "edit_note",      label: Translation.tr("Text editor") },
        { key: "image",   icon: "image",          label: Translation.tr("Image viewer") },
        { key: "pdf",     icon: "picture_as_pdf", label: Translation.tr("PDF viewer") },
        { key: "music",   icon: "music_note",     label: Translation.tr("Music player") },
        { key: "video",   icon: "movie",          label: Translation.tr("Video player") }
    ]

    Component.onCompleted: DefaultApps.refresh()

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

    function defaultAppModel(key) {
        const cands = (DefaultApps.candidates[key] ?? []).slice()
        const cur = DefaultApps.current[key] ?? ""
        if (cur !== "" && !cands.includes(cur)) cands.unshift(cur)
        const items = cands.map(id => ({ displayName: DefaultApps.displayName(id), value: id }))
        items.sort((a, b) => a.displayName.localeCompare(b.displayName))
        if (cur === "") items.unshift({ displayName: Translation.tr("Not set"), value: "" })
        return items
    }

    // ── Autostart list helpers (rebuild-and-assign so JsonAdapter saves) ──
    function autostartList() {
        return (NiriConfig.options.autostart ?? []).map(e => ({
            command: e?.command ?? "",
            enabled: e?.enabled ?? true
        }))
    }

    function addAutostart(cmd) {
        const c = String(cmd ?? "").trim()
        if (c === "") return
        const list = page.autostartList()
        list.push({ command: c, enabled: true })
        NiriConfig.options.autostart = list
    }

    function removeAutostart(index) {
        const list = page.autostartList()
        list.splice(index, 1)
        NiriConfig.options.autostart = list
    }

    function updateAutostart(index, key, value) {
        const list = page.autostartList()
        if (index < 0 || index >= list.length) return
        list[index][key] = value
        NiriConfig.options.autostart = list
    }

    function fileBadge(path) {
        return String(path ?? "").split("/").pop()
    }

    // Strip .desktop Exec field codes (%U, %f, ...) to get a runnable command
    function execOf(entry) {
        let cmd = String(entry?.execString ?? "").replace(/%[a-zA-Z]/g, "").trim()
        if (cmd === "") cmd = entry?.id ?? ""
        return cmd
    }

    // ── App ID substitution helpers ───────────────────────────────────────
    function substitutionList() {
        return (Config.options.apps.idSubstitutions ?? []).map(e => ({
            from: e?.from ?? "",
            to: e?.to ?? ""
        }))
    }

    function addSubstitution() {
        const list = page.substitutionList()
        list.push({ from: "", to: "" })
        Config.options.apps.idSubstitutions = list
    }

    function removeSubstitution(index) {
        const list = page.substitutionList()
        list.splice(index, 1)
        Config.options.apps.idSubstitutions = list
    }

    function updateSubstitution(index, key, value) {
        const list = page.substitutionList()
        if (index < 0 || index >= list.length) return
        list[index][key] = value
        Config.options.apps.idSubstitutions = list
    }

    // Add or update the cliphist watcher autostart entries with the
    // configured -max-items flag (the flag lives on `cliphist store`)
    function applyCliphistToAutostart() {
        const n = Config.options.cliphist.maxEntries
        const list = page.autostartList()
        let found = false
        for (const entry of list) {
            if (!entry.command.includes("cliphist store")) continue
            found = true
            let c = entry.command.replace(/\s+-max-items\s+\d+/, "")
            entry.command = c.replace("cliphist store", `cliphist store -max-items ${n}`)
        }
        if (!found) {
            list.push({ command: `wl-paste --type text --watch cliphist store -max-items ${n}`, enabled: true })
            list.push({ command: `wl-paste --type image --watch cliphist store -max-items ${n}`, enabled: true })
        }
        NiriConfig.options.autostart = list
    }

    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        // ── Default applications ─────────────────────────────────────────
        ContentSection {
            icon: "apps"
            shape: MaterialShape.Shape.Circle
            title: Translation.tr("Default applications")

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: defaultAppsCol.implicitHeight + 28
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1

                ColumnLayout {
                    id: defaultAppsCol
                    anchors { fill: parent; margins: 14 }
                    spacing: 8

                    Repeater {
                        model: page.defaultAppRoles
                        delegate: ConfigComboBox {
                            required property var modelData
                            Layout.fillWidth: true
                            buttonIcon: modelData.icon
                            text: modelData.label
                            model: page.defaultAppModel(modelData.key)
                            currentValue: DefaultApps.current[modelData.key] ?? ""
                            onSelected: newValue => {
                                if (newValue === "" || newValue === (DefaultApps.current[modelData.key] ?? "")) return
                                DefaultApps.setDefault(modelData.key, newValue)
                            }
                        }
                    }
                }
            }

            GroupedList {
                ConfigTextArea {
                    id: terminalField
                    buttonIcon: "terminal"
                    text: Translation.tr("Terminal")
                    description: Translation.tr("Used by shell actions (not an xdg default)")
                    value: Config.options.apps.terminal
                    onValueChanged: terminalDebounceTimer.restart()
                    Timer {
                        id: terminalDebounceTimer
                        interval: 1500
                        onTriggered: {
                            if (terminalField.value !== Config.options.apps.terminal)
                                Config.options.apps.terminal = terminalField.value
                        }
                    }
                }
            }

            StyledText {
                visible: DefaultApps.lastError !== ""
                Layout.leftMargin: 8
                Layout.fillWidth: true
                text: DefaultApps.lastError
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.m3colors.m3error
                wrapMode: Text.Wrap
            }
        }

        // ── Autostart (niri-native) ──────────────────────────────────────
        ContentSection {
            visible: NiriData.isNiri
            icon: "rocket_launch"
            shape: MaterialShape.Shape.Arch
            title: Translation.tr("Autostart")

            StyledText {
                Layout.leftMargin: 8
                Layout.fillWidth: true
                text: Translation.tr("Entries are written to ~/.config/niri/qssettings/autostart.kdl and start with niri (applies on the next niri start). Requires the qssettings include lines — see the Setup button on the Niri page.")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }

            StyledText {
                Layout.leftMargin: 8
                Layout.topMargin: 4
                text: Translation.tr("Managed here")
                font.weight: Font.Medium
                color: Appearance.colors.colOnSecondaryContainer
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: autostartCol.implicitHeight + 20
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1

                ColumnLayout {
                    id: autostartCol
                    anchors { fill: parent; margins: 10 }
                    spacing: 4

                    StyledText {
                        visible: (NiriConfig.options.autostart ?? []).length === 0
                        Layout.leftMargin: 8
                        text: Translation.tr("No autostart entries")
                        color: Appearance.colors.colSubtext
                    }

                    Repeater {
                        model: NiriConfig.options.autostart
                        delegate: RowLayout {
                            id: autostartRow
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            spacing: 10

                            StyledSwitch {
                                Layout.leftMargin: 4
                                checked: autostartRow.modelData.enabled ?? true
                                onClicked: page.updateAutostart(autostartRow.index, "enabled", checked)
                                StyledToolTip {
                                    text: Translation.tr("Start this entry with niri")
                                }
                            }

                            MaterialTextArea {
                                id: autostartCmdArea
                                Layout.fillWidth: true
                                placeholderText: Translation.tr("Command")
                                text: autostartRow.modelData.command ?? ""
                                wrapMode: TextEdit.Wrap
                                font.pixelSize: Appearance.font.pixelSize.small
                                opacity: (autostartRow.modelData.enabled ?? true) ? 1 : 0.5

                                property bool ready: false
                                Component.onCompleted: ready = true
                                onTextChanged: {
                                    if (!ready) return
                                    autostartCmdDebounce.restart()
                                }
                                Timer {
                                    id: autostartCmdDebounce
                                    interval: 2000
                                    onTriggered: {
                                        if (autostartCmdArea.text !== (autostartRow.modelData.command ?? ""))
                                            page.updateAutostart(autostartRow.index, "command", autostartCmdArea.text)
                                    }
                                }
                            }

                            RippleButton {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                buttonRadius: width / 2
                                colBackground: ColorUtils.transparentize(Appearance.colors.colError, 0.85)
                                colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colError, 0.6)
                                colRipple: ColorUtils.transparentize(Appearance.colors.colError, 0.5)
                                onClicked: page.removeAutostart(autostartRow.index)
                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "delete"
                                    iconSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colError
                                }
                                StyledToolTip {
                                    text: Translation.tr("Remove this entry")
                                }
                            }
                        }
                    }
                }
            }

            GroupedList {
                ConfigComboBox {
                    id: appPickerCombo
                    buttonIcon: "add_circle"
                    text: Translation.tr("Add application")
                    model: [{ displayName: Translation.tr("Pick an application…"), value: "" }]
                        .concat(AppSearch.list
                            .filter(a => !a.noDisplay)
                            .map(a => ({ displayName: a.name, value: a.id }))
                            .sort((x, y) => x.displayName.localeCompare(y.displayName)))
                    currentValue: ""
                    onSelected: newValue => {
                        if (newValue === "") return
                        page.addAutostart(page.execOf(DesktopEntries.byId(newValue)))
                        appPickerCombo.comboBox.currentIndex = 0
                    }
                }
                ConfigTextArea {
                    id: rawCommandField
                    buttonIcon: "terminal"
                    text: Translation.tr("Add raw command")
                    placeholderText: Translation.tr("e.g. wl-paste --watch cliphist store")
                    confirmButtonVisible: rawCommandField.value.trim() !== ""
                    confirmButtonIcon: "add"
                    onConfirmClicked: {
                        page.addAutostart(rawCommandField.value)
                        rawCommandField.value = ""
                    }
                }
            }

            // ── spawn-at-startup found in the user's own niri config ─────
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 10
                StyledText {
                    Layout.leftMargin: 8
                    Layout.fillWidth: true
                    text: Translation.tr("From your niri config")
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnSecondaryContainer
                }
                RippleButtonWithIcon {
                    materialIcon: "refresh"
                    mainText: Translation.tr("Reload")
                    onClicked: SystemAutostart.refresh()
                }
            }

            StyledText {
                Layout.leftMargin: 8
                Layout.fillWidth: true
                text: Translation.tr("spawn-at-startup entries in config.kdl and its includes. Turning one off comments the line out; removing deletes it. Applies on the next niri start.")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: niriAutostartCol.implicitHeight + 20
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1

                ColumnLayout {
                    id: niriAutostartCol
                    anchors { fill: parent; margins: 10 }
                    spacing: 4

                    StyledText {
                        visible: SystemAutostart.niriEntries.length === 0
                        Layout.leftMargin: 8
                        text: Translation.tr("No spawn-at-startup entries in your niri config")
                        color: Appearance.colors.colSubtext
                    }

                    Repeater {
                        model: SystemAutostart.niriEntries
                        delegate: RowLayout {
                            id: niriEntryRow
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 10

                            StyledSwitch {
                                Layout.leftMargin: 4
                                checked: niriEntryRow.modelData.enabled
                                onClicked: SystemAutostart.setNiriEnabled(niriEntryRow.modelData, checked)
                                StyledToolTip {
                                    text: Translation.tr("Start this entry with niri")
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                opacity: niriEntryRow.modelData.enabled ? 1 : 0.5

                                StyledText {
                                    Layout.fillWidth: true
                                    text: niriEntryRow.modelData.command
                                    elide: Text.ElideRight
                                    color: Appearance.colors.colOnSecondaryContainer
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: `${page.fileBadge(niriEntryRow.modelData.file)}:${niriEntryRow.modelData.line}`
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                    elide: Text.ElideRight
                                    MouseArea {
                                        id: niriSourceHoverArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.NoButton
                                        StyledToolTip {
                                            extraVisibleCondition: false
                                            alternativeVisibleCondition: niriSourceHoverArea.containsMouse
                                            text: niriEntryRow.modelData.file
                                        }
                                    }
                                }
                            }

                            RippleButton {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                buttonRadius: width / 2
                                colBackground: ColorUtils.transparentize(Appearance.colors.colError, 0.85)
                                colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colError, 0.6)
                                colRipple: ColorUtils.transparentize(Appearance.colors.colError, 0.5)
                                onClicked: SystemAutostart.removeNiri(niriEntryRow.modelData)
                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "delete"
                                    iconSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colError
                                }
                                StyledToolTip {
                                    text: Translation.tr("Delete this line from %1").arg(niriEntryRow.modelData.file)
                                }
                            }
                        }
                    }
                }
            }

            StyledText {
                visible: SystemAutostart.lastError !== ""
                Layout.leftMargin: 8
                Layout.fillWidth: true
                text: SystemAutostart.lastError
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.m3colors.m3error
                wrapMode: Text.Wrap
            }
        }

        // ── Desktop (XDG) autostart ──────────────────────────────────────
        ContentSection {
            icon: "restart_alt"
            shape: MaterialShape.Shape.Clover4Leaf
            title: Translation.tr("Desktop autostart")

            StyledText {
                Layout.leftMargin: 8
                Layout.fillWidth: true
                text: Translation.tr(".desktop entries from ~/.config/autostart and /etc/xdg/autostart, started by the session's xdg-autostart. Turning a system entry off writes a hidden copy into ~/.config/autostart; your own entries are deleted outright.")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: xdgAutostartCol.implicitHeight + 20
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1

                ColumnLayout {
                    id: xdgAutostartCol
                    anchors { fill: parent; margins: 10 }
                    spacing: 4

                    StyledText {
                        visible: SystemAutostart.xdgEntries.length === 0
                        Layout.leftMargin: 8
                        text: Translation.tr("No .desktop autostart entries")
                        color: Appearance.colors.colSubtext
                    }

                    Repeater {
                        model: SystemAutostart.xdgEntries
                        delegate: RowLayout {
                            id: xdgEntryRow
                            required property var modelData
                            // Entries limited to other desktops never run here,
                            // so a Hidden= flip would be a lie
                            readonly property bool togglable: xdgEntryRow.modelData.note === ""
                                || xdgEntryRow.modelData.note === "Hidden"
                            Layout.fillWidth: true
                            spacing: 10

                            StyledSwitch {
                                Layout.leftMargin: 4
                                enabled: xdgEntryRow.togglable
                                checked: xdgEntryRow.modelData.enabled
                                onClicked: SystemAutostart.setXdgEnabled(xdgEntryRow.modelData, checked)
                                StyledToolTip {
                                    text: xdgEntryRow.togglable
                                        ? Translation.tr("Start this app when the session starts")
                                        : xdgEntryRow.modelData.note
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                opacity: xdgEntryRow.modelData.enabled ? 1 : 0.5

                                StyledText {
                                    Layout.fillWidth: true
                                    text: xdgEntryRow.modelData.name
                                    elide: Text.ElideRight
                                    color: Appearance.colors.colOnSecondaryContainer
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: xdgEntryRow.modelData.note !== "" && !xdgEntryRow.togglable
                                        ? `${xdgEntryRow.modelData.command} • ${xdgEntryRow.modelData.note}`
                                        : xdgEntryRow.modelData.command
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle {
                                implicitWidth: xdgSourceBadge.implicitWidth + 16
                                implicitHeight: xdgSourceBadge.implicitHeight + 6
                                radius: height / 2
                                color: Appearance.colors.colLayer2
                                StyledText {
                                    id: xdgSourceBadge
                                    anchors.centerIn: parent
                                    text: xdgEntryRow.modelData.hasSystem ? Translation.tr("system") : Translation.tr("yours")
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                }
                                MouseArea {
                                    id: xdgSourceHoverArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                    StyledToolTip {
                                        extraVisibleCondition: false
                                        alternativeVisibleCondition: xdgSourceHoverArea.containsMouse
                                        text: xdgEntryRow.modelData.path
                                    }
                                }
                            }

                            RippleButton {
                                // A system entry can't be deleted — the switch
                                // already masks it, a delete button would just
                                // be the same action with a scarier label
                                visible: !xdgEntryRow.modelData.hasSystem
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                buttonRadius: width / 2
                                colBackground: ColorUtils.transparentize(Appearance.colors.colError, 0.85)
                                colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colError, 0.6)
                                colRipple: ColorUtils.transparentize(Appearance.colors.colError, 0.5)
                                onClicked: SystemAutostart.removeXdg(xdgEntryRow.modelData)
                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "delete"
                                    iconSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colError
                                }
                                StyledToolTip {
                                    text: Translation.tr("Delete %1").arg(xdgEntryRow.modelData.path)
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── App ID substitutions ─────────────────────────────────────────
        ContentSection {
            icon: "token"
            shape: MaterialShape.Shape.Pill
            title: Translation.tr("App ID substitutions")

            StyledText {
                Layout.leftMargin: 8
                Layout.fillWidth: true
                text: Translation.tr("Remap window app IDs for icon lookup in the bar and dock — useful when a window's app ID doesn't match its .desktop file or icon name (e.g. equibop → vesktop).")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: substitutionsCol.implicitHeight + 20
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1

                ColumnLayout {
                    id: substitutionsCol
                    anchors { fill: parent; margins: 10 }
                    spacing: 4

                    StyledText {
                        visible: (Config.options.apps.idSubstitutions ?? []).length === 0
                        Layout.leftMargin: 8
                        text: Translation.tr("No substitutions")
                        color: Appearance.colors.colSubtext
                    }

                    Repeater {
                        model: Config.options.apps.idSubstitutions
                        delegate: RowLayout {
                            id: subRow
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            spacing: 10

                            MaterialTextArea {
                                id: subFromArea
                                Layout.fillWidth: true
                                placeholderText: Translation.tr("App ID (e.g. equibop)")
                                text: subRow.modelData.from ?? ""
                                wrapMode: TextEdit.Wrap
                                font.pixelSize: Appearance.font.pixelSize.small

                                property bool ready: false
                                Component.onCompleted: ready = true
                                onTextChanged: {
                                    if (!ready) return
                                    subFromDebounce.restart()
                                }
                                Timer {
                                    id: subFromDebounce
                                    interval: 2000
                                    onTriggered: {
                                        if (subFromArea.text !== (subRow.modelData.from ?? ""))
                                            page.updateSubstitution(subRow.index, "from", subFromArea.text)
                                    }
                                }
                            }

                            MaterialSymbol {
                                text: "arrow_forward"
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colSubtext
                            }

                            MaterialTextArea {
                                id: subToArea
                                Layout.fillWidth: true
                                placeholderText: Translation.tr("Icon or app ID (e.g. vesktop)")
                                text: subRow.modelData.to ?? ""
                                wrapMode: TextEdit.Wrap
                                font.pixelSize: Appearance.font.pixelSize.small

                                property bool ready: false
                                Component.onCompleted: ready = true
                                onTextChanged: {
                                    if (!ready) return
                                    subToDebounce.restart()
                                }
                                Timer {
                                    id: subToDebounce
                                    interval: 2000
                                    onTriggered: {
                                        if (subToArea.text !== (subRow.modelData.to ?? ""))
                                            page.updateSubstitution(subRow.index, "to", subToArea.text)
                                    }
                                }
                            }

                            RippleButton {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                buttonRadius: width / 2
                                colBackground: ColorUtils.transparentize(Appearance.colors.colError, 0.85)
                                colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colError, 0.6)
                                colRipple: ColorUtils.transparentize(Appearance.colors.colError, 0.5)
                                onClicked: page.removeSubstitution(subRow.index)
                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "delete"
                                    iconSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colError
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                ToolbarPairedFab {
                    iconText: "add"
                    onClicked: page.addSubstitution()
                }
            }
        }

        // ── Clipboard ────────────────────────────────────────────────────
        ContentSection {
            icon: "content_paste"
            shape: MaterialShape.Shape.Clover4Leaf
            title: Translation.tr("Clipboard")

            GroupedList {
                ConfigSpinBox {
                    icon: "history"
                    text: Translation.tr("Max history entries")
                    value: Config.options.cliphist.maxEntries
                    from: 10
                    to: 10000
                    stepSize: 50
                    onValueChanged: {
                        Config.options.cliphist.maxEntries = value
                    }
                }

                RowLayout {
                    spacing: 10
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                    MaterialSymbol {
                        text: "info"
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colSubtext
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("The limit is a flag on the clipboard watcher command, e.g. %1 — it applies through your autostart entry, not live.")
                            .arg(`wl-paste --watch cliphist store -max-items ${Config.options.cliphist.maxEntries}`)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        wrapMode: Text.Wrap
                    }
                    RippleButtonWithIcon {
                        visible: NiriData.isNiri
                        materialIcon: "sync"
                        mainText: Translation.tr("Update autostart entry")
                        onClicked: page.applyCliphistToAutostart()
                        StyledToolTip {
                            text: Translation.tr("Add the cliphist watcher to autostart, or update its -max-items flag")
                        }
                    }
                }

                RowLayout {
                    id: wipeRow
                    property bool confirming: false
                    spacing: 10
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8

                    MaterialSymbol {
                        text: "delete_sweep"
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnSecondaryContainer
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("%1 entries in clipboard history").arg(Cliphist.entries.length)
                        color: Appearance.colors.colOnSecondaryContainer
                    }
                    RippleButtonWithIcon {
                        visible: !wipeRow.confirming
                        materialIcon: "delete_forever"
                        mainText: Translation.tr("Wipe history")
                        onClicked: wipeRow.confirming = true
                    }
                    DialogButton {
                        visible: wipeRow.confirming
                        buttonText: Translation.tr("Wipe it all?")
                        colText: Appearance.m3colors.m3error
                        onClicked: {
                            wipeRow.confirming = false
                            Cliphist.wipe()
                        }
                    }
                    DialogButton {
                        visible: wipeRow.confirming
                        buttonText: Translation.tr("Cancel")
                        onClicked: wipeRow.confirming = false
                    }
                }
            }
        }

        ContentSection {
            icon: "apps"
            shape: MaterialShape.Shape.Cookie6Sided
            title: Translation.tr("All Apps")

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Search installed apps")
                    text: page.appSearchQuery
                    onTextChanged: page.appSearchQuery = text
                }
                RippleButtonWithIcon {
                    materialIcon: "refresh"
                    mainText: Translation.tr("Refresh")
                    onClicked: AppInventory.refresh()
                }
            }

            StyledText {
                Layout.leftMargin: 8
                text: Translation.tr("%1 apps shown").arg(page.filteredApps.length)
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: allAppsColumn.implicitHeight + 20
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1

                ColumnLayout {
                    id: allAppsColumn
                    anchors { fill: parent; margins: 10 }
                    spacing: 4

                    Repeater {
                        model: page.filteredApps
                        delegate: Rectangle {
                            id: appRow
                            required property var modelData
                            required property int index
                            property bool confirmingUninstall: false
                            property bool confirmingClear: false
                            property bool permissionsExpanded: false

                            Layout.fillWidth: true
                            implicitHeight: appContent.implicitHeight + 16
                            radius: Appearance.rounding.small
                            color: index % 2 === 0 ? Appearance.colors.colLayer2 : "transparent"

                            ColumnLayout {
                                id: appContent
                                anchors { fill: parent; margins: 8 }
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    IconImage {
                                    source: Quickshell.iconPath(appRow.modelData.icon, "image-missing")
                                    implicitWidth: 36
                                    implicitHeight: 36
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: appRow.modelData.name
                                        color: Appearance.colors.colOnLayer1
                                        elide: Text.ElideRight
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: `${appRow.modelData.source === "flatpak" ? "Flatpak" : Translation.tr("System")} · ${appRow.modelData.size || appRow.modelData.id}`
                                        color: Appearance.colors.colSubtext
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        elide: Text.ElideRight
                                    }
                                }

                                RippleButtonWithIcon {
                                    materialIcon: "open_in_new"
                                    mainText: Translation.tr("Open")
                                    onClicked: AppInventory.open(appRow.modelData)
                                }

                                RippleButtonWithIcon {
                                    visible: appRow.modelData.source === "flatpak"
                                    materialIcon: "admin_panel_settings"
                                    mainText: Translation.tr("Permissions")
                                    onClicked: appRow.permissionsExpanded = !appRow.permissionsExpanded
                                }

                                RippleButtonWithIcon {
                                    visible: appRow.modelData.source === "flatpak" && !appRow.confirmingClear
                                    materialIcon: "delete_sweep"
                                    mainText: Translation.tr("Clear data")
                                    onClicked: appRow.confirmingClear = true
                                }
                                DialogButton {
                                    visible: appRow.confirmingClear
                                    buttonText: Translation.tr("Clear?")
                                    colText: Appearance.m3colors.m3error
                                    onClicked: {
                                        Quickshell.execDetached(["gio", "trash", `${FileUtils.trimFileProtocol(Directories.home)}/.var/app/${appRow.modelData.id}`])
                                        appRow.confirmingClear = false
                                    }
                                }

                                RippleButtonWithIcon {
                                    visible: !appRow.confirmingUninstall
                                    materialIcon: "delete"
                                    mainText: Translation.tr("Uninstall")
                                    onClicked: appRow.confirmingUninstall = true
                                }
                                DialogButton {
                                    visible: appRow.confirmingUninstall
                                    buttonText: Translation.tr("Uninstall?")
                                    colText: Appearance.m3colors.m3error
                                    onClicked: {
                                        AppInventory.uninstall(appRow.modelData)
                                        appRow.confirmingUninstall = false
                                    }
                                }
                                DialogButton {
                                    visible: appRow.confirmingUninstall || appRow.confirmingClear
                                    buttonText: Translation.tr("Cancel")
                                    onClicked: {
                                        appRow.confirmingUninstall = false
                                        appRow.confirmingClear = false
                                    }
                                }
                                }

                                RowLayout {
                                    visible: appRow.modelData.source === "flatpak" && appRow.permissionsExpanded
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 46
                                    spacing: 10

                                    MaterialSymbol {
                                        text: "notifications"
                                        iconSize: Appearance.font.pixelSize.larger
                                        color: Appearance.colors.colOnLayer1
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: Translation.tr("Notifications")
                                        color: Appearance.colors.colOnLayer1
                                    }
                                    StyledSwitch {
                                        checked: AppInventory.notificationPermission(appRow.modelData.id)
                                        onClicked: AppInventory.setNotificationPermission(appRow.modelData.id, checked)
                                        StyledToolTip {
                                            text: Translation.tr("Allow this app to send notifications")
                                        }
                                    }
                                    RippleButtonWithIcon {
                                        visible: AppInventory.flatsealInstalled
                                        materialIcon: "tune"
                                        mainText: Translation.tr("More")
                                        onClicked: AppInventory.openPermissions(appRow.modelData.id)
                                        StyledToolTip {
                                            text: Translation.tr("Open microphone, camera, filesystem, and other permissions in Flatseal")
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
}
