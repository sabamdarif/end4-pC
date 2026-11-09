pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

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

    function captureCommand() {
        const saveDir = StringUtils.shellSingleQuoteEscape(Directories.screenshots)
        return `set -o pipefail && mkdir -p '${saveDir}' && filePath='${saveDir}/screenshot-'$(date '+%Y-%m-%d_%H.%M.%S').png && \
            grim -t png "$filePath" && \
            if command -v satty >/dev/null 2>&1; then satty --filename "$filePath" --output-filename "$filePath"; \
            else notify-send "Screenshot editor unavailable" "Install satty to annotate screenshots" -a "Screenshot" -i "dialog-warning"; fi && \
            wl-copy < "$filePath" && \
            notify-send "Screenshot Saved" "Saved to $filePath" -a "Screenshot" -i "image-x-generic"`
    }

    function screenshot() {
        Quickshell.execDetached(["bash", "-c", root.captureCommand()]);
    }

    function areaScreenshot() {
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
    }
}