import qs.services
import QtQuick
import qs.modules.ii.onScreenDisplay

OsdStatusIndicator {
    id: root
    active: !(Audio.source?.audio?.muted ?? false)
    icon: active ? "mic" : "mic_off"
    title: Translation.tr("Microphone")
    activeText: Translation.tr("ON")
    inactiveText: Translation.tr("MUTED")
}
