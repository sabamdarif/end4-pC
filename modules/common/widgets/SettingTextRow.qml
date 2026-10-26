import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

SettingRow {
    id: root

    property alias text: textInput.text
    property alias placeholderText: textInput.placeholderText
    signal textModified(string val)

    currentValue: textInput.text

    onResetRequested: {
        if (defaultValue !== undefined) {
            textInput.text = String(defaultValue)
            root.textModified(textInput.text)
        }
    }

    Rectangle {
        radius: Appearance.rounding.small
        color: Appearance.colors.colLayer2
        Layout.preferredWidth: 200
        Layout.preferredHeight: 36
        Layout.alignment: Qt.AlignVCenter

        StyledTextInput {
            id: textInput
            anchors.fill: parent
            anchors.margins: 6
            color: Appearance.colors.colOnLayer2
            font.pixelSize: Appearance.font.pixelSize.smaller
            onEditingFinished: root.textModified(text)
        }
    }
}
