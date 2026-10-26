import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

SettingRow {
    id: root

    property alias checked: switchControl.checked
    signal toggled(bool checked)

    currentValue: switchControl.checked

    onResetRequested: {
        if (defaultValue !== undefined) {
            checked = Boolean(defaultValue)
            toggled(checked)
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !root.isWip
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            switchControl.checked = !switchControl.checked
            root.toggled(switchControl.checked)
        }
    }

    StyledSwitch {
        id: switchControl
        Layout.alignment: Qt.AlignVCenter
        onClicked: root.toggled(checked)
    }
}
