import QtQuick
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: contentItem
    anchors.fill: parent
    color: Appearance.colors.colLayer1Blurred

    WindowGlass {
        anchors.fill: parent
        glassEnabled: (parent?.color.a ?? 0) > 0
        cardRadius: parent?.radius ?? 0
        tint: parent?.color ?? 'transparent'
    }
}
