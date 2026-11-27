import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

RowLayout {
    id: root
    Layout.fillWidth: true
    Layout.leftMargin: 8
    Layout.rightMargin: 8
    spacing: 10

    property string icon: "palette"
    property string text: Translation.tr("Color")
    property string currentValue: ""
    property var options: ["primary", "secondary", "tertiary", "primaryContainer", "secondaryContainer", "tertiaryContainer", "layer1", "layer0"]
    property bool showLabel: true
    property real itemSpacing: 10
    signal selected(string newValue)

    MaterialSymbol {
        visible: root.showLabel
        text: root.icon
        iconSize: Appearance.font.pixelSize.normal + 5
        color: Appearance.colors.colOnLayer1
    }

    StyledText {
        visible: root.showLabel
        text: root.text
        font.pixelSize: Appearance.font.pixelSize.normal
        color: Appearance.colors.colOnLayer1
    }

    Item {
        visible: root.showLabel
        Layout.fillWidth: true
    }

    Flow {
        Layout.fillWidth: !root.showLabel
        Layout.preferredWidth: root.showLabel ? implicitWidth : -1
        spacing: root.itemSpacing

        Repeater {
            model: root.options
            delegate: RippleButton {
                id: slot
                required property string modelData
                readonly property bool isSelected: root.currentValue === modelData

                implicitWidth: 40
                implicitHeight: 40
                buttonRadius: Appearance.rounding.full
                buttonRadiusPressed: Appearance.rounding.small
                colBackground: "transparent"
                onClicked: root.selected(slot.modelData)

                contentItem: Item {
                    anchors.fill: parent

                    Rectangle {
                        id: ring
                        anchors.centerIn: parent
                        width: slot.isSelected ? parent.width : parent.width - 8
                        height: slot.isSelected ? parent.height : parent.height - 8
                        radius: slot.isSelected ? Appearance.rounding.normal : width / 2
                        color: "transparent"
                        border.width: slot.isSelected ? 2 : 0
                        border.color: Appearance.colors.colOnLayer0

                        Behavior on radius {
                            animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
                        }
                        Behavior on width {
                            animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
                        }
                        Behavior on height {
                            animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
                        }
                    }

                    Rectangle {
                        id: swatch
                        anchors.centerIn: parent
                        width: parent.width - 8
                        height: parent.height - 8
                        radius: slot.isSelected ? Appearance.rounding.normal - 4 : width / 2
                        color: Appearance.colors["col" + slot.modelData.charAt(0).toUpperCase() + slot.modelData.slice(1)]

                        Behavior on radius {
                            animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
                        }
                    }
                }

                StyledToolTip {
                    text: slot.modelData
                }
            }
        }
    }
}