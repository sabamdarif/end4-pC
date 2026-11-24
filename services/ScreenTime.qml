pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import "Wellbeing.js" as Wellbeing

Singleton {
    id: root
    readonly property bool isEnabled: Config.ready && Config.options.wellbeing.enable
    readonly property bool tracking: root.isEnabled && NiriData.isNiri
    readonly property bool sessionActive: !GlobalStates.screenLocked && !idleMonitor.isIdle
    property var days: []
    property int revision: 0
    property string todayKey: Wellbeing.dateKey(new Date())
    readonly property var today: days.find(day => day.date === todayKey) || Wellbeing.emptyDay(todayKey)
    readonly property var appLimits: Config.options.wellbeing.appLimits
    readonly property int totalScreentime: today.active || 0
    readonly property var appsData: today.apps || ({})
    readonly property var hourlyUsage: today.hours || ({})
    property string lastError: ""
    function load() { historyFile.reload(); }

    IdleMonitor { id: idleMonitor; timeout: 300; enabled: root.tracking; respectInhibitors: true }
    function pushState() {
        if (trackerProc.running) trackerProc.write(JSON.stringify({ active: root.sessionActive }) + "\n");
    }
    onSessionActiveChanged: root.pushState()
    Process {
        id: trackerProc
        command: ["python3", Quickshell.shellPath("scripts/screentime/screentime_tracker.py"), "--state-stdin"]
        running: root.tracking
        stdinEnabled: true
        onStarted: { root.lastError = ""; root.pushState(); }
        stdout: SplitParser {
            onRead: line => {
                try {
                    const event = JSON.parse(line);
                    if (event.limit) root.notifyLimit(event.limit);
                    if (event.error) root.lastError = Translation.tr("Screen time tracking stopped to protect your history: %1").arg(event.message || "");
                } catch (error) { root.lastError = Translation.tr("Could not read screen time tracker output."); }
            }
        }
        onExited: code => {
            if (root.tracking && code !== 0 && root.lastError === "") root.lastError = Translation.tr("The screen time tracker stopped unexpectedly.");
            historyFile.reload();
        }
    }
    FileView {
        id: historyFile
        path: Directories.shellConfig + "/screentime.json"
        watchChanges: true
        printErrors: false
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound) root.lastError = Translation.tr("Could not read screen time history.");
        }
        onFileChanged: reload()
        onLoaded: {
            try {
                const data = JSON.parse(text());
                const entries = Array.isArray(data) ? data : data.days;
                if (!Array.isArray(entries)) throw new Error("Invalid history");
                root.days = entries;
                root.todayKey = Wellbeing.dateKey(new Date());
                root.revision++;
            } catch (error) { root.lastError = Translation.tr("Could not read screen time history."); }
        }
    }
    Timer {
        running: root.isEnabled
        interval: 60000
        repeat: true
        onTriggered: root.todayKey = Wellbeing.dateKey(new Date())
    }
    function notifyLimit(limit) {
        const summary = limit.kind === "daily" ? Translation.tr("Daily screen time limit reached")
            : Translation.tr("%1 limit reached").arg(root.formatAppName(limit.appId));
        Quickshell.execDetached(["notify-send", "-a", Translation.tr("Digital wellbeing"), "-i", "preferences-system-time",
            "-h", "boolean:suppress-sound:true", "--", summary, Translation.tr("%1 today").arg(root.formatTime(limit.used))]);
        if (Config.options.sounds.notification) Audio.playSystemSound("message-new-instant");
    }
    function setAppLimit(appId, minutes) {
        if (!appId || !Number.isInteger(minutes) || minutes < 0 || minutes > 1440) return;
        const limits = Object.assign({}, root.appLimits);
        if (minutes > 0) limits[appId] = minutes;
        else delete limits[appId];
        Config.options.wellbeing.appLimits = limits;
    }
    function removeAppLimit(appId) { root.setAppLimit(appId, 0); }
    function formatTime(seconds) {
        const split = Wellbeing.splitDuration(seconds || 0);
        return split.hours > 0 ? Translation.tr("%1h %2m").arg(split.hours).arg(split.minutes) : Translation.tr("%1m").arg(split.minutes);
    }
    function getSortedApps() { return Wellbeing.topApps([root.today]).map(app => ({ name: app.appId, time: app.seconds })); }
    function formatAppName(appId) {
        if (!appId) return "";
        const entry = DesktopEntries.heuristicLookup(appId);
        if (entry?.name) return entry.name;
        const name = String(appId).split(".").pop();
        return name.charAt(0).toUpperCase() + name.slice(1);
    }
}
