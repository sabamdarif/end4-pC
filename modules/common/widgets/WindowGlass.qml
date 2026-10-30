import QtQuick
import QtQml
import Quickshell
import qs.services
import qs.modules.common

Item {
    id: root
    property real cardRadius: 0
    property real topLeftRadius: cardRadius
    property real topRightRadius: cardRadius
    property real bottomRightRadius: cardRadius
    property real bottomLeftRadius: cardRadius
    property color tint: "transparent"
    property bool glassEnabled: true
    property real tintStrength: Appearance.m3colors.darkmode ? 0.35 : 0.82

    readonly property color effectiveTint: {
        if (root.tint !== "transparent" && root.tint.a > 0) {
            return root.tint;
        }
        return Appearance.colors.colLayer0Base;
    }

    readonly property var win: QsWindow.window
    readonly property var scr: win?.screen ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
    readonly property bool floating: !!win && win.anchors === undefined && win.anchor === undefined
    readonly property bool popup: !!win && win.anchor !== undefined

    function panelOffset(w, s) {
        if (!w || !s) return Qt.point(0, 0)
        const a = w.anchors
        const m = w.margins
        const pushed = w.exclusionMode !== ExclusionMode.Ignore
        const x = a?.left ? (m?.left ?? 0) + (pushed ? GlassLayers.leftZone : 0)
            : a?.right ? s.width - w.width - (m?.right ?? 0) - (pushed ? GlassLayers.rightZone : 0)
            : (s.width - w.width) / 2
        const y = a?.top ? (m?.top ?? 0) + (pushed ? GlassLayers.topZone : 0)
            : a?.bottom ? s.height - w.height - (m?.bottom ?? 0) - (pushed ? GlassLayers.bottomZone : 0)
            : (s.height - w.height) / 2
        return Qt.point(x, y)
    }

    function popupOffset(w, s) {
        if (!w || !s) return Qt.point(0, 0)
        const an = w.anchor
        if (!an) return panelOffset(w, s)
        const host = an.window
        if (!host) return Qt.point(0, 0)
        const base = host.anchor !== undefined ? popupOffset(host, s) : panelOffset(host, s)
        let rx = an.rect?.x ?? 0, ry = an.rect?.y ?? 0, rw = an.rect?.width ?? 0, rh = an.rect?.height ?? 0
        if (an.item) {
            const p = an.item.mapToItem(null, 0, 0)
            rx = p.x; ry = p.y; rw = an.item.width; rh = an.item.height
        }
        const e = an.edges ?? 0, g = an.gravity ?? 0
        const ax = (e & Qt.LeftEdge) ? rx : (e & Qt.RightEdge) ? rx + rw : rx + rw / 2
        const ay = (e & Qt.TopEdge) ? ry : (e & Qt.BottomEdge) ? ry + rh : ry + rh / 2
        const gx = (g & Qt.LeftEdge) ? ax - w.width : (g & Qt.RightEdge) ? ax : ax - w.width / 2
        const gy = (g & Qt.TopEdge) ? ay - w.height : (g & Qt.BottomEdge) ? ay : ay - w.height / 2
        const x = Math.max(0, Math.min(base.x + gx, s.width - w.width))
        const y = Math.max(0, Math.min(base.y + gy, s.height - w.height))
        return Qt.point(x, y)
    }

    readonly property point floatPos: {
        if (!root.floating || !root.win) return Qt.point(0, 0)
        const niriWin = NiriData.windows.find(w => w.title === root.win.title)
        const pos = niriWin?.layout?.tile_pos_in_workspace_view
        if (pos && pos.length >= 2) {
            return Qt.point(pos[0], pos[1])
        }
        if (root.scr) {
            return Qt.point(Math.max(0, (root.scr.width - root.win.width) / 2), Math.max(0, (root.scr.height - root.win.height) / 2))
        }
        return Qt.point(0, 0)
    }

    readonly property point winPos: {
        if (!win || !scr) return Qt.point(0, 0)
        if (floating) return floatPos
        if (popup) return popupOffset(win, scr)
        return panelOffset(win, scr)
    }
    readonly property real winX: winPos.x
    readonly property real winY: winPos.y

    property point origin: Qt.point(0, 0)

    function refresh() {
        const p = mapToItem(null, 0, 0)
        if (p.x !== origin.x || p.y !== origin.y) origin = p
    }

    function kick() {
        refresh()
        settleTimer.restart()
        ticker.running = true
    }

    property var ancestors: []

    function rebuild() {
        const list = []
        for (let it = parent; it; it = it.parent) list.push(it)
        ancestors = list
        kick()
    }

    onParentChanged: rebuild()
    onXChanged: kick()
    onYChanged: kick()
    onWidthChanged: kick()
    onHeightChanged: kick()
    onVisibleChanged: kick()
    onGlassEnabledChanged: kick()
    Component.onCompleted: rebuild()

    Instantiator {
        model: root.ancestors
        delegate: Connections {
            required property var modelData
            target: modelData
            ignoreUnknownSignals: true
            function onXChanged() { root.kick() }
            function onYChanged() { root.kick() }
            function onWidthChanged() { root.kick() }
            function onHeightChanged() { root.kick() }
            function onScaleChanged() { root.kick() }
            function onParentChanged() { root.rebuild() }
        }
    }

    Connections {
        target: root.win
        ignoreUnknownSignals: true
        function onWidthChanged() { root.kick() }
        function onHeightChanged() { root.kick() }
        function onVisibleChanged() { root.kick() }
    }

    Timer {
        id: ticker
        interval: 16
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        id: settleTimer
        interval: 1000
        onTriggered: ticker.running = false
    }

    readonly property string wallpaper: {
        const path = Config.options.background.wallpaperPath
        return /\.(mp4|webm|mkv|avi|mov)$/.test(path) ? Config.options.background.thumbnailPath : path
    }

    Loader {
        anchors.fill: parent
        active: root.glassEnabled && (Config.options.background?.widgets?.glass?.enable ?? false) && !!root.scr && root.wallpaper !== ""

        sourceComponent: Item {
            Image {
                id: wallpaperImage
                visible: false
                width: root.scr.width
                height: root.scr.height
                x: -(root.winX + root.origin.x)
                y: -(root.winY + root.origin.y)
                source: "file://" + root.wallpaper
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(Math.ceil(root.scr.width * root.scr.devicePixelRatio), Math.ceil(root.scr.height * root.scr.devicePixelRatio))
                asynchronous: true
                cache: true
            }

            FrostedGlass {
                anchors.fill: parent
                blurSource: wallpaperImage
                cardRadius: root.cardRadius
                topLeftRadius: root.topLeftRadius
                topRightRadius: root.topRightRadius
                bottomRightRadius: root.bottomRightRadius
                bottomLeftRadius: root.bottomLeftRadius
                tint: root.effectiveTint
                tintOpacity: root.tintStrength
                trackX: wallpaperImage.x
                trackY: wallpaperImage.y
            }
        }
    }
}
