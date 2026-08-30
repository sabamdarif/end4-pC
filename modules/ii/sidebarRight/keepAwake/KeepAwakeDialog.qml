import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

DialogSheet {
    id: root
    title: Translation.tr("Keep awake")
    subtitle: Idle.inhibit ? Idle.inhibitStatusText : Translation.tr("Pick how long the system stays awake")
    edgeToEdge: true

    leadingActions: DialogButton {
        visible: Idle.inhibit
        buttonText: Translation.tr("Turn off")
        onClicked: {
            Idle.toggleInhibit(false);
            root.dismiss();
        }
    }

    Column {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop

        Repeater {
            model: Idle.inhibitDurations

            DialogListItem {
                id: durationItem
                required property int modelData
                readonly property bool current: Idle.inhibitDurationMinutes === durationItem.modelData

                anchors {
                    left: parent?.left
                    right: parent?.right
                }
                onClicked: {
                    Idle.toggleInhibit(true, durationItem.modelData);
                    root.dismiss();
                }

                contentItem: RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: durationItem.horizontalPadding
                        rightMargin: durationItem.horizontalPadding
                    }
                    spacing: 10

                    MaterialSymbol {
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnSurfaceVariant
                        text: durationItem.modelData <= 0 ? "all_inclusive" : "timer"
                    }
                    StyledText {
                        Layout.fillWidth: true
                        color: Appearance.colors.colOnSurfaceVariant
                        elide: Text.ElideRight
                        text: Idle.inhibitDurationLabel(durationItem.modelData)
                    }
                    MaterialSymbol {
                        visible: durationItem.current
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colPrimary
                        text: "check"
                    }
                }
            }
        }
    }
}
