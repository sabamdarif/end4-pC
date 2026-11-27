import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RadioButton {
    id: root
    padding: 4
    implicitHeight: contentItem.implicitHeight + padding * 2
    property string description
    property color activeColor: Appearance.colors.colPrimary
    property color inactiveColor: Appearance.m3colors.m3onSurfaceVariant

    PointingHandInteraction {}

    indicator: Item{}
    
    contentItem: RowLayout {
        id: contentItem
        Layout.fillWidth: true
        spacing: 12
        Rectangle {
            id: radio
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignVCenter
            width: 20
            height: 20
            radius: Appearance?.rounding.full
            border.color: checked ? root.activeColor : root.inactiveColor
            border.width: 2
            color: "transparent"

            // Checked indicator
            Rectangle {
                anchors.centerIn: parent
                width: checked ? 10 : 4
                height: checked ? 10 : 4
                radius: Appearance?.rounding.full
                color: Appearance?.colors.colPrimary
                opacity: checked ? 1 : 0

                Behavior on opacity {
                    animation: Appearance?.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on width {
                    animation: Appearance?.animation.elementMove.numberAnimation.createObject(this)
                }
                Behavior on height {
                    animation: Appearance?.animation.elementMove.numberAnimation.createObject(this)
                }

            }

            // Hover / Focus halo
            Rectangle {
                anchors.centerIn: parent
                readonly property bool showHalo: root.hovered || root.visualFocus
                width: showHalo ? 40 : 20
                height: showHalo ? 40 : 20
                radius: Appearance?.rounding.full
                color: Appearance?.m3colors.m3onSurface
                opacity: root.visualFocus ? StateLayer.Focus : (root.hovered ? StateLayer.Hover : 0)

                Behavior on opacity {
                    animation: Appearance?.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on width {
                    animation: Appearance?.animation.elementMove.numberAnimation.createObject(this)
                }
                Behavior on height {
                    animation: Appearance?.animation.elementMove.numberAnimation.createObject(this)
                }
            }
        }

        StyledText {
            text: root.description
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            color: Appearance?.m3colors.m3onSurface
        }
    }
}