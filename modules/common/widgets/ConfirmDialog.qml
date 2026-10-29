import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property string title: Translation.tr("Confirm Deletion")
    property string targetName: ""
    property string message: Translation.tr("Are you sure you want to remove \"%1\"? This action cannot be undone.").arg(targetName)
    property string confirmText: Translation.tr("Delete")
    property string cancelText: Translation.tr("Cancel")
    property bool isDestructive: true

    signal confirmed()
    signal cancelled()

    visible: false
    anchors.fill: parent
    z: 200

    function open(name) {
        if (name !== undefined) root.targetName = name
        root.visible = true
    }

    function close() {
        root.visible = false
    }

    // Scrim overlay
    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.colScrim
        opacity: root.visible ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            preventStealing: true
            onClicked: {
                root.cancelled()
                root.close()
            }
        }
    }

    // Dialog card
    Rectangle {
        id: dialogCard
        WindowGlass {
            anchors.fill: parent
            cardRadius: parent?.radius ?? 0
            tint: parent?.color ?? 'transparent'
        }
        anchors.centerIn: parent
        width: Math.min(parent.width - 40, 420)
        implicitHeight: cardLayout.implicitHeight + 36
        radius: Appearance.rounding.large
        color: Appearance.colors.colLayer1Blurred
        border.color: Appearance.colors.colLayer0Border
        border.width: 1

        scale: root.visible ? 1.0 : 0.95
        Behavior on scale {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            preventStealing: true
        }

        ColumnLayout {
            id: cardLayout
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 20
            }
            spacing: 16

            RowLayout {
                spacing: 12
                Layout.fillWidth: true

                Rectangle {
                    width: 36
                    height: 36
                    radius: Appearance.rounding.small
                    color: root.isDestructive ? Appearance.colors.colErrorContainer : Appearance.colors.colSecondaryContainer
                    Layout.alignment: Qt.AlignVCenter

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: root.isDestructive ? "warning" : "info"
                        iconSize: Appearance.font.pixelSize.large
                        color: root.isDestructive ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnSecondaryContainer
                    }
                }

                StyledText {
                    text: root.title
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer2
                    Layout.fillWidth: true
                }
            }

            StyledText {
                text: root.message
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                spacing: 10

                Item { Layout.fillWidth: true }

                RippleButton {
                    implicitHeight: 38
                    implicitWidth: cancelLabel.implicitWidth + 24
                    buttonRadius: Appearance.rounding.small
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer1Hover

                    onClicked: {
                        root.cancelled()
                        root.close()
                    }

                    contentItem: StyledText {
                        id: cancelLabel
                        anchors.centerIn: parent
                        text: root.cancelText
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer2
                    }
                }

                RippleButton {
                    implicitHeight: 38
                    implicitWidth: confirmLabel.implicitWidth + 24
                    buttonRadius: Appearance.rounding.small
                    colBackground: root.isDestructive ? Appearance.colors.colError : Appearance.colors.colPrimary
                    colBackgroundHover: root.isDestructive ? Appearance.colors.colErrorHover : Appearance.colors.colPrimaryHover

                    onClicked: {
                        root.confirmed()
                        root.close()
                    }

                    contentItem: StyledText {
                        id: confirmLabel
                        anchors.centerIn: parent
                        text: root.confirmText
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.DemiBold
                        color: root.isDestructive ? Appearance.colors.colOnError : Appearance.colors.colOnPrimary
                    }
                }
            }
        }
    }
}
