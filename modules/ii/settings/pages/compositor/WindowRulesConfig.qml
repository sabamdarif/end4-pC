import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: root

    function openPendingRule() {
        if (!NiriConfig.pendingWindowRule || !editorLoader.item) return;
        const window = NiriConfig.pendingWindowRule;
        NiriConfig.pendingWindowRule = null;
        editorLoader.item.edit(-1, null, window);
    }
    Loader {
        id: editorLoader
        source: Qt.resolvedUrl("WindowRuleEditorDialog.qml")
        onLoaded: root.openPendingRule()
    }
    Connections {
        target: NiriConfig
        function onPendingWindowRuleChanged() { root.openPendingRule(); }
    }
    ContentSection {
        icon: "splitscreen"
        title: Translation.tr("Window rules")
        NiriIncludeNotice {}
        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("Match app IDs and titles with regular expressions. Opening rules apply to new windows; other properties update existing windows.")
            wrapMode: Text.Wrap
        }
        RippleButtonWithIcon {
            materialIcon: "add"
            mainText: Translation.tr("Add rule")
            onClicked: editorLoader.item.edit(-1, null, null)
        }
        StyledText {
            visible: NiriConfig.options.windowRules.length === 0 && NiriConfig.externalWindowRules.length === 0
            text: Translation.tr("No window rules yet")
        }
        Repeater {
            model: NiriConfig.options.windowRules
            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                property bool confirmingDelete: false
                Layout.fillWidth: true
                implicitHeight: rowLayout.implicitHeight + 20
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                RowLayout {
                    id: rowLayout
                    anchors { fill: parent; margins: 10 }
                    ConfigSwitch {
                        Layout.fillWidth: true
                        text: row.modelData.name || row.modelData.match?.appId || row.modelData.match?.title || Translation.tr("Window rule")
                        checked: row.modelData.enabled !== false
                        enabled: !NiriConfig.validatingWindowRule
                        onCheckedChanged: {
                            if (checked === (row.modelData.enabled !== false)) return;
                            NiriConfig.saveWindowRule(row.index, Object.assign({}, row.modelData, { enabled: checked }));
                        }
                    }
                    RippleButtonWithIcon {
                        materialIcon: "edit"
                        mainText: ""
                        enabled: !NiriConfig.validatingWindowRule
                        onClicked: editorLoader.item.edit(row.index, row.modelData, null)
                        StyledToolTip { text: Translation.tr("Edit rule") }
                    }
                    RippleButtonWithIcon {
                        visible: !row.confirmingDelete
                        materialIcon: "delete"
                        mainText: ""
                        onClicked: row.confirmingDelete = true
                        StyledToolTip { text: Translation.tr("Delete rule") }
                    }
                    DialogButton {
                        visible: row.confirmingDelete
                        enabled: !NiriConfig.validatingWindowRule
                        buttonText: Translation.tr("Delete?")
                        onClicked: {
                            const rules = Array.from(NiriConfig.options.windowRules);
                            rules.splice(row.index, 1);
                            NiriConfig.options.windowRules = rules;
                        }
                    }
                    DialogButton {
                        visible: row.confirmingDelete
                        buttonText: Translation.tr("Cancel")
                        onClicked: row.confirmingDelete = false
                    }
                }
            }
        }
        StyledText {
            Layout.fillWidth: true
            visible: NiriConfig.windowRuleError !== ""
            text: NiriConfig.windowRuleError
            wrapMode: Text.Wrap
            color: Appearance.m3colors.m3error
        }
    }

    ContentSection {
        icon: "description"
        title: Translation.tr("From your niri config")
        visible: NiriConfig.externalWindowRules.length > 0
        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("These rules are read from config.kdl and its included files. Open the source file to edit them without losing advanced matchers or properties.")
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }
        Repeater {
            model: NiriConfig.externalWindowRules
            delegate: Rectangle {
                id: externalRow
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: externalContent.implicitHeight + 24
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                ColumnLayout {
                    id: externalContent
                    anchors { fill: parent; margins: 12 }
                    spacing: 8
                    RowLayout {
                        Layout.fillWidth: true
                        StyledText {
                            Layout.fillWidth: true
                            text: externalRow.modelData.source
                            textFormat: Text.PlainText
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            elide: Text.ElideMiddle
                        }
                        RippleButtonWithIcon {
                            materialIcon: "edit_document"
                            mainText: Translation.tr("Edit source")
                            onClicked: Quickshell.execDetached(["xdg-open", externalRow.modelData.source])
                        }
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: externalRow.modelData.kdl
                        textFormat: Text.PlainText
                        font.family: Appearance.font.family.monospace
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        wrapMode: Text.WrapAnywhere
                    }
                }
            }
        }
    }
}
