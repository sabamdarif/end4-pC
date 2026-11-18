import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: osd
    required property Item di
    anchors.fill: parent

    readonly property var focusedScreen: Quickshell.screens.find(s => s.name === NiriData.currentOutput) ?? Quickshell.screens[0]
    readonly property var brightnessMonitor: Brightness.getMonitorForScreen(focusedScreen)

    readonly property string kind: GlobalStates.osdIndicatorType
    readonly property bool muted: osd.kind === "volume" && (Audio.sink?.audio?.muted ?? false)
    readonly property real value: {
        switch (osd.kind) {
            case "brightness": return IslandEvents.realBrightness >= 0 ? IslandEvents.realBrightness : (osd.brightnessMonitor?.brightness ?? 0)
            case "gamma":      return (Wlsunset.gamma ?? 50) / 100
            default:           return Audio.sink?.audio?.volume ?? 0
        }
    }
    readonly property real maxValue: osd.kind === "volume" ? (osd.di.cfg.volumeMax ?? 1.5) : 1
    readonly property real clamped: Math.max(0, Math.min(osd.maxValue, osd.value))
    readonly property bool boosted: osd.kind === "volume" && !osd.muted && osd.shown > 1.005
    readonly property color boostColor: Appearance.colors.colTertiary

    property bool dragging: false
    property real dragValue: 0
    readonly property real sliderMax: osd.maxValue

    DiSpring {
        id: shownSpring
        target: osd.dragging ? osd.dragValue : osd.clamped
        stiffness: 850
        dampingRatio: 0.78
        epsilon: 0.005
    }
    readonly property real shown: osd.dragging ? osd.dragValue : shownSpring.value

    property real pendingVolume: -1
    property real pendingBrightness: -1

    Timer {
        id: applyVolume
        interval: 20
        repeat: false
        onTriggered: {
            if (osd.pendingVolume >= 0 && Audio.sink?.audio) {
                Audio.sink.audio.muted = false
                Audio.sink.audio.volume = Math.round(osd.pendingVolume * 100) / 100
            }
            osd.pendingVolume = -1
        }
    }

    Timer {
        id: applyBrightness
        interval: 60
        repeat: false
        onTriggered: {
            if (osd.pendingBrightness >= 0) {
                osd.brightnessMonitor?.setBrightness(osd.pendingBrightness)
            }
            osd.pendingBrightness = -1
        }
    }

    function setLevel(v, immediate) {
        if (osd.kind === "brightness") {
            osd.pendingBrightness = v
            if (immediate) {
                applyBrightness.stop()
                osd.brightnessMonitor?.setBrightness(v)
                osd.pendingBrightness = -1
            } else if (!applyBrightness.running) {
                applyBrightness.start()
            }
        } else if (osd.kind === "volume" && Audio.sink?.audio) {
            osd.pendingVolume = v
            if (immediate) {
                applyVolume.stop()
                Audio.sink.audio.muted = false
                Audio.sink.audio.volume = Math.round(v * 100) / 100
                osd.pendingVolume = -1
            } else if (!applyVolume.running) {
                applyVolume.start()
            }
        }
    }

    Rectangle {
        id: fill
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        width: Math.max(height, parent.width * Math.max(0, Math.min(1, osd.shown / osd.maxValue)))
        radius: height / 2
        color: ColorUtils.transparentize(Appearance.colors.colPrimary, osd.muted ? 0.92 : (osd.dragging ? 0.55 : 0.7))

        Behavior on color {
            ColorAnimation { duration: IslandMotion.short }
        }

        Rectangle {
            anchors {
                right: parent.right
                rightMargin: 6
                verticalCenter: parent.verticalCenter
            }
            width: osd.dragging ? 5 : 3
            height: parent.height * (osd.dragging ? 0.75 : 0.5)
            radius: width / 2
            color: osd.boosted ? osd.boostColor : Appearance.colors.colPrimary
            opacity: osd.muted ? 0 : (osd.dragging ? 1 : 0.8)

            Behavior on width { NumberAnimation { duration: IslandMotion.micro } }
            Behavior on height { NumberAnimation { duration: IslandMotion.micro } }
            Behavior on opacity { NumberAnimation { duration: IslandMotion.micro } }
        }
    }

    Rectangle {
        id: mark100
        visible: osd.maxValue > 1.05 && !osd.muted
        anchors.verticalCenter: parent.verticalCenter
        x: Math.round(parent.width * (1.0 / osd.maxValue)) - width / 2
        width: 2
        height: parent.height * 0.4
        radius: 1
        color: Appearance.colors.colOnLayer0
        opacity: 0.25
    }

    Rectangle {
        id: boostFill
        anchors {
            top: parent.top
            bottom: parent.bottom
        }
        visible: osd.boosted
        x: Math.round(parent.width * (1.0 / osd.maxValue))
        width: Math.max(0, fill.width - x)
        radius: height / 2
        color: ColorUtils.transparentize(osd.boostColor, 0.45)

        Rectangle {
            anchors {
                right: parent.right
                rightMargin: 6
                verticalCenter: parent.verticalCenter
            }
            width: 3
            height: parent.height * 0.5
            radius: 1.5
            color: osd.boostColor
        }
    }

    function nudge(step) {
        if (osd.kind === "brightness") {
            osd.brightnessMonitor?.setBrightness(Math.max(0, Math.min(1, osd.clamped + step)))
        } else if (Audio.sink?.audio) {
            Audio.sink.audio.muted = false
            Audio.sink.audio.volume = Math.max(0, Math.min(osd.maxValue, Math.round((osd.clamped + step) * 100) / 100))
        }
    }

    MouseArea {
        id: zones
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        cursorShape: osd.dragging ? Qt.SizeHorCursor : Qt.PointingHandCursor
        enabled: osd.kind !== "gamma"
        property real pressX: 0

        function levelAt(x) {
            return Math.max(0, Math.min(osd.sliderMax, x / width * osd.sliderMax))
        }
        onPressed: mouse => {
            zones.pressX = mouse.x
            osd.di.childTapAt = Date.now()
        }
        onPositionChanged: mouse => {
            if (!pressed) return
            if (!osd.dragging && Math.abs(mouse.x - zones.pressX) < 4) return
            osd.dragging = true
            osd.dragValue = zones.levelAt(mouse.x)
            osd.setLevel(osd.dragValue, false)
        }
        onReleased: mouse => {
            osd.di.childTapAt = Date.now()
            if (osd.dragging) {
                osd.dragValue = zones.levelAt(mouse.x)
                osd.setLevel(osd.dragValue, true)
                shownSpring.target = osd.dragValue
                shownSpring.snap()
                osd.dragging = false
                return
            }
            if (mouse.x < width * 0.38) osd.nudge(-0.05)
            else if (mouse.x > width * 0.62) osd.nudge(0.05)
            else osd.di.toggleExpanded()
        }
        onCanceled: {
            if (osd.dragging) {
                applyVolume.stop()
                applyBrightness.stop()
                osd.pendingVolume = -1
                osd.pendingBrightness = -1
                shownSpring.snap()
                osd.dragging = false
            }
        }
    }

    MaterialSymbol {
        anchors {
            left: parent.left
            leftMargin: 34
            verticalCenter: parent.verticalCenter
        }
        text: "remove"
        iconSize: 14
        color: Appearance.colors.colOnLayer0
        opacity: osd.dragging ? 0 : (zones.containsMouse && zones.mouseX < zones.width * 0.38 ? 0.9 : (zones.containsMouse ? 0.3 : 0))

        Behavior on opacity {
            NumberAnimation { duration: IslandMotion.micro }
        }
    }

    MaterialSymbol {
        anchors {
            right: parent.right
            rightMargin: 44
            verticalCenter: parent.verticalCenter
        }
        text: "add"
        iconSize: 14
        color: Appearance.colors.colOnLayer0
        opacity: osd.dragging ? 0 : (zones.containsMouse && zones.mouseX > zones.width * 0.62 ? 0.9 : (zones.containsMouse ? 0.3 : 0))

        Behavior on opacity {
            NumberAnimation { duration: IslandMotion.micro }
        }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: osd.di.isMaterial ? 0 : 4
            rightMargin: 12
        }
        spacing: 6

        MaterialShapeWrappedMaterialSymbol {
            id: osdIcon

            MouseArea {
                anchors.fill: parent
                anchors.margins: -3
                enabled: osd.kind !== "brightness" && osd.kind !== "gamma"
                cursorShape: Qt.PointingHandCursor
                onClicked: Audio.toggleMute()
            }
            wrappedShape: osd.muted ? MaterialShape.Shape.Cookie4Sided : MaterialShape.Shape.Cookie12Sided
            color: osd.muted ? Appearance.colors.colLayer2 : (osd.boosted ? osd.boostColor : Appearance.colors.colPrimary)
            colSymbol: osd.muted ? Appearance.colors.colOnLayer1 : (osd.boosted ? Appearance.colors.colOnTertiary : Appearance.colors.colOnPrimary)
            iconSize: osd.di.isMaterial ? 20 : 16
            fill: 1
            padding: 4
            text: {
                switch (osd.kind) {
                    case "brightness": return Wlsunset.active ? "routine" : "light_mode"
                    case "gamma":      return "wb_twilight"
                    default:
                        if (osd.muted || osd.clamped <= 0) return "volume_off"
                        if (osd.clamped < 0.34) return "volume_mute"
                        if (osd.clamped < 0.67) return "volume_down"
                        return "volume_up"
                }
            }

            Behavior on color {
                ColorAnimation { duration: IslandMotion.short }
            }
        }

        Item { Layout.fillWidth: true }

        StyledText {
            text: osd.muted ? Translation.tr("Muted") : `${Math.round(Math.max(0, osd.shown) * 100)}%`
            font.pixelSize: osd.di.isMaterial ? Appearance.font.pixelSize.normal : Appearance.font.pixelSize.small
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
            color: osd.boosted ? osd.boostColor : Appearance.colors.colOnLayer0
        }
    }
}
