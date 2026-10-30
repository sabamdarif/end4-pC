pragma Singleton
pragma ComponentBehavior: Bound;

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common

Singleton {
    id: root

    readonly property bool isEnabled: (Config.options && Config.options.background && Config.options.background.widgets && Config.options.background.widgets.screentime && Config.options.background.widgets.screentime.enable) ? true : false

    property var parsedData: null
    readonly property int totalScreentime: parsedData ? (parsedData.total_screentime || 0) : 0
    readonly property int totalUptime: parsedData ? (parsedData.total_uptime || 0) : 0
    readonly property var appsData: parsedData ? (parsedData.apps || {}) : {}
    readonly property var hourlyUsage: parsedData ? (parsedData.hourly_usage || {}) : {}

    Process {
        id: trackerProc
        command: ["python3", Quickshell.shellPath("scripts/screentime/screentime_tracker.py")]
        running: root.isEnabled
    }

    FileView {
        id: screentimeFileView
        path: Quickshell.env("HOME") + "/.cache/screentime.json"
        watchChanges: root.isEnabled
        onFileChanged: {
            if (root.isEnabled) reload();
        }
        onLoaded: {
            try {
                const textData = screentimeFileView.text().trim();
                if (textData) {
                    root.parsedData = JSON.parse(textData);
                }
            } catch (e) {
                console.log("[ScreenTime] Error parsing JSON:", e);
            }
        }
    }

    function formatTime(seconds) {
        if (!seconds || seconds <= 0) return "0m";
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        if (h > 0) {
            return h + "h " + m + "m";
        }
        return m + "m";
    }

    function getSortedApps() {
        if (!appsData) return [];
        let list = [];
        for (let name in appsData) {
            list.push({ name: name, time: appsData[name] });
        }
        list.sort((a, b) => b.time - a.time);
        return list;
    }

    function formatAppName(name) {
        if (!name) return "";
        if (name.includes(".")) {
            const parts = name.split(".");
            name = parts[parts.length - 1];
        }
        return name.charAt(0).toUpperCase() + name.slice(1);
    }

    function formatHourAxis(seconds) {
        if (!seconds || seconds <= 0) return "0h/hr";
        const h = (seconds / 3600).toFixed(1);
        return h + "h/hr";
    }

    function updateLockState() {
        if (!root.isEnabled) return;
        if (GlobalStates.screenLocked) {
            Quickshell.execDetached(["touch", Quickshell.env("HOME") + "/.cache/screentime_locked"]);
        } else {
            Quickshell.execDetached(["rm", "-f", Quickshell.env("HOME") + "/.cache/screentime_locked"]);
        }
    }

    Connections {
        target: GlobalStates
        function onScreenLockedChanged() {
            root.updateLockState();
        }
    }

    onIsEnabledChanged: {
        if (root.isEnabled) {
            screentimeFileView.reload();
            root.updateLockState();
        } else {
            Quickshell.execDetached(["rm", "-f", Quickshell.env("HOME") + "/.cache/screentime_locked"]);
        }
    }

    Component.onCompleted: {
        if (root.isEnabled) {
            root.updateLockState();
            screentimeFileView.reload();
        }
    }

    Component.onDestruction: {
        Quickshell.execDetached(["rm", "-f", Quickshell.env("HOME") + "/.cache/screentime_locked"]);
    }
}
