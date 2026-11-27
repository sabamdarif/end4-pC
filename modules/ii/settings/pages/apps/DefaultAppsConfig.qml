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

    readonly property var terminalOptions: {
        const current = Config.options.apps.terminal ?? ""
        const options = AppService.list
            .filter(entry => !entry.noDisplay && Array.from(entry.categories ?? []).includes("TerminalEmulator"))
            .map(entry => ({ displayName: entry.name, value: (entry.command ?? [])[0] ?? "" }))
            .filter(option => option.value !== "")
        if (current !== "" && !options.some(option => option.value === current))
            options.push({ displayName: current, value: current })
        options.sort((a, b) => a.displayName.localeCompare(b.displayName))
        return options
    }

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

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Repeater {
                model: page.defaultAppRoles
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool isFirst: index === 0
                    readonly property bool isLast: index === page.defaultAppRoles.length - 1

                    Layout.fillWidth: true
                    implicitHeight: Math.max(64, roleCombo.implicitHeight + 24)
                    color: Appearance.colors.colLayer1
                    topLeftRadius: isFirst ? Appearance.rounding.normal : Appearance.rounding.unsharpenmore
                    topRightRadius: topLeftRadius
                    bottomLeftRadius: isLast ? Appearance.rounding.normal : Appearance.rounding.unsharpenmore
                    bottomRightRadius: bottomLeftRadius

                    ConfigComboBox {
                        id: roleCombo
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 16
                            rightMargin: 16
                        }
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
            ConfigComboBox {
                Layout.fillWidth: true
                buttonIcon: "terminal"
                text: Translation.tr("Terminal")
                description: Translation.tr("Used by shell actions (not an xdg default)")
                model: page.terminalOptions
                currentValue: Config.options.apps.terminal
                onSelected: newValue => {
                    if (newValue !== "" && newValue !== Config.options.apps.terminal)
                        Config.options.apps.terminal = newValue
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
