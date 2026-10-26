import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

SettingRow {
    id: root

    property alias model: comboBox.model
    property alias options: comboBox.model
    property alias textRole: comboBox.textRole
    property alias currentIndex: comboBox.currentIndex
    property alias currentText: comboBox.currentText
    property alias value: root.currentValue
    signal selected(var val)

    textRole: "displayName"

    onResetRequested: {
        if (defaultValue !== undefined) {
            root.currentValue = defaultValue
            root.selected(defaultValue)
        }
    }

    StyledComboBox {
        id: comboBox
        Layout.preferredWidth: 200
        Layout.alignment: Qt.AlignVCenter
        textRole: "displayName"

        currentIndex: {
            if (!Array.isArray(model)) return 0
            const idx = model.findIndex(item => item && (item.value === root.currentValue || item === root.currentValue))
            return idx !== -1 ? idx : 0
        }

        onActivated: index => {
            let item = model[index]
            let val = (item && typeof item === "object" && "value" in item) ? item.value : item
            root.currentValue = val
            root.selected(val)
        }
    }
}
