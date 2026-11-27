import qs.modules.common.widgets
import qs.modules.common
import QtQuick
import QtQuick.Layouts
import qs.services

ColumnLayout {
    id: root
    spacing: 6
    Layout.fillWidth: true
    Layout.leftMargin: 8
    Layout.rightMargin: 8

    property string text: ""
    property string buttonIcon: ""
    property alias configuration: slider.configuration
    property alias value: slider.value
    property alias stepSize: slider.stepSize
    property alias stopIndicatorValues: slider.stopIndicatorValues
    property bool usePercentTooltip: true
    property real from: slider.from
    property real to: slider.to
    property real textWidth: 120
    property bool showLabel: true
    signal moved()

    RowLayout {
        id: row
        visible: root.showLabel
        Layout.fillWidth: true
        spacing: 10

        OptionalMaterialSymbol {
            id: iconWidget
            icon: root.buttonIcon
            iconSize: Appearance.font.pixelSize.larger
        }
        StyledText {
            id: labelWidget
            Layout.fillWidth: true
            text: root.text
            color: Appearance.colors.colOnSecondaryContainer
            elide: Text.ElideRight
        }
    }
    StyledSlider {
        id: slider
        Layout.fillWidth: true
        configuration: StyledSlider.Configuration.S
        usePercentTooltip: root.usePercentTooltip
        value: root.value
        from: root.from
        to: root.to
        onMoved: root.moved()
    }
}