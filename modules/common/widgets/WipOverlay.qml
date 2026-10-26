import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property string featureId: ""
    property bool isBadgeOnly: false
    property string label: Translation.tr("Planned")
    readonly property bool isWip: WipRegistry.isWip(featureId)

    visible: isWip
    anchors.fill: isBadgeOnly ? undefined : parent
    z: 100

    // Full section/page overlay
    Item {
        id: scrim
        visible: !root.isBadgeOnly
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            preventStealing: true
            acceptedButtons: Qt.AllButtons
            onClicked: (mouse) => mouse.accepted = true
            onPressed: (mouse) => mouse.accepted = true
            onReleased: (mouse) => mouse.accepted = true
            onWheel: (wheel) => wheel.accepted = true
        }

        // Large rotated "WIP" watermark
        StyledText {
            anchors.centerIn: parent
            text: "WIP"
            font.pixelSize: 96
            font.weight: Font.Black
            color: Appearance.colors.colOnLayer0
            opacity: 0.15
            rotation: -18
        }

        // Planned pill badge with feature ID
        Rectangle {
            anchors {
                top: parent.top
                right: parent.right
                margins: 14
            }
            radius: Appearance.rounding.small
            color: Appearance.colors.colSecondaryContainer
            implicitWidth: pillRow.implicitWidth + 16
            implicitHeight: pillRow.implicitHeight + 8

            RowLayout {
                id: pillRow
                anchors.centerIn: parent
                spacing: 6

                MaterialSymbol {
                    text: "construction"
                    iconSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnSecondaryContainer
                }

                StyledText {
                    text: root.featureId !== "" ? `${root.label} (${root.featureId})` : root.label
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnSecondaryContainer
                }
            }
        }
    }

    // Row-level inline badge
    Rectangle {
        id: inlineBadge
        visible: root.isBadgeOnly
        radius: Appearance.rounding.small
        color: Appearance.colors.colSecondaryContainer
        implicitWidth: badgeRow.implicitWidth + 12
        implicitHeight: badgeRow.implicitHeight + 6

        RowLayout {
            id: badgeRow
            anchors.centerIn: parent
            spacing: 4

            MaterialSymbol {
                text: "construction"
                iconSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colOnSecondaryContainer
            }

            StyledText {
                text: Translation.tr("WIP")
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.weight: Font.Bold
                color: Appearance.colors.colOnSecondaryContainer
            }
        }
    }
}
