pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

/**
 * Microphone, camera and screen share activity behind the bar's privacy indicator.
 */
Singleton {
    id: root

    readonly property bool micShown: Config.options.bar.privacy.showMicrophone
    readonly property bool cameraShown: Config.options.bar.privacy.showCamera
    readonly property bool screenShareShown: Config.options.bar.privacy.showScreenShare

    // PipeWire only reports cameras opened by its own clients, and browsers and
    // conferencing apps usually open /dev/video* themselves, so camera use is read
    // from the kernel. Clients going through PipeWire show up there as the daemon.
    property list<string> cameraProcesses: []
    readonly property list<string> pipewireDaemons: ["pipewire", "pipewire-pulse", "wireplumber"]

    readonly property var micStreams: Pipewire.linkGroups.values.filter(group => group.source?.type === PwNodeType.AudioSource && group.target?.type === PwNodeType.AudioInStream).map(group => group.target)
    readonly property var cameraStreams: root.videoStreams(true)
    readonly property var screenShareStreams: root.videoStreams(false)

    readonly property bool micInUse: root.micStreams.length > 0
    readonly property bool cameraInUse: root.cameraProcesses.length > 0 || root.cameraStreams.length > 0
    readonly property bool screenSharing: root.screenShareStreams.length > 0

    readonly property list<string> micApps: root.appNames(root.micStreams, [])
    readonly property list<string> cameraApps: root.appNames(root.cameraStreams, root.cameraProcesses)
    readonly property list<string> screenShareApps: root.appNames(root.screenShareStreams, [])

    readonly property bool active: (root.micShown && root.micInUse) || (root.cameraShown && root.cameraInUse) || (root.screenShareShown && root.screenSharing)

    // A capture portal publishes a video source too, so the node name is what tells a
    // real camera apart from a screen share.
    function isCameraNode(node): bool {
        const name = node?.name ?? "";
        return name.startsWith("v4l2_") || name.startsWith("libcamera_");
    }

    function videoStreams(fromCamera: bool): var {
        return Pipewire.linkGroups.values.filter(group => (group.source?.type & PwNodeType.Video) && root.isCameraNode(group.source) === fromCamera).map(group => group.target);
    }

    // A PipeWire client names itself, so the daemon holding the device on its behalf is
    // noise, unless it is the only thing left to name.
    function appNames(streams, processes): var {
        const named = streams.map(node => node?.properties?.["application.name"] || node?.description || node?.name || "").filter(name => name.length > 0);
        const merged = [...named, ...processes.filter(name => !root.pipewireDaemons.includes(name))];
        return [...new Set(merged.length > 0 ? merged : processes)];
    }

    PwObjectTracker {
        objects: [...root.micStreams, ...root.cameraStreams, ...root.screenShareStreams]
    }

    Timer {
        running: root.cameraShown
        interval: 3000
        repeat: true
        triggeredOnStart: true
        onTriggered: cameraProcess.running = true
    }

    Process {
        id: cameraProcess
        command: ["bash", "-c", "set -- /dev/video*; [ -e \"$1\" ] || exit 0; find /proc/[0-9]*/fd -lname '/dev/video*' -printf '%h/../comm\\n' 2>/dev/null | sort -u | xargs -r cat 2>/dev/null | sort -u"]
        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                root.cameraProcesses = output.length > 0 ? output.split("\n") : [];
            }
        }
    }

    onCameraShownChanged: if (!root.cameraShown) root.cameraProcesses = [];
}
