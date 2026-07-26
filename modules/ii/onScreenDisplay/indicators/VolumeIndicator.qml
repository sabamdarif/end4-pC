import qs.services
import QtQuick
import qs.modules.ii.onScreenDisplay

OsdValueIndicator {
    id: osdValues
    to: Audio.maxVolume
    value: Audio.sink?.audio.volume ?? 0
    icon: Audio.sink?.audio.muted ? "volume_off" : "volume_up"
    name: Translation.tr("Volume")
}
