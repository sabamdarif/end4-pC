import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    id: page

    // Show each date format as a live sample so the dropdown needs no explanation
    readonly property var dateFormatPresets: [
        "ddd, dd/MM", "dddd, dd MMMM", "dd/MM/yyyy",
        "MM/dd/yyyy", "yyyy-MM-dd", "dd MMM yyyy"
    ].map(f => ({ displayName: `${Qt.formatDateTime(previewCard.now, f)}  ·  ${f}`, value: f }))
    readonly property bool dateFormatIsPreset: dateFormatPresets.some(p => p.value === Config.options.time.dateFormat)

    ContentSection {
        icon: "nest_clock_farsight_analog"
        shape: MaterialShape.Shape.Bun
        title: Translation.tr("Date & Time")

        Rectangle {
            id: previewCard
            Layout.fillWidth: true
            implicitHeight: 180
            topLeftRadius: Appearance.rounding.normal
            topRightRadius: Appearance.rounding.normal
            bottomLeftRadius: Appearance.rounding.unsharpenmore
            bottomRightRadius: Appearance.rounding.unsharpenmore
            color: Appearance.colors.colLayer1
            clip: true

            property date now: new Date()

            Timer {
                interval: Config.options.time.secondPrecision ? 1000 : 15000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: previewCard.now = new Date()
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                ColumnLayout {
                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        font.family: Appearance.font.family.numbers
                        font.pixelSize: Appearance.font.pixelSize.hugeass * 1.8
                        font.letterSpacing: 1
                        tabularNums: true
                        font.weight: Font.Medium
                        color: Appearance.colors.colPrimary
                        text: {
                            const fmt = Config.options.time.format;
                            if (Config.options.time.secondPrecision) {
                                if (fmt === "hh:mm") return Qt.formatTime(previewCard.now, "hh:mm:ss");
                                if (fmt === "h:mm ap") return Qt.formatTime(previewCard.now, "h:mm:ss ap");
                                if (fmt === "h:mm AP") return Qt.formatTime(previewCard.now, "h:mm:ss AP");
                            }
                            return Qt.formatTime(previewCard.now, fmt);
                        }
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: DateTime.longDate
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Appearance.font.pixelSize.huge * 1.4
                        font.weight: Font.Normal
                        opacity: 0.6
                        color: Appearance.colors.colPrimary
                    }
                }

                AndroidClock {
                    Layout.rightMargin: 6
                    width: 130
                    height: 130
                    backgroundColor: Appearance.colors.colPrimaryContainer
                    handColor:       Appearance.colors.colPrimary
                    centerDotColor:  Appearance.colors.colPrimary
                }
            }
        }

        GroupedList {
            Layout.topMargin: -2
            ConfigSelectionArray {
                text: Translation.tr("Format")
                icon: "schedule"
                currentValue: Config.options.time.format
                onSelected: newValue => {
                    Config.options.time.format = newValue;
                }
                options: [
                    { displayName: Translation.tr("24h"), value: "hh:mm" },
                    { displayName: Translation.tr("12h am/pm"), value: "h:mm ap" },
                    { displayName: Translation.tr("12h AM/PM"), value: "h:mm AP" }
                ]
            }
            ConfigSwitch {
                buttonIcon: "pace"
                text: Translation.tr("Second precision")
                checked: Config.options.time.secondPrecision
                onCheckedChanged: {
                    Config.options.time.secondPrecision = checked;
                }
            }

            ConfigComboBox {
                Layout.fillWidth: true
                buttonIcon: "calendar_month"
                text: Translation.tr("Date format")
                model: page.dateFormatPresets
                currentValue: Config.options.time.dateFormat
                onSelected: (value) => {
                    Config.options.time.dateFormat = value;
                }
            }

            ConfigTextArea {
                id: customDateFormatField
                visible: !page.dateFormatIsPreset
                Layout.fillWidth: true
                buttonIcon: "calendar_month"
                text: Translation.tr("Date format (custom)")
                placeholderText: Translation.tr("e.g. ddd, dd/MM")
                value: Config.options.time.dateFormat
                onValueChanged: customDateDebounce.restart()

                Timer {
                    id: customDateDebounce
                    interval: 350
                    repeat: false
                    onTriggered: {
                        if (customDateFormatField.value !== Config.options.time.dateFormat)
                            Config.options.time.dateFormat = customDateFormatField.value;
                    }
                }
            }
        }
    }
}
