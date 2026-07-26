pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Autostart entries the shell does NOT own (Apps settings page).
 *
 * Backend: scripts/niri/autostart-entries.py
 *  - niri: `spawn-at-startup` / `spawn-sh-at-startup` in the user's own
 *    config.kdl and its includes. qssettings/autostart.kdl is excluded —
 *    that one is generated from NiriConfig.options.autostart and has its
 *    own editor. Disabling comments the line out; removing deletes it.
 *  - xdg: .desktop files in ~/.config/autostart and /etc/xdg/autostart.
 *    Disabling writes Hidden=true into a user copy; removing deletes the
 *    user file, or masks the entry when a system copy would come back.
 *
 * Every mutation re-lists afterwards: line numbers go stale on each edit.
 */
Singleton {
    id: root

    readonly property string parserPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/niri/autostart-entries.py`)
    readonly property string configPath: FileUtils.trimFileProtocol(`${Directories.config}/niri/config.kdl`)

    // [{file, line, raw, node, command, enabled}]
    property list<var> niriEntries: []
    // [{id, path, name, command, enabled, note, hasUser, hasSystem}]
    property list<var> xdgEntries: []
    property string lastError: ""

    function refresh() {
        listProc.running = false
        listProc.running = true
    }

    function setNiriEnabled(entry, enabled) {
        if ((entry?.enabled ?? true) === enabled) return
        root.run(["niri-toggle", "--file", entry.file, "--line", String(entry.line), "--expect", entry.raw])
    }

    function removeNiri(entry) {
        root.run(["niri-remove", "--file", entry.file, "--line", String(entry.line), "--expect", entry.raw])
    }

    function setXdgEnabled(entry, enabled) {
        root.run(["xdg-set", "--id", entry.id, "--enabled", enabled ? "1" : "0"])
    }

    function removeXdg(entry) {
        root.run(["xdg-remove", "--id", entry.id])
    }

    function run(args) {
        root.lastError = ""
        mutateProc.exec(["python3", root.parserPath, ...args, "--path", root.configPath])
    }

    Process {
        id: listProc
        // Runs everywhere: the xdg half is compositor-independent, and the
        // niri half comes back empty when there is no config.kdl
        running: true
        command: ["python3", root.parserPath, "list", "--path", root.configPath]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    root.niriEntries = data.niri ?? []
                    root.xdgEntries = data.xdg ?? []
                } catch (e) {
                    console.error("[SystemAutostart] Error parsing entries:", e)
                }
            }
        }
    }

    Process {
        id: mutateProc
        stderr: StdioCollector {
            onStreamFinished: root.lastError = text.trim()
        }
        onExited: root.refresh()
    }
}
