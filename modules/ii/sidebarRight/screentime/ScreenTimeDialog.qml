import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.sidebarRight.screentime

DialogSheet {
    title: Translation.tr("Digital wellbeing")
    subtitle: Translation.tr("Today: %1").arg(ScreenTime.formatTime(ScreenTime.totalScreentime))
    settingsPage: "wellbeing"
    StyledText {
        Layout.fillWidth: true
        visible: !ScreenTime.isEnabled || ScreenTime.lastError !== ""
        text: ScreenTime.lastError || Translation.tr("Tracking is disabled. Enable it in settings.")
        wrapMode: Text.Wrap
    }
    WellbeingContent { Layout.fillWidth: true; Layout.fillHeight: true }
}
