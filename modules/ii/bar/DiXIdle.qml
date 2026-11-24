import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Bluetooth
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

import qs.modules.ii.sidebarRight
import qs.modules.ii.sidebarRight.quickToggles
import qs.modules.ii.sidebarRight.quickToggles.classicStyle
import qs.modules.ii.sidebarRight.quickToggles.androidStyle
import qs.modules.ii.sidebarRight.bluetoothDevices
import qs.modules.ii.sidebarRight.nightLight
import qs.modules.ii.sidebarRight.volumeMixer
import qs.modules.ii.sidebarRight.wifiNetworks
import qs.modules.ii.sidebarRight.keepAwake
import qs.modules.ii.sidebarRight.notifications

// Dynamic Island Control Center: uses the desktop shell's quick toggles, sliders, and notification style.
Item {
    id: root
    required property Item di

    readonly property real wantedWidth: 440
    readonly property bool hasOpenDialog: showAudioOutputDialog || showAudioInputDialog
        || showBluetoothDialog || showKeepAwakeDialog || showNightLightDialog || showWifiDialog

    implicitWidth: root.wantedWidth
    implicitHeight: root.hasOpenDialog ? 560 : (contentLayout.implicitHeight + 16)

    property bool editMode: false
    property bool showAudioOutputDialog: false
    property bool showAudioInputDialog: false
    property bool showBluetoothDialog: false
    property bool showKeepAwakeDialog: false
    property bool showNightLightDialog: false
    property bool showWifiDialog: false

    function closeDialogs() {
        showAudioOutputDialog = false;
        showAudioInputDialog = false;
        showBluetoothDialog = false;
        showKeepAwakeDialog = false;
        showNightLightDialog = false;
        showWifiDialog = false;
    }

    function openDialog(shownPropertyString) {
        closeDialogs();
        root[shownPropertyString] = true;
    }

    Connections {
        target: root.di
        function onExpandedChanged() {
            if (!root.di.expanded) {
                root.closeDialogs();
                root.editMode = false;
            }
        }
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            if (root.hasOpenDialog) {
                root.closeDialogs();
                event.accepted = true;
            } else if (root.editMode) {
                root.editMode = false;
                event.accepted = true;
            }
        }
    }

    ColumnLayout {
        id: contentLayout
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 4
            leftMargin: 6
            rightMargin: 6
        }
        spacing: 10
        visible: !root.hasOpenDialog

        // Header: Back button, Title, System Buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                implicitWidth: 32
                implicitHeight: 32
                radius: 16
                color: backMouse.containsMouse ? Appearance.colors.colLayer2 : "transparent"

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "arrow_back"
                    iconSize: 20
                    color: Appearance.colors.colOnLayer0
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.di.collapse()
                }

                StyledToolTip {
                    extraVisibleCondition: backMouse.containsMouse
                    text: Translation.tr("Close")
                }
            }

            StyledText {
                text: Translation.tr("Control Center")
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer0
            }

            Item { Layout.fillWidth: true }

            ButtonGroup {
                color: Appearance.colors.colLayer1
                padding: 4

                QuickToggleButton {
                    toggled: root.editMode
                    visible: Config.options.sidebar.quickToggles.style === "android"
                    buttonIcon: "edit"
                    onClicked: root.editMode = !root.editMode
                    StyledToolTip {
                        text: Translation.tr("Edit quick toggles") + (root.editMode ? Translation.tr("\nLMB to enable/disable\nRMB to toggle size\nScroll to swap position") : "")
                    }
                }

                QuickToggleButton {
                    toggled: false
                    buttonIcon: "restart_alt"
                    onClicked: {
                        Quickshell.execDetached(["niri", "msg", "action", "load-config-file"]);
                        Quickshell.reload(true);
                    }
                    StyledToolTip {
                        text: Translation.tr("Reload Niri & Quickshell")
                    }
                }

                QuickToggleButton {
                    toggled: GlobalStates.settingsOpen
                    buttonIcon: "settings"
                    onClicked: {
                        root.di.collapse();
                        GlobalStates.openSettingsAt("right-sidebar");
                    }
                    StyledToolTip {
                        text: Translation.tr("Settings")
                    }
                }

                QuickToggleButton {
                    toggled: false
                    buttonIcon: "mode_off_on"
                    onClicked: {
                        root.di.collapse();
                        GlobalStates.sessionOpen = true;
                    }
                    StyledToolTip {
                        text: Translation.tr("Session")
                    }
                }
            }
        }

        // Quick Toggles (Android or Classic style based on Config)
        LoaderedQuickPanel {
            styleName: "classic"
            sourceComponent: ClassicQuickPanel {}
        }

        LoaderedQuickPanel {
            styleName: "android"
            sourceComponent: AndroidQuickPanel {
                editMode: root.editMode
            }
        }

        // Quick Sliders (Brightness, Volume, Mic) - gated by Config
        Loader {
            id: slidersLoader
            Layout.fillWidth: true
            visible: active
            active: {
                const configQuickSliders = Config.options.sidebar.quickSliders
                if (!configQuickSliders.enable) return false
                if (!configQuickSliders.showMic && !configQuickSliders.showVolume && !configQuickSliders.showBrightness) return false;
                return true;
            }
            sourceComponent: QuickSliders {}
        }

        // Media Player - gated by Config and active player
        Loader {
            readonly property MprisPlayer activePlayer: MprisController.activePlayer
            active: activePlayer !== null && Config.options.sidebar.mediaPlayer
            visible: active
            Layout.fillWidth: true
            sourceComponent: Player {
                player: MprisController.activePlayer
                visualizerPoints: GlobalStates.visualizerPoints
                implicitHeight: 140
                radius: Appearance.rounding.normal
            }
        }

        // Notifications
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Math.max(260, Math.min(360, Notifications.list.length * 68 + 60))
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1
            clip: true

            NotificationList {
                anchors.fill: parent
                anchors.margins: 6
            }
        }
    }

    // Dialog Sheets (Wi-Fi, Bluetooth, Volume, KeepAwake, NightLight)
    ToggleDialog {
        shownPropertyString: "showAudioOutputDialog"
        dialog: VolumeDialog { isSink: true }
    }

    ToggleDialog {
        shownPropertyString: "showAudioInputDialog"
        dialog: VolumeDialog { isSink: false }
    }

    ToggleDialog {
        shownPropertyString: "showBluetoothDialog"
        dialog: BluetoothDialog {}
        onShownChanged: {
            const adapter = Bluetooth.defaultAdapter;
            if (!adapter) return;
            if (!shown) {
                adapter.discovering = false;
            } else {
                adapter.enabled = true;
                adapter.discovering = true;
            }
        }
    }

    ToggleDialog {
        shownPropertyString: "showKeepAwakeDialog"
        dialog: KeepAwakeDialog {}
    }

    ToggleDialog {
        shownPropertyString: "showNightLightDialog"
        dialog: NightLightDialog {}
    }

    ToggleDialog {
        shownPropertyString: "showWifiDialog"
        dialog: WifiDialog {}
        onShownChanged: {
            if (!shown) return;
            Network.enableWifi();
            Network.rescanWifi();
        }
    }

    component LoaderedQuickPanel: Loader {
        id: quickPanelImplLoader
        required property string styleName
        Layout.alignment: item?.Layout.alignment ?? Qt.AlignHCenter
        Layout.fillWidth: item?.Layout.fillWidth ?? true
        visible: active
        active: Config.options.sidebar.quickToggles.style === styleName
        Connections {
            target: quickPanelImplLoader.item
            function onOpenAudioOutputDialog() { root.openDialog("showAudioOutputDialog"); }
            function onOpenAudioInputDialog() { root.openDialog("showAudioInputDialog"); }
            function onOpenBluetoothDialog() { root.openDialog("showBluetoothDialog"); }
            function onOpenKeepAwakeDialog() { root.openDialog("showKeepAwakeDialog"); }
            function onOpenNightLightDialog() { root.openDialog("showNightLightDialog"); }
            function onOpenWifiDialog() { root.openDialog("showWifiDialog"); }
        }
    }

    component ToggleDialog: Loader {
        id: toggleDialogLoader
        required property string shownPropertyString
        property alias dialog: toggleDialogLoader.sourceComponent
        readonly property bool shown: root[shownPropertyString]
        anchors.fill: parent
        z: 99

        active: false
        onShownChanged: {
            if (shown) toggleDialogLoader.active = true;
            if (!item) return;
            item.show = shown;
            if (shown) item.forceActiveFocus();
        }
        Connections {
            target: toggleDialogLoader.item
            function onDismiss() {
                root[toggleDialogLoader.shownPropertyString] = false;
            }
            function onVisibleChanged() {
                if (!toggleDialogLoader.shown && toggleDialogLoader.item && !toggleDialogLoader.item.visible)
                    toggleDialogLoader.active = false;
            }
        }
    }
}
