import QtQuick
import QtQuick.Layouts
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
            visible: NiriConfig.options.windowRules.length === 0
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
}
