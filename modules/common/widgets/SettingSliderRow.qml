import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

SettingRow {
    id: root

    property alias from: slider.from
    property alias to: slider.to
    property alias stepSize: slider.stepSize
    property alias value: slider.value
    property real multiplier: 1.0
    signal valueModified(real val)

    currentValue: slider.value

    onResetRequested: {
        if (defaultValue !== undefined) {
            slider.value = Number(defaultValue)
            root.valueModified(slider.value)
        }
    }

    RowLayout {
        spacing: 12
        Layout.alignment: Qt.AlignVCenter

        StyledSlider {
            id: slider
            Layout.preferredWidth: 160
            Layout.alignment: Qt.AlignVCenter
            onMoved: root.valueModified(value)
        }

        StyledText {
            Layout.preferredWidth: 50
            horizontalAlignment: Text.AlignRight
            text: `${Math.round(slider.value * root.multiplier)}${root.unit !== "" ? " " + root.unit : ""}`
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.family: Appearance.font.family.numbers
            color: Appearance.colors.colOnLayer1
        }
    }
}
