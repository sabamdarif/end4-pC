import qs.services
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.ii.onScreenDisplay

OsdValueIndicator {
    id: root
    property var focusedScreen: (WM.compositor === "hyprland"
            ? Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
            : Quickshell.screens.find(s => s.name === WM.focusedMonitor?.name)) ?? Quickshell.screens[0]
    property var brightnessMonitor: Brightness.getMonitorForScreen(focusedScreen)

    icon: "brightness_medium"
    name: Translation.tr("Brightness")
    value: root.brightnessMonitor?.brightness ?? 0.5
}
