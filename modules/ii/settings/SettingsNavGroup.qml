import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

/**
 * A collapsible group header in the settings nav rail. Draws the chevron only
 * when the group actually has children; a childless group behaves as a leaf.
 */
RippleButton {
    id: root

    required property string groupIcon
    required property string groupName
    property real groupIconRotation: 0
    property bool expanded: false
    property bool hasChildren: true
    // Rail is narrow: icon only, no label and no chevron.
    property bool showLabel: true

    readonly property real baseSize: 48

    Layout.fillWidth: true
    padding: 0
    implicitHeight: baseSize
    buttonRadius: Appearance.rounding.full
    colBackground: ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
    colBackgroundHover: Appearance.colors.colLayer1Hover
    colBackgroundToggled: Appearance.colors.colSecondaryContainer
    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
    colRipple: Appearance.colors.colLayer1Active
    colRippleToggled: Appearance.colors.colSecondaryContainerActive

    contentItem: RowLayout {
        spacing: 6

        MaterialSymbol {
            Layout.leftMargin: 10
            text: root.groupIcon
            rotation: root.groupIconRotation
            iconSize: 24
            fill: root.toggled ? 1 : 0
            font.weight: (root.toggled || root.hovered) ? Font.DemiBold : Font.Normal
            color: root.toggled ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer1

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }

        StyledText {
            visible: root.showLabel
            Layout.fillWidth: true
            text: root.groupName
            font.pixelSize: 14
            font.weight: Font.Medium
            elide: Text.ElideRight
            color: root.toggled ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer1
        }

        MaterialSymbol {
            Layout.rightMargin: 8
            visible: root.showLabel && root.hasChildren
            text: "keyboard_arrow_down"
            iconSize: 20
            color: Appearance.colors.colSubtext
            rotation: root.expanded ? 180 : 0

            Behavior on rotation {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }
    }
}
