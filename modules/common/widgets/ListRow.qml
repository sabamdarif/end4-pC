import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property string trailingText: ""
    property bool showChevron: true
    signal clicked()
    signal chevronClicked()

    default property alias secondaryActions: secondaryRow.data

    Layout.fillWidth: true
    implicitHeight: Math.max(52, contentRow.implicitHeight + 16)
    radius: Appearance.rounding.small
    color: mouseArea.containsMouse ? Appearance.colors.colLayer1Hover : "transparent"

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    RowLayout {
        id: contentRow
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            margins: 12
        }
        spacing: 12

        MaterialSymbol {
            visible: root.icon !== ""
            text: root.icon
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            StyledText {
                text: root.title
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            StyledText {
                visible: root.subtitle !== ""
                text: root.subtitle
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        StyledText {
            visible: root.trailingText !== ""
            text: root.trailingText
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            Layout.alignment: Qt.AlignVCenter
        }

        // Secondary actions, visible on hover only
        RowLayout {
            id: secondaryRow
            visible: mouseArea.containsMouse && children.length > 0
            spacing: 6
            Layout.alignment: Qt.AlignVCenter
        }

        // Chevron
        RippleButton {
            visible: root.showChevron
            implicitWidth: 32
            implicitHeight: 32
            buttonRadius: Appearance.rounding.full
            colBackground: "transparent"
            colBackgroundHover: Appearance.colors.colLayer2Hover
            Layout.alignment: Qt.AlignVCenter

            onClicked: root.chevronClicked()

            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: "chevron_right"
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colSubtext
            }
        }
    }
}
