import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ContentPage {
    bottomContentPadding: 35

    function runSystemUpdate() {
        Quickshell.execDetached([
            "kitty", "--hold",
            "fish", "-i", "-l", "-c",
            "yay -Syu --combinedupgrade=false"
        ])
        Qt.callLater(() => GlobalStates.settingsOpen = false)
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 156 
        Layout.topMargin: 35
        Layout.leftMargin: 16
        Layout.rightMargin: 16

        radius: Appearance.rounding.large
        color: Appearance.colors.colLayer1

        RowLayout {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 24
            spacing: 24

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 110
                implicitHeight: 110
                radius: Appearance.rounding.normal
                color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.9)

                IconImage {
                    anchors.centerIn: parent
                    implicitWidth: 72
                    implicitHeight: 72
                    source: Quickshell.iconPath(SystemInfo.logo)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 4

                StyledText {
                    Layout.fillWidth: true
                    text: SystemInfo.distroName
                    font.pixelSize: Appearance.font.pixelSize.hugeass
                    font.weight: Font.ExtraBold
                    color: Appearance.colors.colOnSurface
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Kernel %1").arg(SystemInfo.kernelVersion || Translation.tr("Loading..."))
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                }

                Row {
                    id: colorRow
                    spacing: -6

                    Repeater {
                        model: [
                            Appearance.m3colors.m3primary,
                            Appearance.m3colors.m3secondary,
                            Appearance.m3colors.m3tertiary,
                            Appearance.m3colors.m3error,
                            Appearance.m3colors.m3primaryContainer,
                            Appearance.m3colors.m3secondaryContainer,
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: 28
                            height: 28
                            radius: width / 2
                            color: modelData
                            z: index
                            border.width: 2
                            border.color: Appearance.colors.colLayer1
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout { //This is not in the grid because I was planning to do something else.
            Layout.fillWidth: true
            spacing: 8

            AboutCard {
                icon: "planner_review"
                iconShape: MaterialShape.Shape.Pentagon
                label: Translation.tr("CPU")
                value: SystemInfo.cpu || Translation.tr("Loading...")
                Layout.fillWidth: true
            }

            AboutCard {
                icon: "monitor"
                iconShape: MaterialShape.Shape.ClamShell
                label: Translation.tr("GPU")
                value: SystemInfo.gpu || Translation.tr("N/A")
                Layout.fillWidth: true
            }
        }

        GridLayout {
            columns: 2
            Layout.fillWidth: true
            rowSpacing: 8
            columnSpacing: 8

            AboutCard {
                icon: "memory"
                label: Translation.tr("Memory")
                value: SystemInfo.memory || Translation.tr("Loading...")
                Layout.fillWidth: true
            }

            AboutCard {
                icon: "storage"
                iconShape: MaterialShape.Shape.Cookie6Sided
                label: Translation.tr("Disk")
                value: SystemInfo.disk || Translation.tr("Loading...")
                Layout.fillWidth: true
            }

            AboutCard {
                icon: "terminal"
                label: Translation.tr("Shell")
                iconShape: MaterialShape.Shape.Gem
                value: SystemInfo.shell || Translation.tr("Loading...")
                Layout.fillWidth: true
            }

            AboutCard {
                icon: "package_2"
                label: Translation.tr("Packages")
                iconShape: MaterialShape.Shape.Sunny
                value: SystemInfo.packages || Translation.tr("Loading...")
                Layout.fillWidth: true
            }

            AboutCard {
                icon: "update"
                label: Translation.tr("Updates")
                iconShape: MaterialShape.Shape.Cookie9Sided
                value: Updates.checking ? Translation.tr("Checking...") : (Updates.count === 0 ? Translation.tr("Up to date") : `${Updates.count}`)
                Layout.fillWidth: true
                clickAction: () => {
                    runSystemUpdate()
                }
            }

            AboutCard {
                icon: "timelapse"
                label: Translation.tr("Uptime")
                iconShape: MaterialShape.Shape.Cookie12Sided
                value: DateTime.uptime || Translation.tr("Loading...")
                Layout.fillWidth: true
            }
        }
    }
}
