import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.sidebarRight.drives

StyledPopup {
    id: root
    signal closeRequested()
    dismissOnOutsideClick: true
    onDismissRequested: root.closeRequested()
    ColumnLayout {
        implicitWidth: 340
        spacing: 12
        StyledText { text: Translation.tr("Removable drives"); font.pixelSize: Appearance.font.pixelSize.larger }
        StyledFlickable {
            Layout.fillWidth: true
            implicitHeight: Math.min(360, volumes.implicitHeight)
            contentHeight: volumes.implicitHeight
            clip: true
            ColumnLayout {
                id: volumes
                width: parent.width
                spacing: 12
                StyledText { visible: !Drives.hasRemovableDrives; text: Translation.tr("No removable drives connected") }
                Repeater {
                    model: Drives.removableDrives
                    delegate: ColumnLayout {
                        id: disk
                        required property var modelData
                        Layout.fillWidth: true
                        RowLayout {
                            Layout.fillWidth: true
                            StyledText { Layout.fillWidth: true; text: disk.modelData.model || disk.modelData.name; elide: Text.ElideRight }
                            RippleButtonWithIcon {
                                materialIcon: "eject"
                                mainText: ""
                                enabled: !Drives.busy
                                onClicked: Drives.ejectDrive(disk.modelData.device)
                                StyledToolTip { text: Translation.tr("Safely eject drive") }
                            }
                        }
                        Repeater {
                            model: disk.modelData.partitions
                            delegate: DrivePartitionRow { required property var modelData; partition: modelData }
                        }
                    }
                }
            }
        }
        StyledText { Layout.fillWidth: true; visible: Drives.lastError !== ""; text: Drives.lastError; wrapMode: Text.Wrap }
        RowLayout {
            DialogButton {
                buttonText: Translation.tr("Storage manager")
                onClicked: { root.closeRequested(); GlobalStates.openSidebarDialog("drives"); }
            }
            Item { Layout.fillWidth: true }
            DialogButton { buttonText: Translation.tr("Done"); onClicked: root.closeRequested() }
        }
    }
}
