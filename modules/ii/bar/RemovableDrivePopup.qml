import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.sidebarRight.drives

StyledPopup {
    id: root
    signal closeRequested()
    property bool showStorageManager: false
    onActiveChanged: if (!active) root.showStorageManager = false
    dismissOnOutsideClick: true
    onDismissRequested: root.closeRequested()
    Item {
        implicitWidth: root.showStorageManager ? 420 : 340
        implicitHeight: content.implicitHeight
        ColumnLayout {
            id: content
            width: parent.width
            spacing: 12
            StyledText {
                text: root.showStorageManager ? Translation.tr("Storage manager") : Translation.tr("Removable drives")
                font.pixelSize: Appearance.font.pixelSize.larger
            }
            StyledFlickable {
                visible: !root.showStorageManager
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
                                visible: disk.modelData.kind !== "mtp"
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
            Loader {
                Layout.fillWidth: true
                Layout.preferredHeight: item ? Math.min(480, item.contentHeight) : 0
                active: root.showStorageManager
                visible: active
                sourceComponent: DriveList {}
            }
            StyledText {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                visible: !root.showStorageManager && Drives.lastError !== ""
                text: Drives.lastError
                wrapMode: Text.WrapAnywhere
                color: Appearance.m3colors.m3error
            }
            RowLayout {
                DialogButton {
                    buttonText: root.showStorageManager ? Translation.tr("Back") : Translation.tr("Storage manager")
                    onClicked: root.showStorageManager = !root.showStorageManager
                }
                DialogButton {
                    visible: root.showStorageManager
                    buttonText: Translation.tr("Refresh")
                    enabled: !Drives.refreshing
                    onClicked: Drives.refresh()
                }
                Item { Layout.fillWidth: true }
                DialogButton { buttonText: Translation.tr("Done"); onClicked: root.closeRequested() }
            }
        }
    }
}
