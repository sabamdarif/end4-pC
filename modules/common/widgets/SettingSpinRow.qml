import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

SettingRow {
    id: root

    property alias from: spinBox.from
    property alias to: spinBox.to
    property alias stepSize: spinBox.stepSize
    property alias value: spinBox.value
    signal valueModified(int val)

    currentValue: spinBox.value

    onResetRequested: {
        if (defaultValue !== undefined) {
            spinBox.value = Number(defaultValue)
            root.valueModified(spinBox.value)
        }
    }

    RowLayout {
        spacing: 6
        Layout.alignment: Qt.AlignVCenter

        StyledSpinBox {
            id: spinBox
            Layout.alignment: Qt.AlignVCenter
            onValueModified: root.valueModified(value)
        }

        StyledText {
            visible: root.unit !== ""
            text: root.unit
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
        }
    }
}
