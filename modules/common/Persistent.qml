pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property alias states: persistentStatesJsonAdapter
    property string fileDir: Directories.state
    property string fileName: "states.json"
    property string filePath: `${root.fileDir}/${root.fileName}`

    property bool ready: false
    property string previousCompositorSignature: ""
    // niri has no instance signature, but its socket path is per-session, so it
    // works the same way for spotting a fresh session.
    readonly property string compositorSignature: Quickshell.env("NIRI_SOCKET") || ""
    property bool isNewCompositorInstance: previousCompositorSignature !== states.compositorSignature

    onReadyChanged: {
        root.previousCompositorSignature = root.states.compositorSignature
        root.states.compositorSignature = root.compositorSignature
    }

    Timer {
        id: fileReloadTimer
        interval: 100
        repeat: false
        onTriggered: {
            persistentStatesFileView.reload()
        }
    }

    Timer {
        id: fileWriteTimer
        interval: 100
        repeat: false
        onTriggered: {
            persistentStatesFileView.writeAdapter()
        }
    }

    FileView {
        id: persistentStatesFileView
        path: root.filePath

        watchChanges: true
        onFileChanged: fileReloadTimer.restart()
        onAdapterUpdated: fileWriteTimer.restart()
        onLoaded: root.ready = true
        onLoadFailed: error => {
            console.log("Failed to load persistent states file:", error);
            if (error == FileViewError.FileNotFound) {
                fileWriteTimer.restart();
            }
        }

        adapter: JsonAdapter {
            id: persistentStatesJsonAdapter

            property string compositorSignature: ""

            property JsonObject cheatsheet: JsonObject {
                property int tabIndex: 0
            }

            property JsonObject sidebar: JsonObject {
                property JsonObject bottomGroup: JsonObject {
                    property bool collapsed: false
                    property int tab: 0
                }
            }

            property JsonObject idle: JsonObject {
                property bool inhibit: false
                // Minutes the keep-awake toggle runs for, and the epoch second the running one
                // ends at. 0 means it keeps going until switched off.
                property int durationMinutes: 0
                property int inhibitUntil: 0
            }

            property JsonObject nightLight: JsonObject {
                property bool userEnabled: false
                property bool manualOverride: false
                property bool manualActive: false
                property int manualActiveHour: -1
                property int manualActiveMinute: -1
                property bool userDisabled: false
            }

            property JsonObject ducky: JsonObject {
                property int petCount: 0
            }

            property JsonObject record: JsonObject {
                property bool enable: false
            }

            property JsonObject timer: JsonObject {
                property JsonObject pomodoro: JsonObject {
                    property bool running: false
                    property int start: 0
                    property bool isBreak: false
                    property int cycle: 0
                }
                property JsonObject stopwatch: JsonObject {
                    property bool running: false
                    property real start: 0
                    property real elapsed: 0
                    property list<var> laps: []
                }
                property JsonObject countdown: JsonObject {
                    property bool running: false
                    property int duration: 0
                    property int start: 0
                }
            }
        }
    }
}
