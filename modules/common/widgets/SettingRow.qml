import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property string rowId: ""
    property string pageKey: ""
    property string sectionTitle: ""
    property string label: ""
    property string subtitle: ""
    property string icon: ""
    property alias rowIcon: root.icon
    property string unit: ""
    property var keywords: []
    property bool requiresRestart: false
    property bool requiresRelogin: false
    property var defaultValue: undefined
    property var currentValue: undefined
    property string wipFeature: ""

    readonly property bool isWip: WipRegistry.isWip(wipFeature)
    readonly property bool isModified: defaultValue !== undefined && currentValue !== undefined && String(defaultValue) !== String(currentValue)

    signal resetRequested()

    default property alias trailingContent: controlContainer.data

    Layout.fillWidth: true
    implicitHeight: Math.max(48, mainRow.implicitHeight + 12)
    height: implicitHeight
    opacity: isWip ? 0.55 : 1.0
    enabled: !isWip

    Component.onCompleted: {
        if (root.rowId !== "") {
            SettingsSearchIndex.registerRow({
                pageKey: root.pageKey,
                sectionTitle: root.sectionTitle,
                rowId: root.rowId,
                label: root.label,
                subtitle: root.subtitle,
                keywords: root.keywords,
                isWip: root.isWip,
                targetItem: root
            })
        }
    }

    Component.onDestruction: {
        if (root.rowId !== "") {
            SettingsSearchIndex.unregisterRow(root.rowId)
        }
    }

    RowLayout {
        id: mainRow
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        spacing: 12

        // Optional leading icon
        MaterialSymbol {
            visible: root.icon !== ""
            text: root.icon
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
            Layout.alignment: Qt.AlignVCenter
        }

        // Modified dot with reset on hover
        Item {
            id: modifiedArea
            visible: root.isModified
            implicitWidth: 18
            implicitHeight: 18
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                id: dot
                anchors.centerIn: parent
                width: 6
                height: 6
                radius: 3
                color: Appearance.colors.colPrimary
                visible: !resetMouseArea.containsMouse
            }

            Rectangle {
                id: resetIcon
                anchors.fill: parent
                radius: Appearance.rounding.unsharpen
                color: resetMouseArea.containsMouse ? Appearance.colors.colSecondaryContainerHover : "transparent"
                visible: resetMouseArea.containsMouse

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "restart_alt"
                    iconSize: 14
                    color: Appearance.colors.colPrimary
                }
            }

            MouseArea {
                id: resetMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.resetRequested()
            }

            StyledToolTip {
                visible: resetMouseArea.containsMouse
                text: Translation.tr("Reset to default")
            }
        }

        // Label, tags, and subtitle
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            RowLayout {
                spacing: 8
                Layout.fillWidth: true

                StyledText {
                    text: root.label
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                    elide: Text.ElideRight
                }

                StyledText {
                    visible: root.unit !== ""
                    text: `(${root.unit})`
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                }

                // Restart tag
                Rectangle {
                    visible: root.requiresRestart
                    radius: Appearance.rounding.unsharpen
                    color: Appearance.colors.colTertiaryContainer
                    implicitWidth: restartText.implicitWidth + 8
                    implicitHeight: restartText.implicitHeight + 4

                    StyledText {
                        id: restartText
                        anchors.centerIn: parent
                        text: Translation.tr("Restart")
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnTertiaryContainer
                    }
                }

                // Re-login tag
                Rectangle {
                    visible: root.requiresRelogin
                    radius: Appearance.rounding.unsharpen
                    color: Appearance.colors.colTertiaryContainer
                    implicitWidth: reloginText.implicitWidth + 8
                    implicitHeight: reloginText.implicitHeight + 4

                    StyledText {
                        id: reloginText
                        anchors.centerIn: parent
                        text: Translation.tr("Re-login")
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnTertiaryContainer
                    }
                }

                // Inline WIP badge
                WipOverlay {
                    visible: root.isWip
                    isBadgeOnly: true
                    featureId: root.wipFeature
                }
            }

            StyledText {
                visible: root.subtitle !== ""
                text: root.subtitle
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        // Trailing control
        RowLayout {
            id: controlContainer
            Layout.alignment: Qt.AlignVCenter
            spacing: 8
        }
    }
}
