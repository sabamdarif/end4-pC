import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root

    property bool vertical: false
    readonly property bool isMaterial: Config.options.bar.cornerStyle === 3
    readonly property bool cameraActive: Privacy.cameraShown && Privacy.cameraInUse
    readonly property bool micActive: Privacy.micShown && Privacy.micInUse
    readonly property bool screenShareActive: Privacy.screenShareShown && Privacy.screenSharing
    readonly property color iconColor: root.isMaterial ? Appearance.colors.colOnErrorContainer : Appearance.colors.colError

    hoverEnabled: !Config.options.bar.tooltips.clickToShow
    acceptedButtons: Qt.NoButton
    implicitWidth: vertical ? Appearance.sizes.verticalBarWidth : (contentLoader.item?.implicitWidth ?? 0) + 8
    implicitHeight: vertical ? (contentLoader.item?.implicitHeight ?? 0) + 8 : Appearance.sizes.barHeight

    component PrivacySymbol: MaterialSymbol {
        Layout.alignment: Qt.AlignCenter
        iconSize: Appearance.font.pixelSize.larger
        color: root.iconColor
    }

    Loader {
        id: contentLoader
        anchors.centerIn: parent
        sourceComponent: root.vertical ? columnContent : rowContent
    }

    Component {
        id: rowContent

        RowLayout {
            spacing: 4

            PrivacySymbol {
                visible: root.cameraActive
                text: "videocam"
            }

            PrivacySymbol {
                visible: root.micActive
                text: "mic"
            }

            PrivacySymbol {
                visible: root.screenShareActive
                text: "screen_share"
            }
        }
    }

    Component {
        id: columnContent

        ColumnLayout {
            spacing: 2

            PrivacySymbol {
                visible: root.cameraActive
                text: "videocam"
            }

            PrivacySymbol {
                visible: root.micActive
                text: "mic"
            }

            PrivacySymbol {
                visible: root.screenShareActive
                text: "screen_share"
            }
        }
    }

    PrivacyPopup {
        hoverTarget: root
    }
}
