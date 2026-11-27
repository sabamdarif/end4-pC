import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls

Switch {
    id: root
    property real scale: 0.85
    implicitHeight: Math.round(32 * root.scale)
    implicitWidth: Math.round(52 * root.scale)

    property color activeColor: Appearance?.colors.colPrimary ?? "#cbc4cb"
    property color inactiveColor: Appearance?.m3colors.m3surfaceContainerHighest ?? "#363435"

    PointingHandInteraction {}

    background: Rectangle {
        width: parent.width
        height: parent.height
        radius: Appearance?.rounding.full ?? 9999
        color: root.checked ? root.activeColor : root.inactiveColor
        border.width: root.visualFocus ? 2.5 : (root.checked ? 0 : 2)
        border.color: root.visualFocus
            ? (Appearance?.colors.colPrimary ?? "#cbc4cb")
            : (root.checked ? "transparent" : (Appearance?.colors.colOutline ?? "#948f94"))

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
        Behavior on border.color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    indicator: Rectangle {
        readonly property real checkedSize: Math.round(24 * root.scale)
        readonly property real uncheckedSize: Math.round(20 * root.scale)
        readonly property real pressedSize: Math.round(26 * root.scale)
        readonly property real thumbSize: (root.pressed || root.down)
            ? pressedSize
            : (root.checked ? checkedSize : uncheckedSize)
        readonly property real pad: Math.round((parent.height - thumbSize) / 2)
        readonly property real stretchExtra: Math.round(4 * root.scale)

        width: (root.pressed || root.down)
            ? thumbSize + stretchExtra
            : thumbSize
        height: thumbSize
        radius: Appearance?.rounding.full ?? 9999

        color: root.checked
            ? (Appearance?.colors.colOnPrimary ?? "#322f34")
            : (Appearance?.colors.colOutline ?? "#948f94")

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: root.checked
            ? (parent.width - width - pad)
            : pad

        Behavior on anchors.leftMargin {
            animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
        }
        Behavior on width {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on height {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        MaterialSymbol {
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            renderType: Text.QtRendering
            text: root.checked ? "check" : "close"
            iconSize: Math.round(14 * root.scale)
            font.weight: Font.Bold
            color: root.checked
                ? (Appearance?.colors.colPrimary ?? "#cbc4cb")
                : root.inactiveColor

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
    }
}
