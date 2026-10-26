import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root

    property string icon: "check_circle"
    property string title: ""
    property string subtitle: ""
    property string statusText: Translation.tr("Active")
    property string actionText: Translation.tr("Disconnect")
    property bool showAction: true
    signal actionClicked()
    signal cardClicked()

    default property alias content: extraContent.data

    Layout.fillWidth: true
    implicitHeight: mainLayout.implicitHeight + 24
    radius: Appearance.rounding.normal
    color: Appearance.colors.colPrimaryContainer

    MouseArea {
        anchors.fill: parent
        onClicked: root.cardClicked()
    }

    ColumnLayout {
        id: mainLayout
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 14
        }
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Prominent status icon
            Rectangle {
                width: 44
                height: 44
                radius: Appearance.rounding.small
                color: Appearance.colors.colPrimary
                Layout.alignment: Qt.AlignVCenter

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: root.icon
                    iconSize: Appearance.font.pixelSize.huge
                    color: Appearance.colors.colOnPrimary
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                RowLayout {
                    spacing: 8
                    Layout.fillWidth: true

                    StyledText {
                        text: root.title
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnPrimaryContainer
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        visible: root.statusText !== ""
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colPrimary
                        implicitWidth: statusLabel.implicitWidth + 10
                        implicitHeight: statusLabel.implicitHeight + 4

                        StyledText {
                            id: statusLabel
                            anchors.centerIn: parent
                            text: root.statusText
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnPrimary
                        }
                    }
                }

                StyledText {
                    visible: root.subtitle !== ""
                    text: root.subtitle
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnPrimaryContainer
                    opacity: 0.8
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Quick action button
            RippleButton {
                visible: root.showAction
                implicitHeight: 34
                implicitWidth: actionLabel.implicitWidth + 24
                buttonRadius: Appearance.rounding.small
                colBackground: Appearance.colors.colSecondaryContainer
                colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                Layout.alignment: Qt.AlignVCenter

                onClicked: root.actionClicked()

                contentItem: StyledText {
                    id: actionLabel
                    anchors.centerIn: parent
                    text: root.actionText
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnSecondaryContainer
                }
            }
        }

        // Optional extra content (details, badges, stats)
        ColumnLayout {
            id: extraContent
            visible: children.length > 0
            Layout.fillWidth: true
            spacing: 4
        }
    }
}
