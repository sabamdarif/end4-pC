import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

StyledFlickable {
    id: root

    property string title: ""
    property string subtitle: ""
    property var tabs: []
    property int currentTab: 0
    property real maxContentWidth: 760
    property real bottomContentPadding: 90
    property string wipFeature: ""

    default property alias data: sectionsColumn.data
    property alias headerActions: headerActionsContainer.data

    width: parent ? parent.width : maxContentWidth
    height: parent ? parent.height : 600
    implicitWidth: maxContentWidth

    clip: true
    contentWidth: width
    contentHeight: Math.max(root.height, contentColumn.implicitHeight + root.bottomContentPadding + 40)

    function goTo(term) {
        const t = String(term ?? "").toLowerCase().trim()
        if (t === "") return

        function findTarget(item) {
            if (!item || !item.children) return null
            for (let i = 0; i < item.children.length; i++) {
                const child = item.children[i]
                if (child.rowId && String(child.rowId).toLowerCase() === t) return child
                if (child.title && String(child.title).toLowerCase().includes(t)) return child
                if (child.label && String(child.label).toLowerCase().includes(t)) return child
            }
            for (let i = 0; i < item.children.length; i++) {
                const found = findTarget(item.children[i])
                if (found) return found
            }
            return null
        }

        const target = findTarget(sectionsColumn)
        if (target) {
            root.contentY = Math.max(0, target.mapToItem(contentColumn, 0, 0).y)
        }
    }

    ColumnLayout {
        id: contentColumn
        width: Math.min(Math.max(root.width - 40, 200), root.maxContentWidth)
        anchors {
            top: parent.top
            topMargin: 20
            horizontalCenter: parent.horizontalCenter
        }
        spacing: 20

        // Page Header
        RowLayout {
            visible: root.title !== ""
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    text: root.title
                    font.pixelSize: Appearance.font.pixelSize.huge
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer0
                }

                StyledText {
                    visible: root.subtitle !== ""
                    text: root.subtitle
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                id: headerActionsContainer
                spacing: 8
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Tabs
        Rectangle {
            visible: root.tabs && root.tabs.length > 0
            Layout.fillWidth: true
            implicitHeight: 40
            radius: Appearance.rounding.small
            color: Appearance.colors.colLayer1

            RowLayout {
                anchors.centerIn: parent
                spacing: 4

                Repeater {
                    model: root.tabs
                    delegate: RippleButton {
                        required property int index
                        required property var modelData

                        readonly property bool isSelected: root.currentTab === index
                        implicitHeight: 34
                        implicitWidth: Math.max(80, tabLabel.implicitWidth + 24)
                        buttonRadius: Appearance.rounding.unsharpenmore

                        colBackground: isSelected ? Appearance.colors.colPrimary : "transparent"
                        colBackgroundHover: isSelected ? Appearance.colors.colPrimaryHover : Appearance.colors.colLayer2Hover
                        colRipple: isSelected ? Appearance.colors.colPrimaryActive : Appearance.colors.colLayer2Active

                        contentItem: StyledText {
                            id: tabLabel
                            anchors.centerIn: parent
                            text: String(modelData)
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.weight: isSelected ? Font.DemiBold : Font.Normal
                            color: isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                        }

                        onClicked: root.currentTab = index
                    }
                }
            }
        }

        // Sections container
        ColumnLayout {
            id: sectionsColumn
            Layout.fillWidth: true
            spacing: 20
        }
    }

    // Page-level WIP Overlay
    WipOverlay {
        id: pageWipOverlay
        featureId: root.wipFeature
    }
}
