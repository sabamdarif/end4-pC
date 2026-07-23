import QtQuick
import Quickshell.Hyprland
import qs.services

/**
 * A wrapper around GlobalShortcut that only instantiates on Hyprland.
 * On Niri, the Loader stays inactive so no hyprland_global_shortcuts_v1
 * warnings are produced. Use IpcHandler + niri keybinds for Niri instead.
 */
Item {
    id: root
    visible: false
    width: 0
    height: 0

    property string name: ""
    property string description: ""

    signal pressed()
    signal released()

    Loader {
        active: !NiriData.isNiri
        sourceComponent: Component {
            GlobalShortcut {
                name: root.name
                description: root.description
                onPressed: root.pressed()
                onReleased: root.released()
            }
        }
    }
}
