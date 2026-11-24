import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.sidebarRight.drives

DialogSheet {
    title: Translation.tr("Storage manager")
    busy: Drives.refreshing || Drives.busy || Drives.smartBusy
    leadingActions: DialogButton { buttonText: Translation.tr("Refresh"); onClicked: Drives.refresh() }
    DriveList { Layout.fillWidth: true; Layout.fillHeight: true }
}
