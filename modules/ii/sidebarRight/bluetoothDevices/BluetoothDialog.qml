import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

DialogSheet {
    id: root
    title: Translation.tr("Bluetooth devices")
    busy: Bluetooth.defaultAdapter?.discovering ?? false
    edgeToEdge: true
    settingsPage: "bluetooth"

    StyledListView {
        Layout.fillHeight: true
        Layout.fillWidth: true

        clip: true
        spacing: 0
        animateAppearance: false

        model: ScriptModel {
            values: BluetoothStatus.friendlyDeviceList
        }
        delegate: BluetoothDeviceItem {
            required property BluetoothDevice modelData
            device: modelData
            anchors {
                left: parent?.left
                right: parent?.right
            }
        }
    }
}
