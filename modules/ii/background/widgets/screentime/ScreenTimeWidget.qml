import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.background.widgets
import qs.modules.ii.sidebarRight.screentime
import "../../../../../services/Wellbeing.js" as Wellbeing

AbstractBackgroundWidget {
    id: root
    configEntryName: "screentime"
    hoverEnabled: true
    readonly property bool wide: root.configEntry.sizeMode === "1x4"
    implicitWidth: wide ? 420 : 276
    implicitHeight: wide ? 140 : 280
    onClicked: if (!root.dragging && !GlobalStates.screenLocked) GlobalStates.requestScreenTimeDialog()
    Rectangle {
        id: card
        anchors.fill: parent
        radius: Appearance.rounding.verylarge
        color: Appearance.colors.colPrimaryContainer
        WindowGlass { anchors.fill: parent; cardRadius: card.radius; tint: card.color }
        StyledRectangularShadow { target: card; z: -1 }
        GridLayout {
            anchors { fill: parent; margins: 14 }
            columns: root.wide ? 2 : 1
            rowSpacing: 6
            columnSpacing: 14
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                RowLayout {
                    MaterialShapeWrappedMaterialSymbol {
                        wrappedShape: MaterialShape.Shape.Cookie4Sided
                        text: "digital_wellbeing"
                        color: Appearance.colors.colPrimary
                        colSymbol: Appearance.colors.colOnPrimary
                        iconSize: 18
                        padding: 4
                        implicitWidth: 28
                        implicitHeight: 28
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("Digital wellbeing")
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnPrimaryContainer
                        elide: Text.ElideRight
                    }
                }
                StyledText {
                    text: ScreenTime.formatTime(ScreenTime.totalScreentime)
                    font.pixelSize: Appearance.font.pixelSize.huge
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnPrimaryContainer
                }
                StyledText {
                    visible: !root.wide
                    text: Translation.tr("Peak this week: %1").arg(ScreenTime.formatTime(Math.max(...weekChart.week.map(day => day.active))))
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colOnPrimaryContainer
                }
                WeeklyChart { id: weekChart; compact: true; Layout.fillWidth: true }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: Wellbeing.topApps([ScreenTime.today], 3)
                    delegate: ColumnLayout {
                        id: app
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 2
                        RowLayout {
                            Layout.fillWidth: true
                            IconImage { implicitSize: 18; source: Quickshell.iconPath(AppService.guessIcon(app.modelData.appId), "image-missing") }
                            StyledText {
                                Layout.fillWidth: true
                                text: ScreenTime.formatAppName(app.modelData.appId)
                                elide: Text.ElideRight
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colOnPrimaryContainer
                            }
                            StyledText { text: ScreenTime.formatTime(app.modelData.seconds); font.pixelSize: Appearance.font.pixelSize.smallest; color: Appearance.colors.colOnPrimaryContainer }
                        }
                        StyledProgressBar { Layout.fillWidth: true; value: app.modelData.seconds / Math.max(1, ScreenTime.totalScreentime) }
                    }
                }
                StyledText {
                    Layout.fillWidth: true
                    visible: Object.keys(ScreenTime.appsData).length === 0
                    text: ScreenTime.isEnabled ? Translation.tr("Nothing tracked yet") : Translation.tr("Tracking disabled")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnPrimaryContainer
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
