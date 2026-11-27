pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io
import "NiriShortcuts.js" as Shortcuts

Singleton {
    id: root

    readonly property string parserPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/niri/list-binds.py`)
    readonly property string configPath: FileUtils.trimFileProtocol(`${Directories.config}/niri/config.kdl`)

    // Raw parser output, in niri application order (all occurrences kept)
    property list<var> rawBinds: []
    property string modKey: "Super"
    property bool included: true
    property string errorText: ""
    property bool refreshPending: false
    readonly property bool loading: getBinds.running
    readonly property var groups: Shortcuts.groupedBinds(root.binds)
    readonly property int overriddenBy: root.binds.filter(b => b.overriddenByConfig).length
    readonly property var compositorActions: Shortcuts.COMPOSITOR_ACTIONS.map(a => ({
        value: a[0], displayName: Translation.tr(a[1]), icon: ""
    }))

    readonly property list<var> binds: Shortcuts.effectiveBinds(root.rawBinds, root.modKey).map(b =>
        b.title === b.action ? Object.assign({}, b, {title: root.actionLabel(b.action)}) : b)

    function actionLabel(action) {
        const tokens = Shortcuts.spawnTokens(action)
        if (tokens?.length) {
            const call = tokens.indexOf("call")
            if (tokens.includes("ipc") && call >= 0)
                return Translation.tr("Shell action: %1").arg(tokens.slice(call + 1).join(" "))
            return Translation.tr("Launch %1").arg(tokens[0])
        }
        const base = action.split(/\s+/)[0]
        const preset = root.compositorActions.find(a => a.value.split(/\s+/)[0] === base)
        return preset ? preset.displayName + action.slice(base.length) : action
    }

    function refresh() {
        if (getBinds.running) {
            root.refreshPending = true
            return
        }
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
        target: NiriConfig
        enabled: NiriData.isNiri
        function onConfigReloaded() { refreshDelay.restart() }
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

        stdout: StdioCollector { id: bindOutput }
        stderr: StdioCollector { id: bindError }
        onExited: code => {
            if (code !== 0) {
                root.errorText = Translation.tr("Could not read shortcuts: %1").arg(bindError.text.trim())
            } else {
                try {
                    const data = JSON.parse(bindOutput.text)
                    root.modKey = data.modKey
                    root.included = data.included
                    if (JSON.stringify(root.rawBinds) !== JSON.stringify(data.binds)) root.rawBinds = data.binds
                    root.errorText = ""
                } catch (error) {
                    root.errorText = Translation.tr("Could not read shortcuts: %1").arg(error.message)
                }
            }
            if (root.refreshPending) {
                root.refreshPending = false
                root.refresh()
            }
        }
    }
}
