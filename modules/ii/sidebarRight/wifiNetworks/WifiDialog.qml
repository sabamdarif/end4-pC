import qs.services
import qs.services.network
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

DialogSheet {
    id: root
    title: Translation.tr("Connect to Wi-Fi")
    busy: Network.wifiScanning
    edgeToEdge: true
    settingsPage: "wifi"

    ListView {
        Layout.fillHeight: true
        Layout.fillWidth: true

        clip: true
        spacing: 0

        model: ScriptModel {
            values: Network.friendlyWifiNetworks
        }
        delegate: WifiNetworkItem {
            required property WifiAccessPoint modelData
            wifiNetwork: modelData
            width: ListView.view.width
        }
    }
}
