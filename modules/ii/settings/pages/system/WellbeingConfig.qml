import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.sidebarRight.screentime

ContentPage {
    ContentSection {
        icon: "digital_wellbeing"
        title: Translation.tr("Digital wellbeing")
        ConfigSwitch {
            buttonIcon: "digital_wellbeing"
            text: Translation.tr("Track screen time")
            checked: Config.options.wellbeing.enable
            onCheckedChanged: Config.options.wellbeing.enable = checked
        }
        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("History stays on this device for 92 days. Time while locked or idle for five minutes is not counted. Limits send reminders, not restrictions.")
            wrapMode: Text.Wrap
        }
        StyledText {
            Layout.fillWidth: true
            visible: ScreenTime.lastError !== ""
            text: ScreenTime.lastError
            color: Appearance.m3colors.m3error
            wrapMode: Text.Wrap
        }
        StyledText { text: Translation.tr("Today: %1").arg(ScreenTime.formatTime(ScreenTime.totalScreentime)); font.pixelSize: Appearance.font.pixelSize.larger }
        WellbeingContent { Layout.fillWidth: true; Layout.preferredHeight: 580 }
    }
    ContentSection {
        icon: "timer"
        title: Translation.tr("App limits")
        Repeater {
            model: Object.keys(ScreenTime.appLimits)
            delegate: RowLayout {
                required property string modelData
                Layout.fillWidth: true
                StyledText {
                    Layout.fillWidth: true
                    text: ScreenTime.formatAppName(modelData) + " • " + ScreenTime.formatTime(ScreenTime.appLimits[modelData] * 60)
                    elide: Text.ElideRight
                }
                DialogButton { buttonText: Translation.tr("Remove"); onClicked: ScreenTime.removeAppLimit(modelData) }
            }
        }
        StyledText { visible: Object.keys(ScreenTime.appLimits).length === 0; text: Translation.tr("No app limits set") }
    }
}
