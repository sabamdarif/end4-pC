//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Scope {
    id: root

    // True when an uncommented prefer-no-csd is found in the niri config.
    // In that case the window draws no titlebar, like every other no-csd client.
    property bool preferNoCsd: false

    Component.onCompleted: {
        GlobalStates.settingsOpen = false;
        if (NiriData.isNiri) csdCheckProc.running = true;
    }

    Process {
        id: csdCheckProc
        command: ["sh", "-c", "grep -hsE '^\\s*prefer-no-csd\\s*$' ~/.config/niri/config.kdl ~/.config/niri/config.d/*.kdl"]
        stdout: StdioCollector {
            onStreamFinished: root.preferNoCsd = text.trim().length > 0
        }
    }

    Loader {
        id: windowLoader
        active: GlobalStates.settingsOpen

        sourceComponent: FloatingWindow {
            id: settingsWindow
            title: Translation.tr("Settings")
            color: Appearance.colors.colLayer0
            implicitWidth: 980
            implicitHeight: 665 + (titleBar.visible ? titleBar.implicitHeight : 0)
            minimumSize: Qt.size(600, 400)
            visible: true

            function hide() {
                GlobalStates.settingsOpen = false;
            }

            onVisibleChanged: {
                if (!visible) GlobalStates.settingsOpen = false;
            }

            Component.onCompleted: {
                if (NiriData.isNiri) csdCheckProc.running = true;
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    id: titleBar
                    visible: !(NiriData.isNiri && root.preferNoCsd)
                    Layout.fillWidth: true
                    implicitHeight: 44
                    color: Appearance.m3colors.m3surfaceContainerLow
                    readonly property var backingWindow: Window.window

                    DragHandler {
                        target: null
                        onActiveChanged: if (active) titleBar.backingWindow?.startSystemMove()
                    }

                    TapHandler {
                        gesturePolicy: TapHandler.DragThreshold
                        onDoubleTapped: settingsWindow.maximized = !settingsWindow.maximized
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 8
                        spacing: 4

                        MaterialSymbol {
                            text: "settings"
                            iconSize: 20
                            color: Appearance.colors.colOnLayer1
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: settingsWindow.title
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                            elide: Text.ElideRight
                        }

                        RippleButton {
                            implicitWidth: 32
                            implicitHeight: 32
                            buttonRadius: width / 2
                            onClicked: settingsWindow.maximized = !settingsWindow.maximized
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                text: settingsWindow.maximized ? "collapse_content" : "expand_content"
                                iconSize: 18
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledToolTip {
                                text: settingsWindow.maximized ? Translation.tr("Restore") : Translation.tr("Maximize")
                            }
                        }

                        RippleButton {
                            implicitWidth: 32
                            implicitHeight: 32
                            buttonRadius: width / 2
                            colBackgroundHover: Appearance.m3colors.m3error
                            onClicked: settingsWindow.hide()
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                text: "close"
                                iconSize: 18
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledToolTip {
                                text: Translation.tr("Close")
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Escape) {
                            settingsWindow.hide();
                        }
                    }

                    SettingsContent {
                        anchors.fill: parent
                        focus: true
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "settings"
        function toggle(): void { GlobalStates.settingsOpen = !GlobalStates.settingsOpen; }
        function open(): void   { GlobalStates.settingsOpen = true; }
        function close(): void  { GlobalStates.settingsOpen = false; }
    }

    NiriSafeShortcut {
        name: "settingsToggle"
        description: "Toggles settings panel"
        onPressed: GlobalStates.settingsOpen = !GlobalStates.settingsOpen;
    }
}
