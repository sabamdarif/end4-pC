import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ContentPage {
    id: page
    forceWidth: true

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

    function execOf(entry) {
        let cmd = String(entry?.execString ?? "").replace(/%[a-zA-Z]/g, "").trim()
        if (cmd === "") cmd = entry?.id ?? ""
        return cmd
    }

    ContentSection {
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
}
