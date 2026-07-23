import qs.services
import QtQuick
import qs.modules.ii.onScreenDisplay

OsdStatusIndicator {
    id: root
    active: KeyLocks.numLock
    icon: "pin"
    title: Translation.tr("Num Lock")
}
