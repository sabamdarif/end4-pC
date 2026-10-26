import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root

    readonly property bool settingsSearchSection: true
    property string title: ""
    property string subtitle: ""
    property string icon: ""
    property var shape: MaterialShape.Shape.Clover4Leaf
    property color iconBgColor: Appearance.colors.colSecondaryContainer
    property bool collapsible: false
    property bool collapsed: false
    property string wipFeature: ""

    default property alias content: sectionRows.data

    Layout.fillWidth: true
    implicitHeight: mainLayout.implicitHeight + 28
    height: implicitHeight
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1
    border.color: Appearance.colors.colLayer0Border
    border.width: 1

    ColumnLayout {
        id: mainLayout
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 14
        }
        spacing: 12

        // Section header
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            MaterialShapeWrappedMaterialSymbol {
                visible: root.icon !== ""
                text: root.icon
                iconSize: Appearance.font.pixelSize.large
                wrappedShape: root.shape
                color: root.iconBgColor
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                StyledText {
                    text: root.title
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                }

                StyledText {
                    visible: root.subtitle !== ""
                    text: root.subtitle
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                }
            }

            // Collapse toggle if enabled
            RippleButton {
                visible: root.collapsible
                implicitWidth: 32
                implicitHeight: 32
                buttonRadius: Appearance.rounding.full
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer2Hover

                onClicked: root.collapsed = !root.collapsed

                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: root.collapsed ? "expand_more" : "expand_less"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colSubtext
                }
            }
        }

        // Rows container
        ColumnLayout {
            id: sectionRows
            Layout.fillWidth: true
            spacing: 2
            visible: !root.collapsed
        }
    }

    // WIP Overlay over the entire section when active
    WipOverlay {
        id: overlay
        featureId: root.wipFeature
    }
}
