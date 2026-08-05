pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
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

    function screenshot() {
        const saveDir = Config.options.screenSnip.savePath !== "" ? Config.options.screenSnip.savePath : "";
        if (saveDir !== "") {
            const cmd = `mkdir -p '${saveDir}' && filePath="${saveDir}/screenshot-$(date '+%Y-%m-%d_%H.%M.%S').png" && grim "$filePath" && cat "$filePath" | wl-copy && notify-send "Screenshot Saved" "Saved to $filePath" -a "Screenshot" -i "image-x-generic"`;
            Quickshell.execDetached(["bash", "-c", cmd]);
        } else {
            const cmd = `grim - | wl-copy && notify-send "Screenshot Copied" "Copied to clipboard" -a "Screenshot" -i "image-x-generic"`;
            Quickshell.execDetached(["bash", "-c", cmd]);
        }
    }

    function areaScreenshot() {
        if (Persistent.states.record.enable) {
            const saveDir = Config.options.screenSnip.savePath !== "" ? Config.options.screenSnip.savePath : "";
            if (saveDir !== "") {
                const cmd = `mkdir -p '${saveDir}' && filePath="${saveDir}/screenshot-$(date '+%Y-%m-%d_%H.%M.%S').png" && grim -g "$(slurp)" "$filePath" && cat "$filePath" | wl-copy && notify-send "Screenshot Saved" "Saved to $filePath" -a "Screen Snip" -i "image-x-generic"`;
                Quickshell.execDetached(["bash", "-c", cmd]);
            } else {
                const cmd = `grim -g "$(slurp)" - | wl-copy && notify-send "Screenshot Copied" "Copied to clipboard" -a "Screen Snip" -i "image-x-generic"`;
                Quickshell.execDetached(["bash", "-c", cmd]);
            }
            return;
        }
        root.action = RegionSelection.SnipAction.Copy
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