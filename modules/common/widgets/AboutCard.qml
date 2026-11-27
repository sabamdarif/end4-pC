import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root

    property string icon: ""
    property string label: ""
    property string value: ""
    property color cardBgColor: Appearance.colors.colLayer1
    property color labelColor: Appearance.colors.colOnSurfaceVariant
    property color valueColor: Appearance.colors.colOnSurface
    property color iconContainerColor: Appearance.colors.colSecondaryContainer
    property color iconColor: Appearance.colors.colOnSecondaryContainer
    property var iconShape: MaterialShape.Shape.Clover4Leaf

    property var clickAction: null
    property bool pointingHandCursor: true

    readonly property bool interactive: root.clickAction !== null
    implicitWidth: 260
    implicitHeight: 80

    RippleButton {
        anchors.fill: parent
        horizontalPadding: 16
        verticalPadding: 12
        buttonRadius: Appearance.rounding.large
        buttonRadiusPressed: root.interactive ? Appearance.rounding.small : Appearance.rounding.large
        pointingHandCursor: root.interactive && root.pointingHandCursor
        rippleEnabled: root.interactive
        colBackground: root.cardBgColor
        colBackgroundHover: root.interactive ? Appearance.colors.colLayer1Hover : root.cardBgColor
        colRipple: Appearance.colors.colLayer1Active
        onClicked: {
            if (root.clickAction) root.clickAction();
        }

        contentItem: RowLayout {
            id: cardRow
            spacing: 16

            MaterialShapeWrappedMaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                wrappedShape: root.iconShape
                text: root.icon
                iconSize: Appearance.font.pixelSize.larger + 1
                colSymbol: root.iconColor
                color: root.iconContainerColor
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 4

                StyledText {
                    Layout.fillWidth: true
                    text: root.label
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: root.labelColor
                    elide: Text.ElideRight
                    opacity: 0.6
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.value
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.DemiBold
                    color: root.valueColor
                    elide: Text.ElideRight
                    animateChange: true
                }
            }
        }
    }
}