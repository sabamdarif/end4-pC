import qs.modules.common
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls

/**
 * Material 3 styled SpinBox component.
 */
SpinBox {
    id: root

    property real baseHeight: 35
    property real radius: Appearance.rounding.small
    property real innerButtonRadius: Appearance.rounding.unsharpen
    implicitHeight: root.baseHeight
    implicitWidth: Math.max(contentItem.implicitWidth, 40) + leftPadding + rightPadding
    editable: true

    opacity: root.enabled ? 1 : 0.4

    background: Rectangle {
        color: Appearance.colors.colLayer2
        radius: root.radius
        border.width: root.activeFocus ? 2 : 0
        border.color: Appearance.colors.colPrimary
    }

    contentItem: StyledTextInput {
        text: root.value
        horizontalAlignment: TextInput.AlignHCenter
        verticalAlignment: TextInput.AlignVCenter
        color: Appearance.colors.colOnLayer2
        font.family: Appearance.font.family.numbers
        font.variableAxes: Appearance.font.variableAxes.numbers
        font.pixelSize: Appearance.font.pixelSize.small
        font.features: ({ "tnum": 1 })
        validator: root.validator
        readOnly: !root.editable
        inputMethodHints: Qt.ImhFormattedNumbersOnly
    }

    down.indicator: Rectangle {
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
        }
        implicitHeight: root.baseHeight
        implicitWidth: root.baseHeight
        topLeftRadius: root.down.pressed ? Appearance.rounding.verysmall : root.radius
        bottomLeftRadius: root.down.pressed ? Appearance.rounding.verysmall : root.radius
        topRightRadius: root.innerButtonRadius
        bottomRightRadius: root.innerButtonRadius

        color: root.down.pressed ? Appearance.colors.colLayer2Active : 
            root.down.hovered ? Appearance.colors.colLayer2Hover : 
            ColorUtils.transparentize(Appearance.colors.colLayer2)
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            cursorShape: Qt.PointingHandCursor
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: "remove"
            iconSize: Appearance.font.pixelSize.larger
            color: Appearance.colors.colOnLayer2
        }
    }

    up.indicator: Rectangle {
        anchors {
            verticalCenter: parent.verticalCenter
            right: parent.right
        }
        implicitHeight: root.baseHeight
        implicitWidth: root.baseHeight
        topRightRadius: root.up.pressed ? Appearance.rounding.verysmall : root.radius
        bottomRightRadius: root.up.pressed ? Appearance.rounding.verysmall : root.radius
        topLeftRadius: root.innerButtonRadius
        bottomLeftRadius: root.innerButtonRadius

        color: root.up.pressed ? Appearance.colors.colLayer2Active : 
            root.up.hovered ? Appearance.colors.colLayer2Hover : 
            ColorUtils.transparentize(Appearance.colors.colLayer2)
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            cursorShape: Qt.PointingHandCursor
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: "add"
            iconSize: Appearance.font.pixelSize.larger
            color: Appearance.colors.colOnLayer2
        }
    }
}
