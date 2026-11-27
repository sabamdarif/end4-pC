pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import "../../../../../services/NiriShortcuts.js" as Shortcuts

Dialog {
    id: root
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(680, parent.width - 32)
    height: Math.min(780, parent.height - 32)
    modal: true
    padding: 24
    closePolicy: NiriConfig.savingBind ? Popup.NoAutoClose : Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property var group: null
    property int keyIndex: -1
    property string originalKey: ""
    property string originalAction: ""
    property string initialCommand: ""
    property string initialType: ""
    property string actionType: "shell-action"
    property string savingAction: ""
    property var bindProperties: ({})
    property bool recording: false
    readonly property var currentKey: root.group?.keys[root.keyIndex] ?? null
    readonly property bool hasChanges: root.originalKey === "" || keyField.text !== root.originalKey ||
        actionField.text !== root.initialCommand || root.actionType !== root.initialType ||
        titleField.text !== (root.currentKey?.title ?? root.group?.title ?? "") ||
        JSON.stringify(root.bindProperties) !== JSON.stringify(root.currentKey?.properties ?? {})
    readonly property var conflicts: NiriKeybinds.binds.filter(b =>
        Shortcuts.normalizeKey(b.key, NiriKeybinds.modKey) === Shortcuts.normalizeKey(keyField.text, NiriKeybinds.modKey) &&
        Shortcuts.normalizeKey(b.key, NiriKeybinds.modKey) !== Shortcuts.normalizeKey(root.originalKey, NiriKeybinds.modKey))
    readonly property var actionTypes: [
        { value: "shell-action", title: Translation.tr("Shell actions"), icon: "widgets" },
        { value: "compositor", title: Translation.tr("Compositor"), icon: "select_window" },
        { value: "command", title: Translation.tr("Command"), icon: "apps" },
        { value: "shell", title: Translation.tr("Shell"), icon: "terminal" }
    ]
    readonly property var shellActions: [
        { displayName: Translation.tr("Launcher"), target: "search" },
        { displayName: Translation.tr("Clipboard"), target: "clipboard" },
        { displayName: Translation.tr("Settings"), target: "settings" },
        { displayName: Translation.tr("Quick settings"), target: "sidebarRight" },
        { displayName: Translation.tr("Wallpaper selector"), target: "wallpaperSelector" },
        { displayName: Translation.tr("Media controls"), target: "mediaControls" },
        { displayName: Translation.tr("Session menu"), target: "session" },
        { displayName: Translation.tr("Lock screen"), target: "lock", action: "activate" },
        { displayName: Translation.tr("Screenshot"), target: "region", action: "screenshot" },
        { displayName: Translation.tr("Area screenshot"), target: "region", action: "areaScreenshot" },
        { displayName: Translation.tr("Play/pause media"), target: "mpris", action: "playPause" },
        { displayName: Translation.tr("Next track"), target: "mpris", action: "next" },
        { displayName: Translation.tr("Previous track"), target: "mpris", action: "previous" }
    ].map(a => ({ displayName: a.displayName, value: root.ipcAction(a.target, a.action || "toggle"), icon: "" }))
    readonly property var compositorActions: NiriKeybinds.compositorActions
    readonly property var options: [
        { key: "repeat", title: Translation.tr("Repeat"), defaultValue: true },
        { key: "allow-when-locked", title: Translation.tr("When locked"), defaultValue: false },
        { key: "allow-inhibiting", title: Translation.tr("Inhibitable"), defaultValue: true }
    ]
    signal saved(string action)

    function ipcAction(target, action) {
        return "spawn " + ["qs", "-p", Quickshell.shellPath("."), "ipc", "call", target, action].map(a => JSON.stringify(a)).join(" ")
    }

    function present(group, index) {
        root.group = group
        root.loadKey(index)
        NiriConfig.bindError = ""
        root.open()
        keyField.forceActiveFocus()
    }

    function loadKey(index) {
        root.recording = false
        root.keyIndex = index
        const key = root.group?.keys[index] ?? null
        root.originalKey = key?.key ?? ""
        root.originalAction = root.group?.action ?? root.shellActions[0].value
        const form = Shortcuts.actionForm(root.originalAction)
        root.actionType = form.type
        root.initialType = form.type
        root.initialCommand = form.text
        keyField.text = root.originalKey
        actionField.text = form.text
        titleField.text = key?.title ?? root.group?.title ?? ""
        root.bindProperties = Object.assign({}, key?.properties ?? {})
        formScroll.contentY = 0
    }

    function newKey() {
        root.recording = false
        root.originalKey = ""
        root.keyIndex = -1
        keyField.text = ""
        keyField.forceActiveFocus()
    }

    function selectType(type) {
        if (root.actionType === type) return
        root.actionType = type
        actionField.text = type === "shell-action" ? root.shellActions[0].value
            : type === "compositor" ? "close-window" : ""
    }

    function presetIndex(model) {
        const text = actionField.text.trim()
        const tokens = Shortcuts.spawnTokens(text)
        return Math.max(0, model.findIndex(a => {
            if (!a.value) return false
            if (root.actionType === "compositor") return a.value.split(/\s+/)[0] === text.split(/\s+/)[0]
            const preset = Shortcuts.spawnTokens(a.value)
            return tokens && preset && tokens.slice(-2).join(" ") === preset.slice(-2).join(" ")
        }))
    }

    function setProperty(name, value) {
        const properties = Object.assign({}, root.bindProperties)
        if (value === undefined) delete properties[name]
        else properties[name] = value
        root.bindProperties = properties
    }

    function save() {
        if (NiriConfig.savingBind || !keyField.text.trim() || !actionField.text.trim()) return
        root.recording = false
        const unchanged = root.actionType === root.initialType && actionField.text === root.initialCommand
        const action = unchanged ? root.originalAction : root.actionType === "shell"
            ? Shortcuts.shellAction(actionField.text) : root.actionType === "command"
            ? Shortcuts.commandAction(actionField.text) : actionField.text.trim()
        root.savingAction = action
        NiriConfig.saveBindOverride(root.originalKey, {
            key: keyField.text.trim(), action: action, title: titleField.text.trim(), properties: root.bindProperties
        }, NiriKeybinds.modKey)
    }

    onClosed: root.recording = false
    Connections {
        target: NiriConfig
        function onBindSaveCompleted(success) {
            if (!root.visible || !success) return
            if (resetConfirm.visible) resetConfirm.close()
            root.saved(root.savingAction || root.originalAction)
            root.close()
        }
    }

    ShortcutInhibitor {
        window: keyField.QsWindow.window
        enabled: root.visible && root.recording
    }
    background: Rectangle { color: Appearance.colors.colLayer1; radius: Appearance.rounding.large }
    contentItem: ColumnLayout {
        spacing: 16
        StyledText {
            Layout.fillWidth: true
            text: root.group ? Translation.tr("Edit shortcut") : Translation.tr("Add shortcut")
            font.pixelSize: Appearance.font.pixelSize.larger
            font.weight: Font.Medium
        }
        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("Changes save to %1").arg(NiriConfig.bindsKdlPath)
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }
        StyledFlickable {
            id: formScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: form.implicitHeight
            ColumnLayout {
                id: form
                width: formScroll.width
                spacing: 16
                ContentSection {
                    title: Translation.tr("Key")
                    icon: "keyboard"
                    Flow {
                        Layout.fillWidth: true
                        visible: !!root.group
                        spacing: 6
                        Repeater {
                            model: root.group?.keys ?? []
                            delegate: DialogButton {
                                required property var modelData
                                required property int index
                                buttonText: modelData.key
                                colBackground: root.keyIndex === index ? Appearance.colors.colSecondaryContainer : "transparent"
                                onClicked: root.loadKey(index)
                            }
                        }
                        DialogButton { buttonText: Translation.tr("New key"); onClicked: root.newKey() }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        MaterialTextField {
                            id: keyField
                            Layout.fillWidth: true
                            placeholderText: root.recording ? Translation.tr("Press a shortcut…") : Translation.tr("Key combo (e.g. Mod+Shift+T)")
                            readOnly: root.recording
                            Keys.onPressed: event => {
                                if (!root.recording) return
                                event.accepted = true
                                if (event.key === Qt.Key_Escape) { root.recording = false; return }
                                const combo = Shortcuts.eventCombo(event, NiriKeybinds.modKey)
                                if (!combo) return
                                text = combo
                                root.recording = false
                            }
                            onActiveFocusChanged: if (!activeFocus) root.recording = false
                        }
                        RippleButtonWithIcon {
                            materialIcon: "keyboard"
                            mainText: root.recording ? Translation.tr("Cancel") : Translation.tr("Capture")
                            onClicked: {
                                root.recording = !root.recording
                                if (root.recording) keyField.forceActiveFocus()
                            }
                        }
                    }
                    StyledText {
                        Layout.fillWidth: true
                        visible: root.recording
                        text: Translation.tr("Press your shortcut. Esc cancels. Other XKB key names can be typed manually.")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        wrapMode: Text.Wrap
                    }
                    StyledText {
                        Layout.fillWidth: true
                        visible: root.conflicts.length > 0
                        text: Translation.tr("Conflicts with: %1").arg(root.conflicts.map(b => b.title).join(", "))
                        color: Appearance.m3colors.m3error
                        wrapMode: Text.Wrap
                    }
                    StyledText {
                        Layout.fillWidth: true
                        visible: root.currentKey?.conflict ?? false
                        text: Translation.tr("Shadows \"%1\" from %2").arg(root.currentKey?.shadowedTitle ?? "").arg(root.currentKey?.shadowedSource ?? "")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        wrapMode: Text.Wrap
                    }
                    StyledText {
                        Layout.fillWidth: true
                        visible: root.originalKey !== "" && Shortcuts.normalizeKey(keyField.text, NiriKeybinds.modKey) !== Shortcuts.normalizeKey(root.originalKey, NiriKeybinds.modKey)
                        text: Translation.tr("Changing the key moves your override. Any original shortcut in your own config remains unchanged.")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        wrapMode: Text.Wrap
                    }
                }
                ContentSection {
                    title: Translation.tr("Action")
                    icon: "bolt"
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Repeater {
                            model: root.actionTypes
                            delegate: RippleButtonWithIcon {
                                required property var modelData
                                Layout.fillWidth: true
                                mainText: root.width > 580 ? modelData.title : ""
                                materialIcon: modelData.icon
                                colBackground: root.actionType === modelData.value ? Appearance.colors.colSecondaryContainer : Appearance.colors.colLayer2
                                Accessible.name: modelData.title
                                onClicked: root.selectType(modelData.value)
                                StyledToolTip { text: modelData.title }
                            }
                        }
                    }
                    StyledComboBoxSearch {
                        Layout.fillWidth: true
                        visible: root.actionType === "shell-action" || root.actionType === "compositor"
                        textRole: "displayName"
                        model: [{ displayName: Translation.tr("Custom"), value: "", icon: "" }].concat(root.actionType === "shell-action" ? root.shellActions : root.compositorActions)
                        currentIndex: root.presetIndex(model)
                        onActivated: index => {
                            const action = model[index]
                            if (!action.value) return
                            actionField.text = action.value
                            if (!titleField.text.trim()) titleField.text = action.displayName
                        }
                    }
                    StyledComboBoxSearch {
                        Layout.fillWidth: true
                        visible: root.actionType === "command"
                        textRole: "displayName"
                        model: [{ displayName: Translation.tr("Pick an application…"), value: "", icon: "" }].concat(
                            AppService.list.filter(a => !a.noDisplay).map(a => ({ displayName: a.name, value: a.id, icon: "" }))
                                .sort((a, b) => a.displayName.localeCompare(b.displayName)))
                        onActivated: index => {
                            const entry = DesktopEntries.byId(model[index].value)
                            if (!entry) return
                            actionField.text = String(entry.execString || entry.id).replace(/%[a-zA-Z]/g, "").trim()
                            if (!titleField.text.trim()) titleField.text = entry.name
                        }
                    }
                    MaterialTextField {
                        id: actionField
                        Layout.fillWidth: true
                        placeholderText: root.actionType === "shell" ? Translation.tr("Shell command, e.g. notify-send 'Hello'")
                            : root.actionType === "command" ? Translation.tr("Command and arguments, e.g. kitty -e btop")
                            : Translation.tr("Niri action, e.g. focus-workspace 2")
                    }
                    MaterialTextField { id: titleField; Layout.fillWidth: true; placeholderText: Translation.tr("Hotkey overlay title (optional)") }
                }
                ContentSection {
                    title: Translation.tr("Options")
                    icon: "tune"
                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        Repeater {
                            model: root.options
                            delegate: DialogButton {
                                id: option
                                required property var modelData
                                readonly property bool selected: root.bindProperties[modelData.key] ?? modelData.defaultValue
                                buttonText: (selected ? "✓ " : "") + modelData.title
                                colBackground: selected ? Appearance.colors.colSecondaryContainer : "transparent"
                                onClicked: root.setProperty(modelData.key, !selected === modelData.defaultValue ? undefined : !selected)
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        StyledText { Layout.fillWidth: true; text: Translation.tr("Cooldown (ms)") }
                        StyledSpinBox {
                            from: 0
                            to: 2147483647
                            value: root.bindProperties["cooldown-ms"] ?? 0
                            onValueModified: root.setProperty("cooldown-ms", value === 0 ? undefined : value)
                        }
                    }
                }
                StyledText {
                    Layout.fillWidth: true
                    visible: NiriConfig.bindError !== ""
                    text: NiriConfig.bindError
                    wrapMode: Text.Wrap
                    color: Appearance.m3colors.m3error
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            DialogButton {
                visible: root.currentKey?.isOverride ?? false
                buttonText: Translation.tr("Reset override")
                enabled: !NiriConfig.savingBind
                onClicked: resetConfirm.open()
            }
            Item { Layout.fillWidth: true }
            DialogButton { buttonText: Translation.tr("Cancel"); enabled: !NiriConfig.savingBind; onClicked: root.close() }
            DialogButton {
                buttonText: NiriConfig.savingBind ? Translation.tr("Saving…") : root.group ? Translation.tr("Save") : Translation.tr("Add")
                enabled: NiriConfig.ready && root.hasChanges && !NiriConfig.savingBind && keyField.text.trim() !== "" && actionField.text.trim() !== ""
                onClicked: root.save()
            }
        }
    }
    Dialog {
        id: resetConfirm
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(440, parent.width - 32)
        modal: true
        padding: 24
        closePolicy: NiriConfig.savingBind ? Popup.NoAutoClose : Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { color: Appearance.colors.colLayer1; radius: Appearance.rounding.large }
        contentItem: ColumnLayout {
            spacing: 16
            StyledText { text: Translation.tr("Reset override?"); font.pixelSize: Appearance.font.pixelSize.larger }
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Remove your override for %1 and restore the shortcut from your original config?").arg(root.originalKey)
                wrapMode: Text.Wrap
            }
            StyledText { Layout.fillWidth: true; visible: NiriConfig.bindError !== ""; text: NiriConfig.bindError; wrapMode: Text.Wrap; color: Appearance.m3colors.m3error }
            RowLayout {
                Item { Layout.fillWidth: true }
                DialogButton { buttonText: Translation.tr("Cancel"); enabled: !NiriConfig.savingBind; onClicked: resetConfirm.close() }
                DialogButton {
                    buttonText: Translation.tr("Reset")
                    enabled: !NiriConfig.savingBind
                    onClicked: NiriConfig.removeBindOverride(root.originalKey, NiriKeybinds.modKey)
                }
            }
        }
    }
}
