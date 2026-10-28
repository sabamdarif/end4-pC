import qs.modules.common
import QtQuick
import QtQuick.Controls

/**
 * Does not include visual layout, but includes the easily neglected colors.
 */
TextInput {
    id: root

    property string placeholderText: ""
    property color placeholderTextColor: Appearance.m3colors.m3outline

    color: Appearance.colors.colOnLayer1
    renderType: Text.NativeRendering
    selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
    selectionColor: Appearance.colors.colSecondaryContainer
    font {
        family: Appearance.font.family.main
        pixelSize: Appearance?.font.pixelSize.small ?? 15
        hintingPreference: Font.PreferFullHinting
        variableAxes: Appearance.font.variableAxes.main
    }

    Text {
        anchors.fill: parent
        anchors.leftMargin: root.leftPadding
        anchors.rightMargin: root.rightPadding
        anchors.topMargin: root.topPadding
        anchors.bottomMargin: root.bottomPadding
        text: root.placeholderText
        visible: root.text.length === 0 && !root.inputMethodComposing
        color: root.placeholderTextColor
        font: root.font
        renderType: root.renderType
        verticalAlignment: root.verticalAlignment
        horizontalAlignment: root.horizontalAlignment
        elide: Text.ElideRight
        enabled: false
    }
}
