import qs.modules.common
import QtQuick

Item {
    id: root
    property color highlightColor: Appearance.colors.colPrimary
    property color trackColor: Appearance.colors.colSecondaryContainer
    property real barHeight: 4
    property real gap: 4

    implicitWidth: 200
    implicitHeight: barHeight
    clip: true

    property real headPos: 0
    property real tailPos: 0

    SequentialAnimation {
        running: root.visible
        loops: Animation.Infinite

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "headPos"
                from: 0
                to: 1
                duration: 750
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
            }
            SequentialAnimation {
                PauseAnimation { duration: 250 }
                NumberAnimation {
                    target: root
                    property: "tailPos"
                    from: 0
                    to: 1
                    duration: 750
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.emphasizedAccel
                }
            }
        }
    }

    // Track left of indicator
    Rectangle {
        visible: width > 0
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, root.tailPos * parent.width - root.gap)
        height: root.barHeight
        radius: height / 2
        color: root.trackColor
    }

    // Active sliding bar
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: root.tailPos * parent.width
        width: Math.max(0, (root.headPos - root.tailPos) * parent.width)
        height: root.barHeight
        radius: height / 2
        color: root.highlightColor
    }

    // Track right of indicator
    Rectangle {
        visible: width > 0
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, (1 - root.headPos) * parent.width - root.gap)
        height: root.barHeight
        radius: height / 2
        color: root.trackColor
    }
}
