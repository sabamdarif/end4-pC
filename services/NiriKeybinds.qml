pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Niri keybinds service (Shortcuts settings page backend).
 *
 * Runs scripts/niri/list-binds.py, which parses ~/.config/niri/config.kdl
 * and every `include`d file (glob includes too) plus qssettings/binds.kdl,
 * and emits ALL bind occurrences in niri's application order as
 * [{key, action, title, source}].
 *
 * This service computes the effective bind per key (in niri the LAST bind
 * for a key wins), tags binds coming from the settings app's override file
 * (qssettings/binds.kdl), and flags conflicts — an override that shadows a
 * bind the user defined in their own config files.
 */
Singleton {
    id: root

    readonly property string parserPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/niri/list-binds.py`)
    readonly property string configPath: FileUtils.trimFileProtocol(`${Directories.config}/niri/config.kdl`)

    // Raw parser output, in niri application order (all occurrences kept)
    property list<var> rawBinds: []

    // The override file may be reached through a symlinked config dir, so
    // compare by suffix instead of the literal NiriConfig.bindsKdlPath.
    function isOverrideSource(source) {
        return String(source ?? "").endsWith("/qssettings/binds.kdl")
    }

    // Same greps as the rofi settings-menu categories, made exclusive:
    // apps (spawn/open/launch/terminal/browser/file), workspace, window.
    function categoryOf(bind) {
        const text = `${bind.action ?? ""} ${bind.title ?? ""}`.toLowerCase()
        if (/spawn|open|launch|terminal|browser|file/.test(text)) return "apps"
        if (/workspace/.test(text)) return "workspace"
        if (/window|focus|move|close|fullscreen|maximize/.test(text)) return "window"
        return "other"
    }

    // One entry per key — the effective (last) occurrence — decorated with
    // isOverride, conflict (override shadowing an earlier user bind),
    // shadowedTitle/shadowedSource (what got shadowed) and category.
    readonly property list<var> binds: {
        const list = []
        const byKey = {}
        for (const bind of root.rawBinds) {
            const prev = byKey[bind.key]
            const entry = {
                key: bind.key,
                action: bind.action,
                title: bind.title,
                source: bind.source,
                isOverride: root.isOverrideSource(bind.source),
                conflict: false,
                shadowedTitle: "",
                shadowedSource: ""
            }
            if (prev !== undefined) {
                const shadowed = list[prev]
                entry.conflict = entry.isOverride && !shadowed.isOverride
                entry.shadowedTitle = shadowed.title
                entry.shadowedSource = shadowed.source
                list[prev] = entry
            } else {
                byKey[bind.key] = list.length
                list.push(entry)
            }
        }
        return list
    }

    function refresh() {
        getBinds.running = false
        getBinds.running = true
    }

    // Regenerating binds.kdl is debounced in NiriConfig (readWriteDelay),
    // so wait a moment before re-parsing after an override change.
    Timer {
        id: refreshDelay
        interval: 600
        onTriggered: root.refresh()
    }

    Connections {
        target: NiriConfig.options
        enabled: NiriData.isNiri

        function onBindOverridesChanged() {
            refreshDelay.restart()
        }
    }

    Process {
        id: getBinds
        running: NiriData.isNiri
        command: ["python3", root.parserPath, "--path", root.configPath]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.rawBinds = JSON.parse(text)
                } catch (e) {
                    console.error("[NiriKeybinds] Error parsing binds:", e)
                }
            }
        }
    }
}
