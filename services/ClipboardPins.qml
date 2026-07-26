pragma Singleton
pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Pinned clipboard entries.
 *
 * cliphist has no notion of pinning, so an entry is decoded at the moment it is pinned
 * and stored shell-side. That way a pin survives eviction from cliphist's rolling
 * history and even `cliphist wipe`.
 */
Singleton {
    id: root
    readonly property string pinsDir: FileUtils.trimFileProtocol(`${Directories.state}/user/clipboard-pins`)
    readonly property string pinsFilePath: `${root.pinsDir}/pins.json`
    readonly property int maxTextLength: 100000

    property alias pins: pinsAdapter.pins
    property bool ready: false

    function entryId(entry) {
        const match = String(entry ?? "").match(/^(\d+)\t/);
        return match ? match[1] : "";
    }

    function entryLabel(entry) {
        return StringUtils.cleanCliphistEntry(String(entry ?? ""));
    }

    /**
     * Images are matched by cliphist id because their preview line
     * ("[[ binary data 129 KiB png 1920x1080 ]]") isn't unique. Text is matched by
     * content so it keeps matching after cliphist renumbers.
     */
    function pinFor(entry) {
        const id = root.entryId(entry);
        const label = root.entryLabel(entry);
        const isImage = Cliphist.entryIsImage(entry);
        for (let i = 0; i < root.pins.length; i++) {
            const pin = root.pins[i];
            if (pin.isImage !== isImage)
                continue;
            if (isImage ? pin.id === id : pin.label === label)
                return pin;
        }
        return null;
    }

    function isPinned(entry) {
        return root.pinFor(entry) !== null;
    }

    function toggle(entry) {
        const existing = root.pinFor(entry);
        if (existing)
            root.remove(existing.key);
        else
            root.pin(entry);
    }

    function pin(entry) {
        if (!entry || root.isPinned(entry))
            return;
        if (Cliphist.entryIsImage(entry))
            imagePinProc.pinEntry(entry);
        else
            textPinProc.pinEntry(entry);
    }

    function remove(key) {
        const kept = [];
        for (let i = 0; i < root.pins.length; i++) {
            const pin = root.pins[i];
            if (pin.key === key) {
                if (pin.isImage && pin.imagePath)
                    Quickshell.execDetached(["rm", "-f", pin.imagePath]);
                continue;
            }
            kept.push(pin);
        }
        root.pins = kept;
    }

    function clear() {
        Quickshell.execDetached(["bash", "-c", `rm -f '${root.pinsDir}'/*.png`]);
        root.pins = [];
    }

    function copy(pin) {
        if (!pin)
            return;
        if (pin.isImage)
            Quickshell.execDetached(["bash", "-c", `wl-copy --type image/png < '${StringUtils.shellSingleQuoteEscape(pin.imagePath)}'`]);
        else
            Quickshell.clipboardText = pin.content;
    }

    function addPin(pin) {
        const updated = [pin];
        for (let i = 0; i < root.pins.length; i++) {
            if (root.pins[i].key !== pin.key)
                updated.push(root.pins[i]);
        }
        root.pins = updated;
    }

    Process {
        id: textPinProc
        property string pendingEntry: ""
        property string collected: ""

        command: ["bash", "-c", `printf '${StringUtils.shellSingleQuoteEscape(textPinProc.pendingEntry)}' | ${Cliphist.cliphistBinary} decode`]

        function pinEntry(entry) {
            textPinProc.collected = "";
            textPinProc.pendingEntry = entry;
            textPinProc.running = true;
        }

        stdout: StdioCollector {
            onStreamFinished: textPinProc.collected = text
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.error("[ClipboardPins] Failed to decode text entry, code", exitCode);
                textPinProc.pendingEntry = "";
                return;
            }
            const content = textPinProc.collected.slice(0, root.maxTextLength);
            root.addPin({
                key: `t${Date.now()}`,
                id: root.entryId(textPinProc.pendingEntry),
                label: root.entryLabel(textPinProc.pendingEntry),
                isImage: false,
                content: content,
                imagePath: ""
            });
            textPinProc.pendingEntry = "";
            textPinProc.collected = "";
        }
    }

    Process {
        id: imagePinProc
        property string pendingEntry: ""
        property string pendingKey: ""
        property string pendingPath: ""

        command: ["bash", "-c", `mkdir -p '${root.pinsDir}' && printf '${StringUtils.shellSingleQuoteEscape(imagePinProc.pendingEntry)}' | ${Cliphist.cliphistBinary} decode > '${StringUtils.shellSingleQuoteEscape(imagePinProc.pendingPath)}'`]

        function pinEntry(entry) {
            imagePinProc.pendingKey = `i${Date.now()}`;
            imagePinProc.pendingPath = `${root.pinsDir}/${imagePinProc.pendingKey}.png`;
            imagePinProc.pendingEntry = entry;
            imagePinProc.running = true;
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.error("[ClipboardPins] Failed to decode image entry, code", exitCode);
                Quickshell.execDetached(["rm", "-f", imagePinProc.pendingPath]);
                imagePinProc.pendingEntry = "";
                return;
            }
            root.addPin({
                key: imagePinProc.pendingKey,
                id: root.entryId(imagePinProc.pendingEntry),
                label: root.entryLabel(imagePinProc.pendingEntry),
                isImage: true,
                content: "",
                imagePath: imagePinProc.pendingPath
            });
            imagePinProc.pendingEntry = "";
        }
    }

    Timer {
        id: fileWriteTimer
        interval: 100
        repeat: false
        onTriggered: pinsFileView.writeAdapter()
    }

    FileView {
        id: pinsFileView
        path: root.pinsFilePath

        onAdapterUpdated: fileWriteTimer.restart()
        onLoaded: root.ready = true
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.ready = true;
                fileWriteTimer.restart();
            } else {
                console.error("[ClipboardPins] Failed to load pins file:", error);
            }
        }

        adapter: JsonAdapter {
            id: pinsAdapter
            property list<var> pins: []
        }
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", root.pinsDir]);
    }
}
