import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Dialog {
    id: root
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(350, parent.width - 24)
    modal: true
    padding: 20
    property string appId: ""
    function presentFor(appId) {
        root.appId = appId;
        const minutes = appId ? ScreenTime.appLimits[appId] || 0 : Config.options.wellbeing.dailyLimit;
        hours.value = Math.floor(minutes / 60);
        mins.value = minutes % 60;
        root.open();
    }
    function setLimit(minutes) {
        if (root.appId) ScreenTime.setAppLimit(root.appId, minutes);
        else Config.options.wellbeing.dailyLimit = minutes;
        root.close();
    }
    background: Rectangle { radius: Appearance.rounding.large; color: Appearance.colors.colLayer1 }
    contentItem: ColumnLayout {
        spacing: 16
        StyledText {
            Layout.fillWidth: true
            text: root.appId ? Translation.tr("Daily limit for %1").arg(ScreenTime.formatAppName(root.appId)) : Translation.tr("Daily screen time limit")
            wrapMode: Text.Wrap
            font.pixelSize: Appearance.font.pixelSize.larger
        }
        ConfigSpinBox { id: hours; Layout.fillWidth: true; text: Translation.tr("Hours"); from: 0; to: 24 }
        ConfigSpinBox { id: mins; Layout.fillWidth: true; text: Translation.tr("Minutes"); from: 0; to: hours.value === 24 ? 0 : 59 }
        StyledText { Layout.fillWidth: true; text: Translation.tr("Limits remind you to take a break. They do not close or block apps."); wrapMode: Text.Wrap }
        Flow {
            Layout.fillWidth: true
            spacing: 4
            DialogButton { buttonText: Translation.tr("Remove limit"); onClicked: root.setLimit(0) }
            DialogButton { buttonText: Translation.tr("Cancel"); onClicked: root.close() }
            DialogButton { buttonText: Translation.tr("Save"); onClicked: root.setLimit(hours.value * 60 + mins.value) }
        }
    }
}
