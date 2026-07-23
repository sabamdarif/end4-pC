import qs.services
import QtQuick
import qs.modules.ii.onScreenDisplay

OsdStatusIndicator {
    id: root
    active: KeyLocks.capsLock
    icon: "keyboard_capslock"
    title: Translation.tr("Caps Lock")
}
