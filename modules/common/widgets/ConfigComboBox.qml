import qs.modules.common.widgets
import qs.modules.common
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

RowLayout {
    id: root

    property string text: ""
    property string description: ""
    property string buttonIcon: ""
    property var model: []
    property string textRole: "displayName"
    property var currentValue: undefined
    property bool searchable: false
    property bool previewFont: false

    property real fieldWidth: 220

    property alias comboBox: comboLoader.item

    signal selected(var newValue)

    spacing: 10
    Layout.leftMargin: 8
    Layout.rightMargin: 8

    OptionalMaterialSymbol {
        icon: root.buttonIcon
        iconSize: Appearance.font.pixelSize.larger
        opacity: root.enabled ? 1 : 0.4
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        StyledText {
            Layout.fillWidth: true
            text: root.text
            color: Appearance.colors.colOnSecondaryContainer
            opacity: root.enabled ? 1 : 0.4
        }
        StyledText {
            Layout.fillWidth: true
            visible: root.description.length > 0
            text: root.description
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
            opacity: root.enabled ? 1 : 0.4
        }
    }

    Loader {
        id: comboLoader
        Layout.fillWidth: false
        Layout.preferredWidth: root.fieldWidth
        Layout.alignment: Qt.AlignVCenter
        sourceComponent: root.searchable ? searchComboComponent : regularComboComponent
    }

    Component {
        id: regularComboComponent
        StyledComboBox {
            enabled: root.enabled
            textRole: root.textRole
            model: root.model

            currentIndex: {
                if (!root.model) return 0;
                const index = root.model.findIndex(item => {
                    if (typeof item === "object" && item !== null) {
                        return item.value === root.currentValue;
                    }
                    return item === root.currentValue;
                });
                return index !== -1 ? index : 0;
            }

            onActivated: index => {
                const item = model[index];
                const val = (typeof item === "object" && item !== null && item.value !== undefined) ? item.value : item;
                root.selected(val);
            }
        }
    }

    Component {
        id: searchComboComponent
        StyledComboBoxSearch {
            enabled: root.enabled
            textRole: root.textRole
            model: root.model
            previewFont: root.previewFont

            currentIndex: {
                if (!root.model) return 0;
                const index = root.model.findIndex(item => {
                    if (typeof item === "object" && item !== null) {
                        return item.value === root.currentValue;
                    }
                    return item === root.currentValue;
                });
                return index !== -1 ? index : 0;
            }

            onActivated: index => {
                const item = model[index];
                const val = (typeof item === "object" && item !== null && item.value !== undefined) ? item.value : item;
                root.selected(val);
            }
        }
    }
}