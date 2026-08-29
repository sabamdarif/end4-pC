import qs.services
import QtQuick
import Quickshell
import qs.modules.ii.onScreenDisplay

OsdValueIndicator {
    id: rotateIcon

    icon: "wb_twilight"
    name: Translation.tr("Gamma")
    from: Wlsunset.gammaLowerLimit / 100
    value: Wlsunset.gamma / 100 ?? 0.5
}
