pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

Process {
    id: root

    property string url: ""
    property bool enabled: true
    readonly property string source: {
        if (!enabled || url.length === 0) return "";
        if (url.startsWith("file://")) return url;
        return downloadedUrl === url ? Qt.resolvedUrl(filePath) : "";
    }
    readonly property string filePath: `${Directories.coverArt}/${Qt.md5(url)}`
    property string requestedUrl: ""
    property string downloadedUrl: ""

    function fetch() {
        if (running || !enabled || !/^https?:\/\//i.test(url) || downloadedUrl === url) return;
        requestedUrl = url;
        command = ["bash", Quickshell.shellPath("scripts/images/fetch-cover.sh"), filePath, requestedUrl];
        running = true;
    }

    onUrlChanged: fetch()
    onEnabledChanged: fetch()
    Component.onCompleted: fetch()
    onExited: (exitCode, exitStatus) => {
        downloadedUrl = exitCode === 0 ? requestedUrl : "";
        // Process cannot restart while running, so fetch the latest track after it exits.
        if (requestedUrl !== url) fetch();
    }
}
