import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Loader {
    id: root
    property string icon: ""
    property real iconSize: Appearance.font.pixelSize.larger
    property color color: Appearance.colors.colOnSecondaryContainer
    property bool toggled: false
    Layout.alignment: Qt.AlignVCenter

    active: root.icon !== undefined && root.icon !== ""
    visible: active

    sourceComponent: Item {
        implicitWidth: materialSymbol.implicitWidth

        MaterialSymbol {
            id: materialSymbol
            anchors.centerIn: parent

            iconSize: root.iconSize
            color: root.color
            text: root.icon
        }
    }
}
