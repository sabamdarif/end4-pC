import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    Component.onCompleted: NetworkExtras.refresh()

    ContentSection {
        icon: "shield"
        shape: MaterialShape.Shape.Clover8Leaf
        title: Translation.tr("Blocky (DNS proxy)")

        NoticeBox {
            visible: !NetworkExtras.blockyPresent
            Layout.fillWidth: true
            text: Translation.tr("Blocky is not installed. Install the blocky package to manage the DNS proxy from here.")
        }

        GroupedList {
            visible: NetworkExtras.blockyPresent
            RowLayout {
                id: blockyRow
                property bool confirming: false
                spacing: 10
                Layout.leftMargin: 8
                Layout.rightMargin: 8

                MaterialSymbol {
                    text: "shield"
                    iconSize: Appearance.font.pixelSize.larger
                    color: NetworkExtras.blockyActive ? Appearance.colors.colPrimary : Appearance.colors.colOnSecondaryContainer
                }
                StyledText {
                    Layout.fillWidth: true
                    color: Appearance.colors.colOnSecondaryContainer
                    text: NetworkExtras.blockyActive
                        ? Translation.tr("Blocky service is running")
                        : Translation.tr("Blocky service is stopped")
                }
                RippleButtonWithIcon {
                    visible: !blockyRow.confirming
                    materialIcon: NetworkExtras.blockyActive ? "stop" : "play_arrow"
                    mainText: NetworkExtras.blockyActive ? Translation.tr("Stop") : Translation.tr("Start")
                    onClicked: blockyRow.confirming = true
                }
                DialogButton {
                    visible: blockyRow.confirming
                    buttonText: NetworkExtras.blockyActive ? Translation.tr("Stop it?") : Translation.tr("Start it?")
                    colText: Appearance.m3colors.m3error
                    onClicked: {
                        blockyRow.confirming = false
                        NetworkExtras.blockySetActive(!NetworkExtras.blockyActive)
                    }
                }
                DialogButton {
                    visible: blockyRow.confirming
                    buttonText: Translation.tr("Cancel")
                    onClicked: blockyRow.confirming = false
                }
            }
        }

        StyledText {
            visible: NetworkExtras.blockyPresent
            Layout.leftMargin: 8
            Layout.fillWidth: true
            text: Translation.tr("Uses pkexec — a system authentication prompt will appear")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }
    }
}
