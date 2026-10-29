pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root
    property real barZone: 0
    property string barEdge: "top"
    property real dockZone: 0
    property string dockEdge: "bottom"
    readonly property real topZone: (barEdge === "top" ? barZone : 0) + (dockEdge === "top" ? dockZone : 0)
    readonly property real bottomZone: (barEdge === "bottom" ? barZone : 0) + (dockEdge === "bottom" ? dockZone : 0)
    readonly property real leftZone: (barEdge === "left" ? barZone : 0) + (dockEdge === "left" ? dockZone : 0)
    readonly property real rightZone: (barEdge === "right" ? barZone : 0) + (dockEdge === "right" ? dockZone : 0)

    function refresh() {}
}
