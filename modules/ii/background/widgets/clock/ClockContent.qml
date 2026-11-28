import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import "."

Column {
    id: root

    property string clockStyle: Config.options.background.widgets.clock.style
    property color colText: Appearance.colors.colPrimary
    property var textHorizontalAlignment: Text.AlignHCenter

    readonly property string customClockColorKey: Config.options.background.widgets.clock.color ?? ""
    readonly property color resolvedClockColor: {
        if (customClockColorKey === "") return root.colText;
        const propName = "col" + customClockColorKey.charAt(0).toUpperCase() + customClockColorKey.slice(1);
        return Appearance.colors[propName] ?? root.colText;
    }

    spacing: 10

    FadeLoader {
        anchors.horizontalCenter: parent.horizontalCenter
        shown: root.clockStyle === "cookie"
        fade: false
        sourceComponent: CookieClock {}
    }

    FadeLoader {
        anchors.horizontalCenter: parent.horizontalCenter
        shown: root.clockStyle === "digital"
        fade: false
        sourceComponent: DigitalClock {
            colText: root.resolvedClockColor
            textHorizontalAlignment: root.textHorizontalAlignment
        }
    }

    FadeLoader {
        anchors.horizontalCenter: parent.horizontalCenter
        shown: root.clockStyle === "pixel"
        fade: false
        sourceComponent: PixelClock {}
    }

    FadeLoader {
        anchors.horizontalCenter: parent.horizontalCenter
        shown: Config.options.background.widgets.clock.quote.enable
            && root.clockStyle === "pixel"
            && Config.options.background.widgets.clock.quote.text !== ""
        sourceComponent: CookieQuote {}
    }
}
