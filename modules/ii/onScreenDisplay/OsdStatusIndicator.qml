import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

Item {
    id: root
    required property bool active
    required property string icon
    required property string title
    property string activeText: Translation.tr("ON")
    property string inactiveText: Translation.tr("OFF")

    implicitWidth: Appearance.sizes.osdWidth + 4 * Appearance.sizes.elevationMargin
    implicitHeight: 48 + 2 * Appearance.sizes.elevationMargin

    Rectangle {
        id: statusIndicator
        anchors {
            fill: parent
            margins: Appearance.sizes.elevationMargin
        }
        radius: Appearance.rounding.full
        color: Appearance.colors.colLayer0
        border.width: 1
        border.color: Appearance.colors.colLayer0Border

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12

            MaterialSymbol {
                text: root.icon
                iconSize: 22
                color: root.active ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
            }

            StyledText {
                Layout.fillWidth: true
                text: root.title
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer0
                elide: Text.ElideRight
            }

            Rectangle {
                implicitWidth: statusText.implicitWidth + 16
                implicitHeight: 24
                radius: Appearance.rounding.full
                color: root.active ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer

                StyledText {
                    id: statusText
                    anchors.centerIn: parent
                    text: root.active ? root.activeText : root.inactiveText
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.bold: true
                    color: root.active ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                }
            }
        }
    }
}
