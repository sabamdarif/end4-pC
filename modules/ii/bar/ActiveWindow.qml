import qs
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import QtQuick.Controls
import Quickshell.Wayland
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property bool vertical: false
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    property var biggestWindow: NiriData.biggestWindowForWorkspace(NiriData.activeWorkspaceId)

    property string activeAppClass: {
        if (!root.activeWindow?.activated)
            return root.biggestWindow?.app_id ?? ""
        return root.activeWindow?.appId ?? root.biggestWindow?.app_id ?? ""
    }

    property var mainAppIconSource: {
        if (!root.activeAppClass || root.activeAppClass === "")
            return Quickshell.iconPath("user-desktop", "image-missing")
        return Quickshell.iconPath(AppSearch.guessIcon(root.activeAppClass), 
            Quickshell.iconPath("user-desktop", "image-missing"))     // ← fallback Desktop
    }

    implicitWidth:  vertical ? Appearance.sizes.verticalBarWidth : Math.min(colLayout.implicitWidth + 6, 280)
    implicitHeight: vertical ? iconItem.implicitHeight : Appearance.sizes.barHeight

    // Vertical
    Item {
        id: iconItem
        visible: root.vertical
        anchors.centerIn: parent
        implicitWidth: 22
        implicitHeight: 22

        IconImage {
            anchors.centerIn: parent
            source: root.mainAppIconSource
            implicitSize: 18
            visible: root.mainAppIconSource !== ""
        }
    }

    // Horizontal
    ColumnLayout {
        id: colLayout
        visible: !root.vertical
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 3
        spacing: -4

        StyledText {
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            elide: Text.ElideRight
            text: root.activeWindow?.activated && root.biggestWindow ?
                root.activeWindow?.appId :
                root.biggestWindow?.app_id ?? Translation.tr("Desktop")
        }
        StyledText {
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer0
            elide: Text.ElideRight
            text: root.activeWindow?.activated && root.biggestWindow ?
                root.activeWindow?.title :
                (root.biggestWindow?.title) ?? `${Translation.tr("Workspace")} ${NiriData.activeWorkspaceIdx}`
        }
    }
}