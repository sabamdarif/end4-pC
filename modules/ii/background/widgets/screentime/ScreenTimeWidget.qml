import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.background.widgets
import qs.modules.ii.sidebarRight.screentime

AbstractBackgroundWidget {
    id: root
    configEntryName: "screentime"
    hoverEnabled: true
    readonly property bool wide: root.configEntry.sizeMode === "1x4"
    implicitWidth: wide ? 540 : 400
    implicitHeight: wide ? 560 : 620
    Rectangle {
        id: card
        anchors.fill: parent
        radius: Appearance.rounding.verylarge
        color: Appearance.colors.colLayer1Blurred
        WindowGlass { anchors.fill: parent; cardRadius: card.radius; tint: card.color }
        StyledRectangularShadow { target: card; z: -1 }
        ColumnLayout {
            anchors { fill: parent; margins: 20 }
            spacing: 12
            RowLayout {
                Layout.fillWidth: true
                MaterialSymbol { text: "digital_wellbeing"; iconSize: Appearance.font.pixelSize.larger }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("Digital wellbeing")
                        font.pixelSize: Appearance.font.pixelSize.larger
                        elide: Text.ElideRight
                    }
                    StyledText {
                        text: Translation.tr("Today: %1").arg(ScreenTime.formatTime(ScreenTime.totalScreentime))
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }
            }
            WindowDialogSeparator {}
            StyledText {
                Layout.fillWidth: true
                visible: !ScreenTime.tracking || ScreenTime.lastError !== ""
                text: ScreenTime.lastError || (ScreenTime.isEnabled ? Translation.tr("Tracking needs a running niri session.")
                    : Translation.tr("Tracking is disabled. Enable it in settings."))
                wrapMode: Text.Wrap
                font.pixelSize: Appearance.font.pixelSize.smaller
            }
            WellbeingContent {
                Layout.fillWidth: true
                Layout.fillHeight: true
                desktop: true
                enabled: !GlobalStates.screenLocked
            }
        }
    }
}
