import qs.services
import QtQuick
import Quickshell
import qs.modules.ii.onScreenDisplay

OsdValueIndicator {
    id: root
    property var focusedScreen: Quickshell.screens.find(s => s.name === NiriData.currentOutput) ?? Quickshell.screens[0]
    property var brightnessMonitor: Brightness.getMonitorForScreen(focusedScreen)

    icon: "brightness_medium"
    name: Translation.tr("Brightness")
    value: root.brightnessMonitor?.brightness ?? 0.5
}
