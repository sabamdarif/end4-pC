import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import "../../../../services/Wellbeing.js" as Wellbeing

StyledListView {
    id: root
    property var days: []
    readonly property var apps: Wellbeing.topApps(root.days)
    signal limitRequested(string appId)
    clip: true
    spacing: 10
    model: root.apps
    StyledText { anchors.centerIn: parent; visible: root.apps.length === 0; text: Translation.tr("Nothing tracked yet") }
    delegate: ColumnLayout {
        id: app
        required property var modelData
        readonly property int dailyLimit: ScreenTime.appLimits[modelData.appId] || 0
        width: ListView.view.width
        spacing: 4
        RowLayout {
            Layout.fillWidth: true
            IconImage {
                implicitSize: 24
                source: Quickshell.iconPath(AppService.guessIcon(app.modelData.appId), "image-missing")
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                StyledText { Layout.fillWidth: true; text: ScreenTime.formatAppName(app.modelData.appId); elide: Text.ElideRight }
                StyledText {
                    Layout.fillWidth: true
                    text: ScreenTime.formatTime(app.modelData.seconds) + (app.dailyLimit > 0
                        ? " • " + Translation.tr("Daily limit: %1").arg(ScreenTime.formatTime(app.dailyLimit * 60)) : "")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                }
            }
            RippleButtonWithIcon {
                materialIcon: "timer"
                mainText: ""
                onClicked: root.limitRequested(app.modelData.appId)
                StyledToolTip { text: Translation.tr("Set daily limit") }
            }
        }
        StyledProgressBar {
            Layout.fillWidth: true
            value: app.modelData.seconds / Math.max(1, root.apps[0]?.seconds || 0)
        }
    }
}
