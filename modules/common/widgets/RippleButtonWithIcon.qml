import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

RippleButton {
    id: buttonWithIconRoot
    property string nerdIcon
    property string materialIcon
    property bool materialIconFill: true
    property string mainText: "Button text"
    property Component mainContentComponent: Component {
        StyledText {
            visible: text !== ""
            text: buttonWithIconRoot.mainText
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.Medium
            color: buttonWithIconRoot.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer2
        }
    }
    implicitHeight: 38
    horizontalPadding: 14
    buttonRadius: Appearance.rounding.full
    buttonRadiusPressed: Appearance.rounding.small
    colBackground: Appearance.colors.colLayer2
    colBackgroundHover: Appearance.colors.colLayer2Hover
    colRipple: Appearance.colors.colLayer2Active
    colBackgroundToggled: Appearance.colors.colSecondaryContainer
    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
    colRippleToggled: Appearance.colors.colSecondaryContainerActive

    contentItem: RowLayout {
        Item {
            Layout.fillWidth: false
            implicitWidth: Math.max(materialIconLoader.implicitWidth, nerdIconLoader.implicitWidth)
            Loader {
                id: materialIconLoader
                anchors.centerIn: parent
                active: !nerdIcon
                sourceComponent: MaterialSymbol {
                    text: buttonWithIconRoot.materialIcon
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnSecondaryContainer
                    fill: buttonWithIconRoot.materialIconFill ? 1 : 0
                }
            }
            Loader {
                id: nerdIconLoader
                anchors.centerIn: parent
                active: nerdIcon
                sourceComponent: StyledText {
                    text: buttonWithIconRoot.nerdIcon
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.family: Appearance.font.family.iconNerd
                    color: Appearance.colors.colOnSecondaryContainer
                }
            }
        }
        Loader {
            Layout.fillWidth: true
            sourceComponent: buttonWithIconRoot.mainContentComponent
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
