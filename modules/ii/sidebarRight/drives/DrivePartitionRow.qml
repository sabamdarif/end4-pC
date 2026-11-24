import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ColumnLayout {
    id: root
    required property var partition
    Layout.fillWidth: true
    spacing: 4
    RowLayout {
        Layout.fillWidth: true
        RippleButton {
            Layout.fillWidth: true
            implicitHeight: 52
            buttonRadius: Appearance.rounding.small
            enabled: !Drives.busy
            onClicked: Drives.openPartition(root.partition.device)
            contentItem: ColumnLayout {
                StyledText {
                    Layout.fillWidth: true
                    text: root.partition.kind === "mtp" ? Translation.tr("Phone: %1").arg(root.partition.label) : root.partition.label
                    elide: Text.ElideRight
                }
                StyledText {
                    Layout.fillWidth: true
                    text: root.partition.kind === "mtp" ? "MTP • " + (root.partition.mountPoint ? Translation.tr("Connected") : Translation.tr("Not mounted"))
                        : Drives.formatBytes(root.partition.size) + " • " + (root.partition.filesystem || Translation.tr("Unknown filesystem"))
                        + " • " + (root.partition.mountPoint || Translation.tr("Not mounted"))
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideMiddle
                }
            }
        }
        RippleButtonWithIcon {
            visible: root.partition.mountPoint !== ""
            materialIcon: "eject"
            mainText: ""
            enabled: !Drives.busy
            onClicked: Drives.unmountPartition(root.partition.device)
            StyledToolTip { text: root.partition.kind === "mtp" ? Translation.tr("Disconnect phone") : Translation.tr("Unmount") }
        }
    }
    StyledProgressBar {
        Layout.fillWidth: true
        visible: root.partition.total !== null && root.partition.mountPoint !== ""
        value: root.partition.usage
    }
    StyledText {
        Layout.fillWidth: true
        visible: root.partition.total !== null && root.partition.mountPoint !== ""
        text: Translation.tr("%1 used • %2 available").arg(Drives.formatBytes(root.partition.used)).arg(Drives.formatBytes(root.partition.free))
        font.pixelSize: Appearance.font.pixelSize.smaller
        color: Appearance.colors.colSubtext
    }
}
