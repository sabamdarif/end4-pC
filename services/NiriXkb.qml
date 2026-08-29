pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

/**
 * Exposes the active Xkb keyboard layout name and code for indicators.
 *
 * niri reports the layout as an xkb *description* ("English (US)"), which is
 * looked up in base.lst to get the short code shown in the bar.
 */
Singleton {
    id: root
    // You can read these
    property list<string> layoutCodes: []
    property var cachedLayoutCodes: ({})
    property string currentLayoutName: ""
    property string currentLayoutCode: ""
    // For the service
    property var baseLayoutFilePath: "/usr/share/X11/xkb/rules/base.lst"

    // Update the layout code according to the layout name (niri gives the name not the code)
    onCurrentLayoutNameChanged: root.updateLayoutCode()
    function updateLayoutCode() {
        if (cachedLayoutCodes.hasOwnProperty(currentLayoutName)) {
            root.currentLayoutCode = cachedLayoutCodes[currentLayoutName];
        } else {
            getLayoutProc.running = true;
        }
    }

    // Get the layout code from the base.lst file by grabbing the line with the current layout name
    Process {
        id: getLayoutProc
        command: ["cat", root.baseLayoutFilePath]

        stdout: StdioCollector {
            id: layoutCollector

            onStreamFinished: {
                const lines = layoutCollector.text.split("\n");
                const targetDescription = root.currentLayoutName;
                const foundLine = lines.find(line => {
                    // Skip comment lines and empty lines
                    if (!line.trim() || line.trim().startsWith('!'))
                        return false;

                    // Match layout: (whitespace + ) key + whitespace + description
                    const matchLayout = line.match(/^\s*(\S+)\s+(.+)$/);
                    if (matchLayout && matchLayout[2] === targetDescription) {
                        root.cachedLayoutCodes[matchLayout[2]] = matchLayout[1];
                        root.currentLayoutCode = matchLayout[1];
                        return true;
                    }

                    // Match variant: (whitespace + ) variant + whitespace + key + whitespace + description
                    const matchVariant = line.match(/^\s*(\S+)\s+(\S+)\s+(.+)$/);
                    if (matchVariant && matchVariant[3] === targetDescription) {
                        const complexLayout = matchVariant[2] + matchVariant[1];
                        root.cachedLayoutCodes[matchVariant[3]] = complexLayout;
                        root.currentLayoutCode = complexLayout;
                        return true;
                    }
                    
                    return false;
                });
                // console.log("[NiriXkb] Found line:", foundLine);
                // console.log("[NiriXkb] Layout:", root.currentLayoutName, "| Code:", root.currentLayoutCode);
                // console.log("[NiriXkb] Cached layout codes:", JSON.stringify(root.cachedLayoutCodes, null, 2));
            }
        }
    }

    // Available layouts and the active one. Refreshed on every niri layout switch.
    Process {
        id: fetchNiriLayoutsProc
        running: NiriData.isNiri
        command: ["niri", "msg", "-j", "keyboard-layouts"]

        stdout: StdioCollector {
            id: niriLayoutsCollector
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(niriLayoutsCollector.text);
                    const names = parsed["names"] ?? [];
                    if (names.length === 0) return;
                    root.layoutCodes = names;
                    root.currentLayoutName = names[parsed["current_idx"] ?? 0];
                    Config.options.osk.layout = root.currentLayoutName.split(" (")[0];
                } catch (e) {
                    console.log("[NiriXkb] Could not parse niri keyboard-layouts:", e);
                }
            }
        }
    }

    Connections {
        target: NiriData
        function onRawEvent(line) {
            if (line.includes("KeyboardLayout")) fetchNiriLayoutsProc.running = true;
        }
    }
}
