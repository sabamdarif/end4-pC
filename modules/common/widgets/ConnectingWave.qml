import qs.modules.common
import QtQuick

/**
 * Indeterminate travelling wave shown under the name of a device or network
 * while a connection to it is being established.
 */
Item {
    id: root
    property bool running: false
    property color color: Appearance.colors.colPrimary
    property real thickness: 3

    implicitHeight: root.running ? root.thickness * 4 : 0
    // An invisible item is dropped from a layout entirely, so a collapsed wave
    // leaves no gap behind
    visible: root.implicitHeight > 0

    Behavior on implicitHeight {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    WavyLine {
        id: line
        anchors.fill: parent
        color: root.color
        lineWidth: root.thickness
        amplitudeMultiplier: 1
        // Keeps one wavelength around 56px whatever the row is wide
        frequency: Math.max(2, Math.round(root.width / 56))
        fullLength: root.width
        phaseSpeed: -10

        FrameAnimation {
            // root.visible is false while an ancestor is hidden, so a closed
            // dialog costs nothing
            running: root.visible
            onTriggered: line.requestPaint()
        }
    }
}
