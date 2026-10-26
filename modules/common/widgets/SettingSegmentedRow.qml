import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

SettingRow {
    id: root

    property var options: []
    property var value: undefined
    signal selected(var val)

    currentValue: root.value

    onResetRequested: {
        if (defaultValue !== undefined) {
            root.value = defaultValue
            root.selected(defaultValue)
        }
    }

    Rectangle {
        id: segmentBar
        radius: Appearance.rounding.small
        color: Appearance.colors.colLayer2
        implicitWidth: segmentRow.implicitWidth + 4
        implicitHeight: 36
        Layout.alignment: Qt.AlignVCenter

        RowLayout {
            id: segmentRow
            anchors.centerIn: parent
            spacing: 2

            Repeater {
                model: root.options
                delegate: RippleButton {
                    required property int index
                    required property var modelData

                    readonly property var optValue: (modelData && typeof modelData === "object" && "value" in modelData) ? modelData.value : modelData
                    readonly property string optLabel: (modelData && typeof modelData === "object" && "label" in modelData) ? modelData.label : String(modelData)
                    readonly property bool isSelected: String(root.value) === String(optValue)
                    readonly property bool isFirst: index === 0
                    readonly property bool isLast: index === root.options.length - 1

                    implicitHeight: 32
                    implicitWidth: Math.max(56, labelText.implicitWidth + 20)
                    buttonRadius: Appearance.rounding.unsharpenmore

                    colBackground: isSelected ? Appearance.colors.colPrimary : "transparent"
                    colBackgroundHover: isSelected ? Appearance.colors.colPrimaryHover : Appearance.colors.colLayer2Hover
                    colRipple: isSelected ? Appearance.colors.colPrimaryActive : Appearance.colors.colLayer2Active

                    contentItem: StyledText {
                        id: labelText
                        anchors.centerIn: parent
                        text: optLabel
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: isSelected ? Font.DemiBold : Font.Normal
                        color: isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
                    }

                    onClicked: {
                        root.value = optValue
                        root.selected(optValue)
                    }
                }
            }
        }
    }
}
