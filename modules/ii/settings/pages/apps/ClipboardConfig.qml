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
}
