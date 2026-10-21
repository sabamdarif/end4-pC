pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    // property string cliphistBinary: FileUtils.trimFileProtocol(`${Directories.home}/.cargo/bin/stash`)
    property string cliphistBinary: "cliphist"
    property real pasteDelay: 0.05
    property string pressPasteCommand: "ydotool key -d 1 29:1 47:1 47:0 29:0"
    property bool sloppySearch: Config.options?.search.sloppy ?? false
    property real scoreThreshold: 0.2
    property list<string> entries: []
    property bool incognito: false
    property var preIncognitoIds: ({})
    property list<string> incognitoEntryIds: []
    readonly property var preparedEntries: entries.map(a => ({
        name: Fuzzy.prepare(`${a.replace(/^\s*\S+\s+/, "")}`),
        entry: a
    }))
    function fuzzyQuery(search: string): var {
        if (search.trim() === "") {
            return entries;
        }
        if (root.sloppySearch) {
            const results = entries.slice(0, 100).map(str => ({
                entry: str,
                score: Levendist.computeTextMatchScore(str.toLowerCase(), search.toLowerCase())
            })).filter(item => item.score > root.scoreThreshold)
                .sort((a, b) => b.score - a.score)
            return results
                .map(item => item.entry)
        }

        return Fuzzy.go(search, preparedEntries, {
            all: true,
            key: "name"
        }).map(r => {
            return r.obj.entry
        });
    }

    function entryIsImage(entry) {
        return !!(/^\d+\t\[\[.*binary data.*\d+x\d+.*\]\]$/.test(entry))
    }

    function refresh() {
        readProc.buffer = []
        readProc.running = true
    }

    function copy(entry) {
        if (root.cliphistBinary.includes("cliphist")) // Classic cliphist
            Quickshell.execDetached(["bash", "-c", `printf '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} decode | wl-copy`]);
        else { // Stash
            const entryNumber = entry.split("\t")[0];
            Quickshell.execDetached(["bash", "-c", `${root.cliphistBinary} decode ${entryNumber} | wl-copy`]);
        }
    }

    function paste(entry) {
        if (root.cliphistBinary.includes("cliphist")) // Classic cliphist
            Quickshell.execDetached(["bash", "-c", `printf '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} decode | wl-copy && wl-paste`]);
        else { // Stash
            const entryNumber = entry.split("\t")[0];
            Quickshell.execDetached(["bash", "-c", `${root.cliphistBinary} decode ${entryNumber} | wl-copy; ${root.pressPasteCommand}`]);
        }
    }

    function superpaste(count, isImage = false) {
        // Find entries
        const targetEntries = entries.filter(entry => {
            if (!isImage) return true;
            return entryIsImage(entry);
        }).slice(0, count)
        const pasteCommands = [...targetEntries].reverse().map(entry => `printf '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} decode | wl-copy && sleep ${root.pasteDelay} && ${root.pressPasteCommand}`)
        // Act
        Quickshell.execDetached(["bash", "-c", pasteCommands.join(` && sleep ${root.pasteDelay} && `)]);
    }

    Process {
        id: deleteProc
        property string entry: ""
        command: ["bash", "-c", `echo '${StringUtils.shellSingleQuoteEscape(deleteProc.entry)}' | ${root.cliphistBinary} delete`]
        function deleteEntry(entry) {
            deleteProc.entry = entry;
            deleteProc.running = true;
            deleteProc.entry = "";
        }
        onExited: (exitCode, exitStatus) => {
            root.refresh();
        }
    }

    function deleteEntry(entry) {
        deleteProc.deleteEntry(entry);
    }

    Process {
        id: wipeProc
        command: [root.cliphistBinary, "wipe"]
        onExited: (exitCode, exitStatus) => {
            root.refresh();
        }
    }

    function wipe() {
        root.preIncognitoIds = ({});
        root.incognitoEntryIds = [];
        wipeProc.running = true;
    }

    Connections {
        target: Quickshell
        function onClipboardTextChanged() {
            delayedUpdateTimer.restart()
        }
    }

    Timer {
        id: delayedUpdateTimer
        interval: Config.options.hacks.arbitraryRaceConditionDelay
        repeat: false
        onTriggered: {
            root.refresh()
        }
    }

    Process {
        id: readProc
        property list<string> buffer: []

        command: [root.cliphistBinary, "list"]

        stdout: SplitParser {
            onRead: (line) => {
                readProc.buffer.push(line)
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.entries = readProc.buffer;
                if (root.incognito) {
                    const tracked = [...root.incognitoEntryIds];
                    for (let i = 0; i < root.entries.length; i++) {
                        const match = root.entries[i].match(/^(\d+)\t/);
                        if (match && !root.preIncognitoIds[match[1]]) {
                            if (!tracked.includes(match[1]))
                                tracked.push(match[1]);
                        }
                    }
                    root.incognitoEntryIds = tracked;
                }
            } else {
                console.error("[Cliphist] Failed to refresh with code", exitCode, "and status", exitStatus);
            }
        }
    }

    Process {
        id: batchDeleteProc
        property string payload: ""
        command: ["bash", "-c", `printf '%b' "${batchDeleteProc.payload}" | ${root.cliphistBinary} delete`]
        function deleteEntries(ids) {
            if (!ids || ids.length === 0)
                return;
            batchDeleteProc.payload = ids.map(id => `${id}\\t\\n`).join("");
            batchDeleteProc.running = true;
        }
        onExited: (exitCode, exitStatus) => {
            batchDeleteProc.payload = "";
            root.refresh();
        }
    }

    Process {
        id: stopIncognitoProc
        property list<string> buffer: []
        command: [root.cliphistBinary, "list"]

        stdout: SplitParser {
            onRead: (line) => {
                stopIncognitoProc.buffer.push(line);
            }
        }

        onExited: (exitCode, exitStatus) => {
            const toDeleteMap = {};
            if (exitCode === 0) {
                for (let i = 0; i < stopIncognitoProc.buffer.length; i++) {
                    const match = stopIncognitoProc.buffer[i].match(/^(\d+)\t/);
                    if (match && !root.preIncognitoIds[match[1]])
                        toDeleteMap[match[1]] = true;
                }
            }
            for (let i = 0; i < root.incognitoEntryIds.length; i++) {
                toDeleteMap[root.incognitoEntryIds[i]] = true;
            }
            root.preIncognitoIds = ({});
            root.incognitoEntryIds = [];
            Quickshell.clipboardText = "";
            Quickshell.execDetached(["wl-copy", "--clear"]);

            const ids = Object.keys(toDeleteMap);
            if (ids.length > 0) {
                batchDeleteProc.deleteEntries(ids);
            } else {
                root.refresh();
            }
        }
    }

    function startIncognito() {
        root.incognito = true;
        const ids = {};
        for (let i = 0; i < root.entries.length; i++) {
            const match = root.entries[i].match(/^(\d+)\t/);
            if (match)
                ids[match[1]] = true;
        }
        root.preIncognitoIds = ids;
        root.incognitoEntryIds = [];
    }

    function stopIncognito() {
        if (!root.incognito)
            return;
        root.incognito = false;
        stopIncognitoProc.buffer = [];
        stopIncognitoProc.running = true;
    }

    function toggleIncognito() {
        if (root.incognito)
            stopIncognito();
        else
            startIncognito();
    }

    IpcHandler {
        target: "cliphistService"

        function update(): void {
            root.refresh()
        }

        function toggleIncognito(): void {
            root.toggleIncognito()
        }
    }
}
