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

    function defaultAppModel(key) {
        const cands = (DefaultApps.candidates[key] ?? []).slice()
        const cur = DefaultApps.current[key] ?? ""
        if (cur !== "" && !cands.includes(cur)) cands.unshift(cur)
        const items = cands.map(id => ({ displayName: DefaultApps.displayName(id), value: id }))
        items.sort((a, b) => a.displayName.localeCompare(b.displayName))
        if (cur === "") items.unshift({ displayName: Translation.tr("Not set"), value: "" })
        return items
    }

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
}
