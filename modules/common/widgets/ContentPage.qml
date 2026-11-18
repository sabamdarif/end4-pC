import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

StyledFlickable {
    id: root
    property real baseWidth: 600
    property real maxContentWidth: 1250
    property bool forceWidth: false
    property real bottomContentPadding: 90
    property real horizontalPadding: 24

    default property alias data: contentColumn.data

    clip: true
    contentWidth: width
    contentHeight: contentColumn.implicitHeight + root.bottomContentPadding // Add some padding at the bottom
    implicitWidth: contentColumn.implicitWidth

    // Scroll to the first section or subsection whose title matches `term`.
    // Used by the settings search and by GlobalStates.settingsPage deep links.
    function goTo(term) {
        const t = String(term ?? "").toLowerCase().trim()
        if (t === "")
            return

        function findTarget(item) {
            for (let i = 0; i < item.children.length; i++) {
                const child = item.children[i]
                if (child.title && String(child.title).toLowerCase().includes(t))
                    return child
            }
            for (let i = 0; i < item.children.length; i++) {
                const found = findTarget(item.children[i])
                if (found) return found
            }
            return null
        }

        const target = findTarget(contentColumn)
        if (target)
            root.contentY = Math.max(0, target.mapToItem(contentColumn, 0, 0).y)
    }

    ColumnLayout {
        id: contentColumn
        width: root.forceWidth
            ? root.baseWidth
            : Math.min(Math.max(400, root.width > 0 ? root.width - (root.horizontalPadding * 2) : root.baseWidth), root.maxContentWidth)
        anchors {
            top: parent.top
            topMargin: 20
            horizontalCenter: parent.horizontalCenter
        }
        spacing: 24
    }

}
