import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Dialog {
    id: root
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(700, parent.width - 32)
    height: Math.min(740, parent.height - 32)
    modal: true
    padding: 24
    property int ruleIndex: -1
    property var draft: ({ match: {}, properties: {} })

    function exact(value) { return "^" + String(value).replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "$"; }
    function pickWindow(window) {
        if (!window) return;
        appId.text = window.app_id ? root.exact(window.app_id) : "";
        windowTitle.text = window.title ? root.exact(window.title) : "";
    }
    function edit(index, rule, window) {
        root.ruleIndex = index;
        root.draft = rule ? JSON.parse(JSON.stringify(rule)) : { enabled: true, match: {}, properties: {} };
        name.text = root.draft.name || "";
        appId.text = root.draft.match?.appId || "";
        windowTitle.text = root.draft.match?.title || "";
        if (window) {
            appId.text = window.app_id ? root.exact(window.app_id) : "";
            windowTitle.text = "";
        }
        NiriConfig.windowRuleError = "";
        root.open();
    }
    function update(section, key, value) {
        const draft = JSON.parse(JSON.stringify(root.draft));
        draft[section] = draft[section] || {};
        if (value === null) delete draft[section][key];
        else draft[section][key] = value;
        root.draft = draft;
    }
    function save() {
        const draft = JSON.parse(JSON.stringify(root.draft));
        draft.name = name.text.trim();
        draft.match = draft.match || {};
        draft.match.appId = appId.text;
        draft.match.title = windowTitle.text;
        NiriConfig.saveWindowRule(root.ruleIndex, draft);
    }
    Connections {
        target: NiriConfig
        function onWindowRuleSaved() { if (root.visible) root.close(); }
    }
    background: Rectangle { color: Appearance.colors.colLayer1; radius: Appearance.rounding.large }

    component BooleanField: ConfigComboBox {
        required property string section
        required property string fieldKey
        currentValue: root.draft[section]?.[fieldKey] ?? null
        model: [
            { displayName: Translation.tr("Default / any"), value: null },
            { displayName: Translation.tr("Yes"), value: true },
            { displayName: Translation.tr("No"), value: false }
        ]
        onSelected: value => root.update(section, fieldKey, value)
    }
    component NumberField: RowLayout {
        id: numberField
        required property string fieldKey
        required property string label
        property int minimum: 0
        property int maximum: 100
        property int defaultValue: 100
        ConfigSwitch {
            Layout.fillWidth: true
            text: numberField.label
            checked: root.draft.properties?.[numberField.fieldKey] !== undefined
            onCheckedChanged: {
                if (checked === (root.draft.properties?.[numberField.fieldKey] !== undefined)) return;
                root.update("properties", numberField.fieldKey, checked ? numberField.defaultValue / 100 : null);
            }
        }
        StyledSpinBox {
            enabled: root.draft.properties?.[numberField.fieldKey] !== undefined
            from: numberField.minimum
            to: numberField.maximum
            value: Math.round((root.draft.properties?.[numberField.fieldKey] ?? numberField.defaultValue / 100) * 100)
            onValueModified: root.update("properties", numberField.fieldKey, value / 100)
        }
    }
    contentItem: ColumnLayout {
        spacing: 16
        StyledText {
            text: root.ruleIndex < 0 ? Translation.tr("Add window rule") : Translation.tr("Edit window rule")
            font.pixelSize: Appearance.font.pixelSize.larger
        }
        StyledFlickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: form.implicitHeight
            ColumnLayout {
                id: form
                width: parent.width
                spacing: 12
                MaterialTextField { id: name; Layout.fillWidth: true; placeholderText: Translation.tr("Rule name (optional)") }
                ConfigComboBox {
                    Layout.fillWidth: true
                    text: Translation.tr("Pick a running window")
                    model: [{ displayName: Translation.tr("Custom match"), value: -1 }].concat(
                        NiriData.windows.map(w => ({ displayName: (w.app_id || "") + ": " + (w.title || ""), value: w.id })))
                    onSelected: value => root.pickWindow(NiriData.windows.find(w => w.id === value))
                }
                MaterialTextField { id: appId; Layout.fillWidth: true; placeholderText: Translation.tr("App ID regular expression") }
                MaterialTextField { id: windowTitle; Layout.fillWidth: true; placeholderText: Translation.tr("Title regular expression (optional)") }
                BooleanField { Layout.fillWidth: true; text: Translation.tr("Match floating"); section: "match"; fieldKey: "isFloating" }
                BooleanField { Layout.fillWidth: true; text: Translation.tr("Match focused"); section: "match"; fieldKey: "isFocused" }
                BooleanField { Layout.fillWidth: true; text: Translation.tr("Open floating"); section: "properties"; fieldKey: "openFloating" }
                BooleanField { Layout.fillWidth: true; text: Translation.tr("Open maximized"); section: "properties"; fieldKey: "openMaximized" }
                BooleanField { Layout.fillWidth: true; text: Translation.tr("Open fullscreen"); section: "properties"; fieldKey: "openFullscreen" }
                BooleanField { Layout.fillWidth: true; text: Translation.tr("Clip to geometry"); section: "properties"; fieldKey: "clipToGeometry" }
                NumberField { Layout.fillWidth: true; label: Translation.tr("Opacity (%)"); fieldKey: "opacity" }
                NumberField { Layout.fillWidth: true; label: Translation.tr("Column width (%)"); fieldKey: "columnWidth"; minimum: 1; defaultValue: 50 }
                NumberField { Layout.fillWidth: true; label: Translation.tr("Scroll factor (%)"); fieldKey: "scrollFactor"; minimum: 1; maximum: 10000 }
                ConfigComboBox {
                    Layout.fillWidth: true
                    text: Translation.tr("Block capture")
                    currentValue: root.draft.properties?.blockOutFrom || ""
                    model: [{ displayName: Translation.tr("Default"), value: "" },
                        { displayName: Translation.tr("Screencasts"), value: "screencast" },
                        { displayName: Translation.tr("All screen capture"), value: "screen-capture" }]
                    onSelected: value => root.update("properties", "blockOutFrom", value)
                }
                StyledText {
                    Layout.fillWidth: true
                    visible: NiriConfig.windowRuleError !== ""
                    text: NiriConfig.windowRuleError
                    color: Appearance.m3colors.m3error
                    wrapMode: Text.Wrap
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }
            DialogButton { buttonText: Translation.tr("Cancel"); enabled: !NiriConfig.validatingWindowRule; onClicked: root.close() }
            DialogButton {
                buttonText: NiriConfig.validatingWindowRule ? Translation.tr("Validating…") : Translation.tr("Save")
                enabled: !NiriConfig.validatingWindowRule
                onClicked: root.save()
            }
        }
    }
}
