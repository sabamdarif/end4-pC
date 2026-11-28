import shutil
import unittest

from ui_test_utils import qml_block, run_qml


@unittest.skipUnless(shutil.which("qs"), "Quickshell is required")
class DateTimeTests(unittest.TestCase):
    def test_digit_clock_follows_format_changes(self):
        bindings = qml_block(
            "services/DateTime.qml",
            "    readonly property bool use12HourFormat:",
            "    property string uptime:",
        ).replace("Config.options?.time.format", "root.format")
        run_qml(self, '''
            property string format: "hh:mm"
            QtObject {
                id: clock
                property date date: new Date(2026, 10, 28, 14, 55)
            }
''' + bindings + '''
            Timer {
                interval: 50
                running: true
                onTriggered: {
                    const formats = ["hh:mm", "h:mm ap", "h:mm AP", "hh:mm"];
                    const hours = [0, 1, 11, 12, 14, 23];
                    for (const format of formats) {
                        root.format = format;
                        const is12Hour = format !== "hh:mm";
                        root.check(root.use12HourFormat === is12Hour, "format " + format);
                        for (const hour of hours) {
                            clock.date = new Date(2026, 10, 28, hour, 55);
                            const expectedHour = is12Hour ? (hour % 12 || 12) : hour;
                            const expected = Qt.locale().toString(new Date(2026, 10, 28, expectedHour, 55), "HH");
                            root.check(root.hourStr === expected, format + " at " + hour);
                            root.check(root.digitH0 === expected.charAt(0), "first hour digit");
                            root.check(root.digitH1 === expected.charAt(1), "second hour digit");
                            const minute = Qt.locale().toString(clock.date, "mm");
                            root.check(root.digitM0 + root.digitM1 === minute, "minutes unchanged");
                        }
                    }
                    console.log("UI_TEST_DONE");
                }
            }
''')


if __name__ == "__main__":
    unittest.main()
