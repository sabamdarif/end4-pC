import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root
    signal requestBluetoothDialog()
    signal requestDrivesDialog()
    property bool barOpen: true
    property bool clipboardOpen: false
    property bool crosshairOpen: false
    property bool sidebarRightOpen: false
    property bool mediaControlsOpen: false
    property bool osdBrightnessOpen: false
    property bool settingsOpen: false
    property bool osdVolumeOpen: false
    property bool overlayOpen: false
    property bool overviewOpen: false
    property bool regionSelectorOpen: false
    property bool screenLocked: false
    property bool screenLockContainsCharacters: false
    property bool screenUnlockFailed: false
    property bool sessionOpen: false
    property bool wallpaperSelectorOpen: false
    readonly property bool dynamicIslandEnabled: (Config.options?.bar?.cornerStyle === 2)
    property string osdIndicatorType: "volume"
    property bool diSessionOpen: false
    property bool islandExpanded: false
    property bool barCenterOnly: false
    property bool superDown: false
    property bool startupLockPending: false
    property real lastBackingY: 0
    property string diForceView: ""
    property bool diForceCycle: false
    property bool workspaceShowNumbers: false
    property string settingsPage: ""
    property Item currentPageInstance: null

    function openSettingsAt(targetPage: string): void {
        root.settingsOpen = true
        Qt.callLater(() => {
            root.settingsPage = targetPage
        })
    }
    property list<real> visualizerPoints: []
    property bool desktopWidgetKeyboardFocus: false
    property bool desktopMenuOpen: false
    property var desktopMenuScreen: null
    property real desktopMenuX: 0
    property real desktopMenuY: 0
    property string wallpaperSelectorTarget: "wallpaper"

    onSidebarRightOpenChanged: {
        if (GlobalStates.sidebarRightOpen) {
            Notifications.timeoutAll();
            Notifications.markAllRead();
        }
    }

    IpcHandler {
        target: "background"
        function toggleCenteredWallpaper(): void {
            Config.options.background.centeredWallpaper = !Config.options.background.centeredWallpaper
        }
    }
}
