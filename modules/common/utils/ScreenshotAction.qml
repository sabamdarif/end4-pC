pragma ComponentBehavior: Bound
pragma Singleton
import qs.modules.common
import qs.modules.common.utils
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import Qt.labs.synchronizer
import Quickshell

Singleton {
    id: root

    enum Action {
        Copy,
        Edit,
        Search,
        CharRecognition,
        Record,
        RecordWithSound
    }

    property string imageSearchEngineBaseUrl: Config.options.search.imageSearch.imageSearchEngineBaseUrl
    property string fileUploadApiEndpoint: "https://uguu.se/upload"

    function getCommand(x, y, width, height, screenshotPath, action, saveDir = "") {
        // Set command for action
        const rx = Math.round(x);
        const ry = Math.round(y);
        const rw = Math.round(width);
        const rh = Math.round(height);
        const cropBase = `magick ${StringUtils.shellSingleQuoteEscape(screenshotPath)} `
            + `-crop ${rw}x${rh}+${rx}+${ry} +repage`
        const cropToStdout = `${cropBase} png:-`
        const cropInPlace = `${cropBase} '${StringUtils.shellSingleQuoteEscape(screenshotPath)}'`
        const cleanup = `rm '${StringUtils.shellSingleQuoteEscape(screenshotPath)}'`
        const slurpRegion = `${rx},${ry} ${rw}x${rh}`
        const uploadAndGetUrl = (filePath) => {
            return `curl -sF files[]=@'${StringUtils.shellSingleQuoteEscape(filePath)}' ${root.fileUploadApiEndpoint} | jq -r '.files[0].url'`
        }
        const escapedScreenshotPath = StringUtils.shellSingleQuoteEscape(screenshotPath)
        const annotationCommand = `if command -v satty >/dev/null 2>&1; then satty --filename '${escapedScreenshotPath}' --output-filename '${escapedScreenshotPath}'; elif command -v swappy >/dev/null 2>&1; then swappy -f '${escapedScreenshotPath}' -o '${escapedScreenshotPath}'; else notify-send 'Screenshot editor unavailable' 'Install satty or swappy to annotate screenshots' -a 'Screenshot' -i 'dialog-warning'; fi`;
        const notifyCopied = `notify-send 'Screenshot Copied' 'Copied to clipboard' -a 'Screenshot' -i 'image-x-generic'`
        const notifySaved = `notify-send 'Screenshot Saved' "Saved to $savePath" -a 'Screenshot' -i 'image-x-generic'`
        switch (action) {
            case ScreenshotAction.Action.Copy:
                if (saveDir === "") {
                    // not saving the screenshot, just copy to clipboard
                    return ["bash", "-c", `${cropToStdout} | wl-copy && ${notifyCopied} && ${cleanup}`]
                }
                return [
                    "bash", "-c",
                    `set -o pipefail && mkdir -p '${StringUtils.shellSingleQuoteEscape(saveDir)}' && \
                    saveFileName="screenshot-$(date '+%Y-%m-%d_%H.%M.%S').png" && \
                    savePath='${StringUtils.shellSingleQuoteEscape(saveDir)}'/"$saveFileName" && \
                    ${cropToStdout} | tee "$savePath" | wl-copy && \
                    ${notifySaved} && ${cleanup}`
                ]

                break;
            case ScreenshotAction.Action.Edit:
                if (saveDir === "") {
                    return ["bash", "-c", `${cropInPlace} && ${annotationCommand} && wl-copy < '${escapedScreenshotPath}' && ${notifyCopied} && ${cleanup}`]
                }
                return ["bash", "-c", `mkdir -p '${StringUtils.shellSingleQuoteEscape(saveDir)}' && savePath='${StringUtils.shellSingleQuoteEscape(saveDir)}/screenshot-'$(date '+%Y-%m-%d_%H.%M.%S').png && ${cropInPlace} && ${annotationCommand} && cp '${escapedScreenshotPath}' "$savePath" && wl-copy < "$savePath" && ${notifySaved} && ${cleanup}`]
            case ScreenshotAction.Action.Search:
                return ["bash", "-c", `${cropInPlace} && xdg-open "${root.imageSearchEngineBaseUrl}$(${uploadAndGetUrl(screenshotPath)})" && ${cleanup}`]
                break;
            case ScreenshotAction.Action.CharRecognition:
                return ["bash", "-c", `${cropInPlace} && tesseract '${StringUtils.shellSingleQuoteEscape(screenshotPath)}' stdout -l $(tesseract --list-langs | awk 'NR>1{print $1}' | tr '\\n' '+' | sed 's/\\+$/\\n/') | wl-copy && ${cleanup}`]
                break;
            case ScreenshotAction.Action.Record:
                return ["bash", "-c", `${Directories.recordScriptPath} --region '${slurpRegion}'`]
                break;
            case ScreenshotAction.Action.RecordWithSound:
                return ["bash", "-c", `${Directories.recordScriptPath} --region '${slurpRegion}' --sound`]
                break;
            default:
                console.warn("[Region Selector] Unknown snip action, skipping snip.");
                return;
        }
    }
}
