import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool showDate: Config.options.bar.verbose
    property bool vertical: Config.options.bar.vertical
    property bool isMaterial: Config.options.bar.cornerStyle === 3 || Config.options.bar.cornerStyle === 4
    property color contentColor: Appearance.colors.colOnLayer1
    property bool contentColorOverridden: false
    property bool isDi: GlobalStates.dynamicIslandEnabled && Config.options.bar.dynamicIsland.rightWidget === "systemIcons"
    readonly property color iconColor: root.contentColorOverridden ? root.contentColor : (root.isDi ? Appearance.colors.colOnLayer1 : (root.isMaterial ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1))

    // Only the Android quick panel has a user-managed tile list. Other styles have a fixed
    // set of toggles, so a null list here means "do not filter".
    readonly property var addedToggleTypes: (Config.ready && Config.options.sidebar.quickToggles.style === "android")
        ? Config.options.sidebar.quickToggles.android.toggles.filter(toggle => toggle).map(toggle => toggle.type)
        : null

    function hasToggle(type: string): bool {
        return !root.addedToggleTypes || root.addedToggleTypes.includes(type);
    }

    implicitWidth: root.vertical ? 32 : flow.implicitWidth + 4
    implicitHeight: root.vertical ? flow.implicitHeight + 4 : 32

    MouseArea {
        anchors.fill: parent
        onPressed: {
            GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
        }
    }

    Flow {
        id: flow
        anchors.centerIn: parent
        flow: root.vertical ? Flow.TopToBottom : Flow.LeftToRight
        spacing: isMaterial ? 2 : 10

        Revealer {
            reveal: root.hasToggle("audio")
            MaterialSymbol {
                text: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"
                iconSize: Appearance.font.pixelSize.larger
                color: root.iconColor
            }
        }
        Revealer {
            reveal: (Audio.source?.audio?.muted ?? false) && root.hasToggle("mic")
            MaterialSymbol {
                text: "mic_off"
                iconSize: Appearance.font.pixelSize.larger
                color: root.iconColor
            }
        }
        Revealer {
            reveal: Wlsunset.temperatureActive && root.hasToggle("nightLight")
            MaterialSymbol {
                text: Config.options.light.night.automatic ? "night_sight_auto" : "bedtime"
                iconSize: Appearance.font.pixelSize.larger
                color: root.iconColor
            }
        }
        Revealer {
            reveal: Idle.inhibit && root.hasToggle("idleInhibitor")
            MaterialSymbol {
                text: "coffee"
                iconSize: Appearance.font.pixelSize.larger
                color: root.iconColor
            }
        }
        Loader {
            source: "XkbIndicator.qml"
            onLoaded: item.color = root.iconColor
        }
        MaterialSymbol {
            visible: root.hasToggle("network")
            text: Network.materialSymbol
            iconSize: Appearance.font.pixelSize.larger
            color: root.iconColor
        }
        MaterialSymbol {
            visible: BluetoothStatus.available && root.hasToggle("bluetooth")
            text: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
            iconSize: Appearance.font.pixelSize.larger
            color: root.iconColor
        }
        Loader {
            id: notifLoader
            active: Notifications.silent || Notifications.unread > 0
            visible: active
            width: active ? item?.implicitWidth ?? 0 : 0
            height: active ? item?.implicitHeight ?? 0 : 0
            source: "NotificationUnreadCount.qml"
        }
    }
}