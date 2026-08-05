pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Scope {
    id: root

    function dismiss() {
        GlobalStates.regionSelectorOpen = false
    }

    property var action: RegionSelection.SnipAction.Copy
    property var selectionMode: RegionSelection.SelectionMode.RectCorners
    
    Variants {
        model: Quickshell.screens
        delegate: Loader {
            id: regionSelectorLoader
            required property var modelData
            active: GlobalStates.regionSelectorOpen

            sourceComponent: RegionSelection {
                screen: regionSelectorLoader.modelData
                onDismiss: root.dismiss()
                action: root.action
                selectionMode: root.selectionMode
            }
        }
    }

    function captureCommand(area = false) {
        const saveDir = StringUtils.shellSingleQuoteEscape(Config.options.screenSnip.savePath || Directories.screenshotTemp)
        const keepFile = Config.options.screenSnip.savePath !== ""
        const grimArgs = area ? `-g "$(slurp)"` : ""
        return `mkdir -p '${saveDir}' && filePath='${saveDir}/screenshot-'$(date '+%Y-%m-%d_%H.%M.%S').png && \
            grim ${grimArgs} "$filePath" && \
            if command -v satty >/dev/null 2>&1; then satty --filename "$filePath" --output-filename "$filePath"; \
            elif command -v swappy >/dev/null 2>&1; then swappy -f "$filePath" -o "$filePath"; fi && \
            wl-copy < "$filePath" && \
            notify-send "Screenshot ${keepFile ? "Saved" : "Copied"}" "${keepFile ? "Saved to $filePath" : "Copied to clipboard"}" -a "Screenshot" -i "image-x-generic" \
            ${keepFile ? "" : "&& rm -f \"$filePath\""}`
    }

    function screenshot() {
        Quickshell.execDetached(["bash", "-c", root.captureCommand(false)]);
    }

    function areaScreenshot() {
        if (Persistent.states.record.enable) {
            Quickshell.execDetached(["bash", "-c", root.captureCommand(true)]);
            return;
        }
        root.action = RegionSelection.SnipAction.Edit
        root.selectionMode = RegionSelection.SelectionMode.RectCorners
        GlobalStates.regionSelectorOpen = true
    }

    function search() {
        root.action = RegionSelection.SnipAction.Search
        if (Config.options.search.imageSearch.useCircleSelection) {
            root.selectionMode = RegionSelection.SelectionMode.Circle
        } else {
            root.selectionMode = RegionSelection.SelectionMode.RectCorners
        }
        GlobalStates.regionSelectorOpen = true
    }

    function ocr() {
        root.action = RegionSelection.SnipAction.CharRecognition
        root.selectionMode = RegionSelection.SelectionMode.RectCorners
        GlobalStates.regionSelectorOpen = true
    }

    function record() {
        if (Persistent.states.record.enable) {
            Quickshell.execDetached([Directories.recordScriptPath]);
            return;
        }
        root.action = RegionSelection.SnipAction.Record
        root.selectionMode = RegionSelection.SelectionMode.RectCorners
        GlobalStates.regionSelectorOpen = true
    }

    function recordWithSound() {
        if (Persistent.states.record.enable) {
            Quickshell.execDetached([Directories.recordScriptPath]);
            return;
        }
        root.action = RegionSelection.SnipAction.RecordWithSound
        root.selectionMode = RegionSelection.SelectionMode.RectCorners
        GlobalStates.regionSelectorOpen = true
    }

    IpcHandler {
        target: "region"

        function screenshot() {
            root.screenshot()
        }
        function areaScreenshot() {
            root.areaScreenshot()
        }
        function search() {
            root.search()
        }
        function ocr() {
            root.ocr()
        }
        function record() {
            root.record()
        }
        function recordWithSound() {
            root.recordWithSound()
        }
    }

    NiriSafeShortcut {
        name: "screenshot"
        description: "Takes a fullscreen screenshot"
        onPressed: root.screenshot()
    }
    NiriSafeShortcut {
        name: "regionScreenshot"
        description: "Takes a screenshot of the selected region"
        onPressed: root.areaScreenshot()
    }
    NiriSafeShortcut {
        name: "regionSearch"
        description: "Searches the selected region"
        onPressed: root.search()
    }
    NiriSafeShortcut {
        name: "regionOcr"
        description: "Recognizes text in the selected region"
        onPressed: root.ocr()
    }
    NiriSafeShortcut {
        name: "regionRecord"
        description: "Records the selected region"
        onPressed: root.record()
    }
    NiriSafeShortcut {
        name: "regionRecordWithSound"
        description: "Records the selected region with sound"
        onPressed: root.recordWithSound()
    }
}