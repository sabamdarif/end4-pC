import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

TextField {
    id: filterField

    property color colBackground: Appearance.colors.colLayer1
    property color colBackgroundFocused: colBackground
    property string leadingIcon: ""
    property bool clearable: false

    signal cleared()

    Layout.fillHeight: true
    implicitWidth: 200
    padding: 10
    leftPadding: leadingIcon !== "" ? 42 : padding
    rightPadding: (clearable && text.length > 0) ? 40 : padding
    selectByMouse: true

    placeholderTextColor: Appearance.colors.colSubtext
    color: Appearance.colors.colOnLayer1
    font {
        family: Appearance.font.family.main
        pixelSize: Appearance.font.pixelSize.small
        hintingPreference: Font.PreferFullHinting
        variableAxes: Appearance.font.variableAxes.main
    }
    renderType: Text.NativeRendering
    selectedTextColor: Appearance.colors.colOnSecondaryContainer
    selectionColor: Appearance.colors.colSecondaryContainer

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.IBeamCursor
    }

    background: Rectangle {
        id: background
        color: filterField.activeFocus ? filterField.colBackgroundFocused : filterField.colBackground
        radius: Appearance.rounding.full
        border.width: 0

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        MaterialSymbol {
            visible: filterField.leadingIcon !== ""
            anchors {
                left: parent.left
                leftMargin: 14
                verticalCenter: parent.verticalCenter
            }
            text: filterField.leadingIcon
            iconSize: Appearance.font.pixelSize.larger
            color: filterField.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colSubtext

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }

        RippleButton {
            visible: filterField.clearable && filterField.text.length > 0
            anchors {
                right: parent.right
                rightMargin: 6
                verticalCenter: parent.verticalCenter
            }
            implicitWidth: 32
            implicitHeight: 32
            buttonRadius: Appearance.rounding.full
            buttonRadiusPressed: Appearance.rounding.verysmall
            colBackground: "transparent"
            colBackgroundHover: Appearance.colors.colLayer3Hover
            colRipple: Appearance.colors.colLayer3Active
            onClicked: {
                filterField.text = ""
                filterField.cleared()
                filterField.forceActiveFocus()
            }

            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: "close"
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
            }

            StyledToolTip {
                text: Translation.tr("Clear search")
            }
        }
    }
}
