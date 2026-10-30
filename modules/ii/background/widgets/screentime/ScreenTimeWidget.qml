import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root
    configEntryName: "screentime"
    hoverEnabled: true

    property string sizeMode: (root.configEntry && root.configEntry.sizeMode) ? root.configEntry.sizeMode : "2x2"

    implicitWidth: sizeMode === "1x4" ? 400 : 276
    implicitHeight: sizeMode === "1x4" ? 120 : 252

    Behavior on implicitWidth {
        NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
    }
    Behavior on implicitHeight {
        NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Appearance.rounding ? Appearance.rounding.verylarge : 24
        color: Appearance.colors.colPrimaryContainer

        WindowGlass {
            anchors.fill: parent
            cardRadius: parent ? parent.radius : 0
            tint: parent ? parent.color : "transparent"
        }

        StyledRectangularShadow {
            target: card
            z: -2
        }

        // Layout for 2x2 Square mode (Material 3 Android Wellbeing style)
        ColumnLayout {
            visible: root.sizeMode === "2x2"
            anchors {
                fill: parent
                margins: 14
            }
            spacing: 6

            // Top Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                MaterialShapeWrappedMaterialSymbol {
                    wrappedShape: MaterialShape.Shape.Cookie4Sided
                    color: Appearance.colors.colPrimary
                    colSymbol: Appearance.colors.colOnPrimary
                    text: "hourglass_bottom"
                    iconSize: 18
                    fill: 1
                    padding: 4
                    implicitWidth: 28
                    implicitHeight: 28
                }

                ColumnLayout {
                    spacing: -2
                    Layout.fillWidth: true

                    StyledText {
                        text: Translation.tr("Screen Time")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnPrimaryContainer
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    StyledText {
                        text: Translation.tr("24h History")
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colOnPrimaryContainer
                        opacity: 0.6
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
            }

            // Main Metric Readout + Peak rate
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                StyledText {
                    text: ScreenTime.formatTime(ScreenTime.totalScreentime)
                    font.pixelSize: 28
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnPrimaryContainer
                }

                StyledText {
                    property real maxVal: {
                        let max = 0;
                        for (let i = 0; i < 24; i++) {
                            let val = ScreenTime.hourlyUsage[i.toString()] || 0;
                            if (val > max) max = val;
                        }
                        return max;
                    }
                    text: Translation.tr("Peak: %1").arg(ScreenTime.formatHourAxis(maxVal))
                    font.pixelSize: 11
                    color: Appearance.colors.colOnPrimaryContainer
                    opacity: 0.6
                    Layout.alignment: Qt.AlignBottom
                    Layout.bottomMargin: 4
                }
            }

            // Material 3 Bar Chart with 0-24 Full Day Timeline
            ColumnLayout {
                id: chartContainer2x2
                Layout.fillWidth: true
                spacing: 3

                Item {
                    id: chart2x2
                    Layout.fillWidth: true
                    implicitHeight: 38

                    property real maxVal: {
                        let max = 0;
                        for (let i = 0; i < 24; i++) {
                            let val = ScreenTime.hourlyUsage[i.toString()] || 0;
                            if (val > max) max = val;
                        }
                        return max > 0 ? max : 1;
                    }

                    property int currentHour: new Date().getHours()

                    Row {
                        anchors.centerIn: parent
                        spacing: 3

                        Repeater {
                            model: 24
                            delegate: Item {
                                required property int index
                                property int hourIndex: index
                                property real hourVal: ScreenTime.hourlyUsage[hourIndex.toString()] || 0
                                property bool isCurrentHour: hourIndex === chart2x2.currentHour

                                width: 6
                                height: chart2x2.implicitHeight

                                Rectangle {
                                    width: parent.width
                                    height: Math.max(4, (hourVal / chart2x2.maxVal) * chart2x2.implicitHeight)
                                    radius: width / 2
                                    anchors.bottom: parent.bottom

                                    color: isCurrentHour
                                        ? Appearance.colors.colPrimary
                                        : (hourVal > 0
                                            ? ColorUtils.mix(Appearance.colors.colPrimary, Appearance.colors.colPrimaryContainer, 0.45)
                                            : ColorUtils.mix(Appearance.colors.colOnPrimaryContainer, Appearance.colors.colPrimaryContainer, 0.12))
                                    border.width: isCurrentHour ? 1 : 0
                                    border.color: Appearance.colors.colOnPrimaryContainer
                                }
                            }
                        }
                    }
                }

                // 0-24 Hour Timeline Markings Row
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 10
                    Layout.rightMargin: 10

                    StyledText { text: "00"; font.pixelSize: 9; color: Appearance.colors.colOnPrimaryContainer; opacity: 0.6 }
                    Item { Layout.fillWidth: true }
                    StyledText { text: "06"; font.pixelSize: 9; color: Appearance.colors.colOnPrimaryContainer; opacity: 0.6 }
                    Item { Layout.fillWidth: true }
                    StyledText { text: "12"; font.pixelSize: 9; color: Appearance.colors.colOnPrimaryContainer; opacity: 0.6 }
                    Item { Layout.fillWidth: true }
                    StyledText { text: "18"; font.pixelSize: 9; color: Appearance.colors.colOnPrimaryContainer; opacity: 0.6 }
                    Item { Layout.fillWidth: true }
                    StyledText { text: "24"; font.pixelSize: 9; color: Appearance.colors.colOnPrimaryContainer; opacity: 0.6 }
                }
            }

            // Top Apps Usage List (Android M3 Rows)
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 5

                Repeater {
                    model: ScreenTime.getSortedApps().slice(0, 3)
                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 10

                        // Squircle Icon Box
                        Rectangle {
                            width: 26
                            height: 26
                            radius: 8
                            color: ColorUtils.mix(Appearance.colors.colOnPrimaryContainer, Appearance.colors.colPrimaryContainer, 0.08)

                            IconImage {
                                anchors.centerIn: parent
                                width: 16
                                height: 16
                                source: Quickshell.iconPath(AppService.guessIcon(modelData.name), "image-missing")
                            }
                        }

                        StyledText {
                            text: ScreenTime.formatAppName(modelData.name)
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnPrimaryContainer
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        StyledText {
                            text: ScreenTime.formatTime(modelData.time)
                            font.pixelSize: 12
                            color: Appearance.colors.colOnPrimaryContainer
                            opacity: 0.7
                        }
                    }
                }
            }
        }

        // Layout for 1x4 Horizontal mode
        RowLayout {
            visible: root.sizeMode === "1x4"
            anchors {
                fill: parent
                margins: 12
            }
            spacing: 14

            // Left Column (Stats & Bar Chart)
            ColumnLayout {
                Layout.fillHeight: true
                Layout.preferredWidth: 210
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    MaterialShapeWrappedMaterialSymbol {
                        wrappedShape: MaterialShape.Shape.Cookie4Sided
                        color: Appearance.colors.colPrimary
                        colSymbol: Appearance.colors.colOnPrimary
                        text: "hourglass_bottom"
                        iconSize: 16
                        fill: 1
                        padding: 3
                        implicitWidth: 24
                        implicitHeight: 24
                    }

                    StyledText {
                        text: Translation.tr("Screen Time")
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnPrimaryContainer
                    }
                }

                StyledText {
                    text: ScreenTime.formatTime(ScreenTime.totalScreentime)
                    font.pixelSize: 22
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnPrimaryContainer
                }

                // Small M3 Bar Chart with 0-24 Timeline
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Item {
                        id: chart1x4
                        Layout.fillWidth: true
                        implicitHeight: 28

                        property real maxVal: {
                            let max = 0;
                            for (let i = 0; i < 24; i++) {
                                let val = ScreenTime.hourlyUsage[i.toString()] || 0;
                                if (val > max) max = val;
                            }
                            return max > 0 ? max : 1;
                        }

                        property int currentHour: new Date().getHours()

                        Row {
                            anchors.centerIn: parent
                            spacing: 3

                            Repeater {
                                model: 24
                                delegate: Item {
                                    required property int index
                                    property int hourIndex: index
                                    property real hourVal: ScreenTime.hourlyUsage[hourIndex.toString()] || 0
                                    property bool isCurrentHour: hourIndex === chart1x4.currentHour

                                    width: 5
                                    height: chart1x4.implicitHeight

                                    Rectangle {
                                        width: parent.width
                                        height: Math.max(3, (hourVal / chart1x4.maxVal) * chart1x4.implicitHeight)
                                        radius: width / 2
                                        anchors.bottom: parent.bottom

                                        color: isCurrentHour
                                            ? Appearance.colors.colPrimary
                                            : (hourVal > 0
                                                ? ColorUtils.mix(Appearance.colors.colPrimary, Appearance.colors.colPrimaryContainer, 0.45)
                                                : ColorUtils.mix(Appearance.colors.colOnPrimaryContainer, Appearance.colors.colPrimaryContainer, 0.12))
                                        border.width: isCurrentHour ? 1 : 0
                                        border.color: Appearance.colors.colOnPrimaryContainer
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 6
                        Layout.rightMargin: 6

                        StyledText { text: "00"; font.pixelSize: 8; color: Appearance.colors.colOnPrimaryContainer; opacity: 0.6 }
                        Item { Layout.fillWidth: true }
                        StyledText { text: "12"; font.pixelSize: 8; color: Appearance.colors.colOnPrimaryContainer; opacity: 0.6 }
                        Item { Layout.fillWidth: true }
                        StyledText { text: "24"; font.pixelSize: 8; color: Appearance.colors.colOnPrimaryContainer; opacity: 0.6 }
                    }
                }
            }

            // Divider
            Rectangle {
                width: 1
                Layout.fillHeight: true
                color: Appearance.colors.colOnPrimaryContainer
                opacity: 0.15
            }

            // Right Column (App List)
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4

                Repeater {
                    model: ScreenTime.getSortedApps().slice(0, 3)
                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            width: 22
                            height: 22
                            radius: 6
                            color: ColorUtils.mix(Appearance.colors.colOnPrimaryContainer, Appearance.colors.colPrimaryContainer, 0.08)

                            IconImage {
                                anchors.centerIn: parent
                                width: 14
                                height: 14
                                source: Quickshell.iconPath(AppService.guessIcon(modelData.name), "image-missing")
                            }
                        }

                        StyledText {
                            text: ScreenTime.formatAppName(modelData.name)
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnPrimaryContainer
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        StyledText {
                            text: ScreenTime.formatTime(modelData.time)
                            font.pixelSize: 11
                            color: Appearance.colors.colOnPrimaryContainer
                            opacity: 0.7
                        }
                    }
                }
            }
        }
    }
}
