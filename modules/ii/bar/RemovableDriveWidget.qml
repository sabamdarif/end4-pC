import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

MouseArea {
    id: root
    property bool vertical: false
    property bool popupOpen: false
    // Each output has an active workspace; only one workspace is focused.
    readonly property int focusedWorkspaceId: NiriData.workspaces.find(ws => ws.is_focused)?.id ?? -1
    onFocusedWorkspaceIdChanged: root.popupOpen = false
    implicitWidth: vertical ? Appearance.sizes.verticalBarWidth : content.implicitWidth + 12
    implicitHeight: vertical ? 36 : Appearance.sizes.barHeight
    onClicked: { popupOpen = !popupOpen; if (popupOpen) Drives.refresh(); }
    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: 4
        MaterialSymbol { text: "usb"; iconSize: Appearance.font.pixelSize.larger }
        StyledText { text: String(Drives.removableVolumeCount); visible: !root.vertical || Drives.removableVolumeCount > 0 }
    }
    RemovableDrivePopup {
        hoverTarget: root
        active: root.popupOpen
        onCloseRequested: root.popupOpen = false
    }
}
