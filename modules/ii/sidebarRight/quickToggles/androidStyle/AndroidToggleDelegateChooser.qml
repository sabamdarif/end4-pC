pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.models.quickToggles
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower

AndroidQuickToggleButton {
    id: root

    required property int index
    required property var modelData

    property int startingIndex: 0

    buttonIndex: root.startingIndex + index
    buttonData: modelData
    expandedSize: (modelData?.size ?? 1) > 1
    cellSize: modelData?.size ?? 1

    signal openAudioOutputDialog()
    signal openAudioInputDialog()
    signal openBluetoothDialog()
    signal openKeepAwakeDialog()
    signal openNightLightDialog()
    signal openWifiDialog()

    onOpenMenu: {
        switch (modelData?.type) {
            case "audio": root.openAudioOutputDialog(); break;
            case "bluetooth": root.openBluetoothDialog(); break;
            case "idleInhibitor": root.openKeepAwakeDialog(); break;
            case "mic": root.openAudioInputDialog(); break;
            case "network": root.openWifiDialog(); break;
            case "nightLight": root.openNightLightDialog(); break;
        }
    }

    Component { id: audioComp; AudioToggle {} }
    Component { id: bluetoothComp; BluetoothToggle {} }
    Component { id: warpComp; CloudflareWarpToggle {} }
    Component { id: pickerComp; ColorPickerToggle {} }
    Component { id: darkModeComp; DarkModeToggle {} }
    Component { id: idleComp; IdleInhibitorToggle {} }
    Component { id: micComp; MicToggle {} }
    Component { id: networkComp; NetworkToggle {} }
    Component { id: nightLightComp; NightLightToggle {} }
    Component { id: notifComp; NotificationToggle {} }
    Component { id: powerComp; PowerProfilesToggle {} }
    Component { id: snipComp; ScreenSnipToggle {} }

    Loader {
        id: modelLoader
        active: !!root.modelData?.type
        sourceComponent: {
            switch (root.modelData?.type) {
                case "audio": return audioComp;
                case "bluetooth": return bluetoothComp;
                case "cloudflareWarp": return warpComp;
                case "colorPicker": return pickerComp;
                case "darkMode": return darkModeComp;
                case "idleInhibitor": return idleComp;
                case "mic": return micComp;
                case "network": return networkComp;
                case "nightLight": return nightLightComp;
                case "notifications": return notifComp;
                case "powerProfile": return powerComp;
                case "screenSnip": return snipComp;
                default: return null;
            }
        }
    }

    toggleModel: modelLoader.item
}
