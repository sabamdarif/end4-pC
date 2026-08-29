import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    ContentSection {
        icon: "nest_clock_farsight_analog"
        shape: MaterialShape.Shape.Bun
        title: Translation.tr("Date & Time")

        Rectangle {
            id: previewCard
            Layout.fillWidth: true
            implicitHeight: 180
            radius: Appearance.rounding.normal
            clip: true

            gradient: Gradient { // I didn't like how it turned out but in case I regret it 
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Appearance.colors.colLayer1  }
                GradientStop { position: 0.6; color: Appearance.colors.colLayer1  }
                GradientStop { position: 1.0; color: Appearance.colors.colLayer1  }
            }

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
                        font.family: Appearance.font.family.expressive
                        font.pixelSize: 42
                        font.letterSpacing: 1
                        font.features: { "tnum": 1 }
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
                        font.pixelSize: 32
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
            ConfigTextArea {
                Layout.fillWidth: true
                buttonIcon: "scoreboard"
                text: Translation.tr("Clock String Format")
                placeholderText: Translation.tr("Clock String Format")
                value: Config.options.time.format
                onValueChanged: {
                    Config.options.time.format = value;
                }
            }

            ConfigTextArea {
                Layout.fillWidth: true
                buttonIcon: "calendar_month"
                text: Translation.tr("Date String Format")
                placeholderText: Translation.tr("Date String Format")
                value: Config.options.time.dateFormat
                onValueChanged: {
                    Config.options.time.dateFormat = value;
                }
            }
        }
    }
}
