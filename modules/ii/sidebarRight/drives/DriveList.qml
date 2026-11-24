import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.sidebarRight.drives

StyledFlickable {
    id: root
    Component.onCompleted: { Drives.subscribers++; Drives.refresh(); }
    Component.onDestruction: Drives.subscribers--
    clip: true
    contentHeight: disks.implicitHeight
    ColumnLayout {
        id: disks
        width: parent.width
        spacing: 16
        StyledText {
            Layout.fillWidth: true
            visible: Drives.lastError !== ""
            text: Drives.lastError
            wrapMode: Text.WrapAnywhere
            color: Appearance.m3colors.m3error
        }
        StyledText { visible: Drives.allDrives.length === 0; text: Translation.tr("No drives found") }
        Repeater {
            model: Drives.allDrives
            delegate: ColumnLayout {
                id: disk
                required property var modelData
                readonly property var health: Drives.smartData[modelData.device]
                Layout.fillWidth: true
                spacing: 8
                StyledText {
                    visible: disk.modelData.kind !== "mtp"
                    Layout.fillWidth: true
                    text: (disk.modelData.model || disk.modelData.name) + " • " + disk.modelData.bus
                    font.weight: Font.Medium
                    wrapMode: Text.Wrap
                }
                StyledText {
                    visible: disk.modelData.kind !== "mtp"
                    text: Drives.formatBytes(disk.modelData.size) + " • " + (disk.modelData.removable ? Translation.tr("Removable") : Translation.tr("Internal"))
                }
                RowLayout {
                    visible: disk.modelData.kind !== "mtp"
                    Layout.fillWidth: true
                    spacing: 2
                    Repeater {
                        model: disk.modelData.partitions
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredWidth: Math.max(1, modelData.size / Math.max(1, disk.modelData.size) * 280)
                            implicitHeight: 12
                            radius: 4
                            color: Appearance.colors.colSecondaryContainer
                            Rectangle {
                                width: parent.width * modelData.usage
                                height: parent.height
                                radius: parent.radius
                                color: Appearance.colors.colPrimary
                            }
                        }
                    }
                }
                Repeater {
                    model: disk.modelData.partitions
                    delegate: DrivePartitionRow { required property var modelData; partition: modelData }
                }
                StyledText {
                    Layout.fillWidth: true
                    visible: !!disk.health
                    color: disk.health?.status === "critical" ? Appearance.m3colors.m3error : Appearance.colors.colOnLayer1
                    text: {
                        if (!disk.health) return "";
                        const labels = { ok: Translation.tr("OK"), warning: Translation.tr("Warning"),
                            critical: Translation.tr("Critical"), unknown: Translation.tr("Unknown") };
                        let parts = [Translation.tr("Health: %1").arg(labels[disk.health.status])];
                        if (disk.health.temperature !== null) parts.push(Translation.tr("%1 °C").arg(disk.health.temperature));
                        if (disk.health.wear !== null) parts.push(Translation.tr("%1% lifetime used").arg(disk.health.wear));
                        if (disk.health.powerOnHours !== null) parts.push(Translation.tr("%1 power-on hours").arg(disk.health.powerOnHours));
                        return parts.join(" • ");
                    }
                    wrapMode: Text.Wrap
                }
                RowLayout {
                    visible: disk.modelData.kind !== "mtp"
                    RippleButtonWithIcon {
                        materialIcon: "health_and_safety"
                        mainText: Translation.tr("Check health")
                        enabled: !Drives.smartBusy
                        onClicked: Drives.checkHealth(disk.modelData.device)
                    }
                    RippleButtonWithIcon {
                        visible: disk.modelData.removable
                        materialIcon: "eject"
                        mainText: Translation.tr("Safely eject")
                        enabled: !Drives.busy
                        onClicked: Drives.ejectDrive(disk.modelData.device)
                    }
                }
                WindowDialogSeparator {}
            }
        }
    }
}
