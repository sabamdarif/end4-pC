pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell

/**
 * One row in the clipboard manager: index badge, thumbnail or type icon,
 * preview text and the pin/copy/delete actions.
 */
Item {
    id: root

    required property var row
    required property int itemIndex
    property bool selected: false
    property string sectionLabel: ""

    signal selectRequested
    signal copyRequested
    signal deleteRequested
    signal pinRequested

    readonly property real itemHeight: Appearance.sizes.clipboardItemHeight
    readonly property real thumbnailHeight: Math.min(Config.options.clipboard.imagePreviewHeight, root.itemHeight - 8)
    readonly property bool isImage: root.row?.isImage ?? false
    readonly property bool isOrphanPin: (root.row?.entry ?? "") === ""

    readonly property string typeLabel: {
        if (root.isImage)
            return Translation.tr("Image");
        const label = String(root.row?.label ?? "");
        if (/^file:\/\//.test(label))
            return Translation.tr("File");
        if (/^https?:\/\//.test(label))
            return Translation.tr("Link");
        return Translation.tr("Text");
    }

    readonly property string typeIcon: {
        if (root.isImage)
            return "image";
        const label = String(root.row?.label ?? "");
        if (/^file:\/\//.test(label))
            return "folder";
        if (/^https?:\/\//.test(label))
            return "link";
        return "text_fields";
    }

    implicitHeight: (root.sectionLabel !== "" ? sectionText.implicitHeight + 8 : 0) + root.itemHeight

    StyledText {
        id: sectionText
        visible: root.sectionLabel !== ""
        anchors {
            top: parent.top
            left: parent.left
            leftMargin: 6
        }
        text: root.sectionLabel
        font.pixelSize: Appearance.font.pixelSize.smaller
        color: Appearance.colors.colSubtext
    }

    Rectangle {
        id: itemBackground
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: root.itemHeight
        radius: Appearance.rounding.small
        color: root.selected ? Appearance.colors.colPrimaryContainer : (mouseArea.containsMouse ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1)

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.selectRequested()
            onClicked: root.copyRequested()
        }

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 10
                rightMargin: 6
            }
            spacing: 10

            StyledText { // Index badge
                visible: Config.options.clipboard.showIndexNumbers && root.row?.id !== ""
                Layout.preferredWidth: 38
                text: root.row?.id ?? ""
                horizontalAlignment: Text.AlignRight
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: root.selected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
            }

            Loader { // Image thumbnail straight out of cliphist
                active: root.isImage && !root.isOrphanPin
                visible: active
                Layout.preferredWidth: root.thumbnailHeight * 4 / 3
                Layout.preferredHeight: root.thumbnailHeight

                sourceComponent: CliphistImage {
                    entry: root.row?.entry ?? ""
                    maxWidth: root.thumbnailHeight * 4 / 3
                    maxHeight: root.thumbnailHeight
                    cropToFit: true
                    keepDecoded: true
                    blur: root.row?.blur ?? false
                }
            }

            Loader { // Pinned image whose cliphist entry is gone
                active: root.isImage && root.isOrphanPin
                visible: active
                Layout.preferredWidth: root.thumbnailHeight * 4 / 3
                Layout.preferredHeight: root.thumbnailHeight

                sourceComponent: StyledImage {
                    source: Qt.resolvedUrl(root.row?.pin?.imagePath ?? "")
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    antialiasing: true
                    sourceSize.height: root.thumbnailHeight * 2
                }
            }

            MaterialSymbol { // Type icon for everything that isn't an image
                visible: !root.isImage
                text: root.typeIcon
                iconSize: 22
                color: root.selected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
            }

            ColumnLayout { // Content
                Layout.fillWidth: true
                spacing: 1

                StyledText {
                    Layout.fillWidth: true
                    text: root.isImage ? `${root.typeLabel} · ${root.row?.label ?? ""}`.replace(/\[\[\s*binary data\s*|\s*\]\]/g, "") : root.typeLabel
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: root.selected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colPrimary
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: !root.isImage
                    text: root.row?.label ?? ""
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: root.selected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
                    textFormat: Text.PlainText
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                }
            }

            RowLayout { // Actions
                spacing: 0
                opacity: (root.selected || mouseArea.containsMouse || pinButton.hovered || copyButton.hovered || deleteButton.hovered) ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                RippleButton {
                    id: pinButton
                    implicitWidth: 36
                    implicitHeight: 36
                    buttonRadius: Appearance.rounding.full
                    onClicked: root.pinRequested()

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "keep"
                        iconSize: 19
                        fill: (root.row?.pinned ?? false) ? 1 : 0
                        color: (root.row?.pinned ?? false) ? Appearance.colors.colPrimary : (root.selected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext)
                    }

                    StyledToolTip {
                        text: (root.row?.pinned ?? false) ? Translation.tr("Unpin") : Translation.tr("Pin")
                    }
                }

                RippleButton {
                    id: copyButton
                    implicitWidth: 36
                    implicitHeight: 36
                    buttonRadius: Appearance.rounding.full
                    onClicked: root.copyRequested()

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "content_copy"
                        iconSize: 19
                        color: root.selected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                    }

                    StyledToolTip {
                        text: Translation.tr("Copy")
                    }
                }

                RippleButton {
                    id: deleteButton
                    implicitWidth: 36
                    implicitHeight: 36
                    buttonRadius: Appearance.rounding.full
                    onClicked: root.deleteRequested()

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "delete"
                        iconSize: 19
                        color: root.selected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                    }

                    StyledToolTip {
                        text: Translation.tr("Delete")
                    }
                }
            }
        }
    }
}
