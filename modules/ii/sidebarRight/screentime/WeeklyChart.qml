import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import "../../../../services/Wellbeing.js" as Wellbeing

ColumnLayout {
    id: root
    property bool compact: false
    property var days: ScreenTime.days
    property date today: Wellbeing.parseKey(ScreenTime.todayKey)
    property int firstDayOfWeek: Qt.locale().firstDayOfWeek % 7
    property int weekOffset: 0
    property string selectedDate: ""
    readonly property date anchor: Wellbeing.addDays(today, weekOffset * 7)
    readonly property var week: Wellbeing.weekDays(days, anchor, firstDayOfWeek, today)
    readonly property int oldestOffset: Wellbeing.oldestWeekOffset(today, firstDayOfWeek)
    readonly property real limitSeconds: Config.options.wellbeing.dailyLimit * 60
    readonly property var axis: Wellbeing.axis(Math.max(root.compact ? 0 : limitSeconds, ...week.map(day => day.active)))
    readonly property real total: Wellbeing.totalSeconds(week)
    spacing: compact ? 2 : 8
    onWeekOffsetChanged: root.selectedDate = ""

    RowLayout {
        visible: !root.compact
        Layout.fillWidth: true
        RippleButtonWithIcon {
            materialIcon: "chevron_left"
            mainText: ""
            enabled: root.weekOffset > root.oldestOffset
            onClicked: root.weekOffset--
            StyledToolTip { text: Translation.tr("Previous week") }
        }
        StyledText {
            Layout.fillWidth: true
            text: Qt.formatDate(Wellbeing.parseKey(root.week[0].date), "MMM d") + " / " + Qt.formatDate(Wellbeing.parseKey(root.week[6].date), "MMM d")
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Appearance.font.pixelSize.smaller
        }
        RippleButtonWithIcon {
            materialIcon: "chevron_right"
            mainText: ""
            enabled: root.weekOffset < 0
            onClicked: root.weekOffset++
            StyledToolTip { text: Translation.tr("Next week") }
        }
    }
    StyledText {
        visible: !root.compact
        text: Translation.tr("Weekly total: %1").arg(ScreenTime.formatTime(root.total))
        font.weight: Font.Medium
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 4
        ColumnLayout {
            visible: !root.compact
            Layout.preferredHeight: 100
            spacing: 0
            StyledText { text: ScreenTime.formatTime(root.axis.top); font.pixelSize: Appearance.font.pixelSize.smallest }
            Item { Layout.fillHeight: true }
            StyledText { text: ScreenTime.formatTime(0); font.pixelSize: Appearance.font.pixelSize.smallest }
        }
        Item {
            Layout.fillWidth: true
            implicitHeight: root.compact ? 46 : 120
            Rectangle {
                visible: !root.compact && root.limitSeconds > 0
                width: parent.width
                height: 1
                y: (parent.height - 20) * (1 - Math.min(1, root.limitSeconds / root.axis.top))
                color: Appearance.m3colors.m3error
            }
            RowLayout {
                anchors.fill: parent
                spacing: root.compact ? 4 : 8
                Repeater {
                    model: root.week
                    delegate: ColumnLayout {
                        id: day
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 3
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: Math.min(parent.width, root.compact ? 18 : 26)
                                height: Math.max(3, parent.height * day.modelData.active / root.axis.top)
                                radius: width / 2
                                opacity: day.modelData.future ? 0.3 : 1
                                color: root.limitSeconds > 0 && day.modelData.active >= root.limitSeconds
                                    ? Appearance.m3colors.m3error : day.modelData.today || root.selectedDate === day.modelData.date
                                        ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
                            }
                            MouseArea {
                                anchors.fill: parent
                                enabled: !root.compact && !day.modelData.future
                                onClicked: root.selectedDate = root.selectedDate === day.modelData.date ? "" : day.modelData.date
                                StyledToolTip { text: Qt.formatDate(Wellbeing.parseKey(day.modelData.date), "ddd, MMM d") + ": " + ScreenTime.formatTime(day.modelData.active) }
                            }
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.locale().dayName(day.modelData.weekday || 7, Locale.ShortFormat).slice(0, 1)
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }
        }
    }
}
