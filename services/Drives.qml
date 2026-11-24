pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

Singleton {
    id: root
    property int subscribers: 0
    readonly property bool enabled: root.subscribers > 0 || [
        ...Config.options.bar.layouts.leftLayout, ...Config.options.bar.layouts.middleLayout,
        ...Config.options.bar.layouts.rightLayout].includes("removableDrive")
    property var allDrives: []
    property var removableDrives: []
    readonly property bool hasRemovableDrives: removableDrives.length > 0
    readonly property int removableVolumeCount: removableDrives.reduce((count, disk) => count + disk.partitions.length, 0)
    property string lastError: ""
    property var smartData: ({})
    property var actionQueue: []
    readonly property bool busy: actionProc.running || actionQueue.length > 0
    readonly property bool refreshing: scanProc.running
    readonly property bool smartBusy: smartProc.running

    function formatBytes(bytes) {
        if (bytes === null || bytes === undefined) return Translation.tr("Unavailable");
        const units = ["B", "KiB", "MiB", "GiB", "TiB"];
        let value = bytes, unit = 0;
        while (value >= 1024 && unit < units.length - 1) { value /= 1024; unit++; }
        return value.toFixed(unit > 0 ? 1 : 0) + " " + units[unit];
    }
    function refresh() {
        if (!scanProc.running) scanProc.exec(["python3", Quickshell.shellPath("scripts/system/drives_info.py")]);
    }
    function partition(device) {
        for (const disk of root.allDrives) {
            const part = disk.partitions.find(p => p.device === device);
            if (part) return part;
        }
        return null;
    }
    function runActions(commands) {
        if (root.busy || commands.length === 0) return;
        root.lastError = "";
        root.actionQueue = commands;
        root.runNext();
    }
    function runNext() {
        if (root.actionQueue.length === 0) { root.refresh(); return; }
        const commands = root.actionQueue.slice();
        const command = commands.shift();
        root.actionQueue = commands;
        actionProc.exec(command);
    }
    function mountPartition(device) {
        const part = root.partition(device);
        if (!part || part.mountPoint || !part.filesystem || part.filesystem === "crypto_LUKS" || part.filesystem === "swap") return;
        root.runActions([part.kind === "mtp" ? ["gio", "mount", device] : ["udisksctl", "mount", "-b", device]]);
    }
    function unmountPartition(device) {
        const part = root.partition(device);
        if (!part || !part.mountPoint) return;
        root.runActions([part.kind === "mtp" ? ["gio", "mount", "-u", part.mountPoint] : ["udisksctl", "unmount", "-b", device]]);
    }
    function ejectDrive(device) {
        const disk = root.removableDrives.find(d => d.device === device);
        if (!disk) return;
        if (disk.kind === "mtp") {
            root.runActions(disk.partitions.filter(p => p.mountPoint).map(p => ["gio", "mount", "-u", p.mountPoint]));
            return;
        }
        const commands = disk.partitions.filter(p => p.mountPoint).map(p => ["udisksctl", "unmount", "-b", p.device]);
        commands.push(["udisksctl", "power-off", "-b", device]);
        root.runActions(commands);
    }
    function openPartition(device) {
        const part = root.partition(device);
        if (!part) return;
        if (part.mountPoint) Quickshell.execDetached(["xdg-open", part.mountPoint]);
        else root.mountPartition(device);
    }
    function checkHealth(device) {
        if (smartProc.running || !root.allDrives.some(d => d.device === device && d.kind !== "mtp")) return;
        root.lastError = "";
        smartProc.exec(["python3", Quickshell.shellPath("scripts/system/drives_info.py"), "--smart", device]);
    }
    onEnabledChanged: if (enabled) root.refresh()
    Component.onCompleted: if (enabled) root.refresh()

    Timer { interval: 15000; running: root.enabled; repeat: true; onTriggered: root.refresh() }
    Timer { id: refreshDelay; interval: 400; onTriggered: root.refresh() }
    Process {
        command: ["udevadm", "monitor", "--kernel", "--subsystem-match=block"]
        running: root.enabled
        stdout: SplitParser { onRead: line => refreshDelay.restart() }
    }
    Process {
        command: ["gio", "mount", "-o"]
        running: root.enabled
        stdout: SplitParser { onRead: line => refreshDelay.restart() }
    }
    Process {
        id: scanProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (data.error) {
                        root.lastError = Translation.tr("Could not read drives. Check that lsblk is installed.");
                        return;
                    }
                    root.allDrives = data.allDrives;
                    root.removableDrives = data.removableDrives;
                } catch (error) { root.lastError = Translation.tr("Could not read drive information."); }
            }
        }
    }
    Process {
        id: actionProc
        stderr: StdioCollector { id: actionError }
        onExited: code => {
            if (code !== 0) {
                root.actionQueue = [];
                root.lastError = Translation.tr("Drive operation failed: %1").arg(actionError.text.trim());
                root.refresh();
            } else root.runNext();
        }
    }
    Process {
        id: smartProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (data.error) {
                        root.lastError = Translation.tr("SMART data is unavailable. Install smartmontools and check device permissions; some USB bridges do not support SMART.");
                    } else root.smartData = Object.assign({}, root.smartData, { [data.device]: data });
                } catch (error) { root.lastError = Translation.tr("Could not read SMART information."); }
            }
        }
    }
}
