import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.sidebarRight.screentime
import "../../../../services/Wellbeing.js" as Wellbeing

ColumnLayout {
    id: root
    property string period: "week"
    property bool desktop: false
    spacing: 12
    AppLimitSheet { id: limitSheet; desktop: root.desktop }
    WeeklyChart {
        id: chart
        Layout.fillWidth: true
        Layout.maximumHeight: implicitHeight
    }
    ConfigSelectionArray {
        Layout.fillWidth: true
        currentValue: root.period
        onSelected: value => { root.period = value; chart.selectedDate = ""; }
        options: [ { displayName: Translation.tr("Day"), value: "day" },
            { displayName: Translation.tr("Week"), value: "week" },
            { displayName: Translation.tr("Month"), value: "month" } ]
    }
    StyledText {
        Layout.fillWidth: true
        text: chart.selectedDate ? Qt.formatDate(Wellbeing.parseKey(chart.selectedDate), "ddd, MMM d")
            : Translation.tr("Most used apps")
        font.weight: Font.Medium
    }
    AppUsageList {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 70
        days: Wellbeing.periodDays(ScreenTime.days, chart.selectedDate ? Wellbeing.parseKey(chart.selectedDate)
            : root.period === "day" && chart.weekOffset === 0 ? chart.today : chart.anchor,
            chart.firstDayOfWeek, chart.selectedDate ? "day" : root.period, chart.today)
        onLimitRequested: appId => limitSheet.presentFor(appId)
    }
    RowLayout {
        Layout.fillWidth: true
        DialogButton {
            buttonText: Translation.tr("Daily limit")
            onClicked: limitSheet.presentFor("")
        }
        Item { Layout.fillWidth: true }
        DialogButton {
            visible: chart.weekOffset < 0 || chart.selectedDate !== ""
            buttonText: Translation.tr("Today")
            onClicked: { chart.weekOffset = 0; chart.selectedDate = ""; root.period = "day"; }
        }
    }
}
