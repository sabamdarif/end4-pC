pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    readonly property string scriptDir: FileUtils.trimFileProtocol(`${Directories.scriptPath}/theming`)

    property list<string> iconThemes: []
    property list<string> gtkThemes: []
    property list<string> cursorThemes: []
    property string currentIconTheme: ""
    property string currentGtkTheme: ""
    property string currentCursorTheme: ""
    property int currentCursorSize: 24

    property list<var> matugenTemplates: []
    property bool templateRefreshPending: false

    function load() {}

    function refreshTemplates() {
        root.templateRefreshPending = true
        templateRefresh.restart()
    }

    function templateEnabled(name) {
        if (name === "quickshell" || name === "quickshell-seed") return true
        return !Config.options.appearance.matugenDisabled.includes(name)
    }

    function setTemplateEnabled(name, on) {
        if (name === "quickshell" || name === "quickshell-seed") return
        const disabled = Config.options.appearance.matugenDisabled
        if (on === !disabled.includes(name)) return
        Config.options.appearance.matugenDisabled = on
            ? disabled.filter(n => n !== name)
            : disabled.concat([name])
    }

    function refresh() {
        scanProc.running = true
        root.refreshTemplates()
    }

    function applyIconTheme(theme) {
        root.currentIconTheme = theme
        Quickshell.execDetached(["bash", `${root.scriptDir}/set-icon-theme.sh`, theme])
    }

    function applyGtkTheme(theme) {
        root.currentGtkTheme = theme
        Quickshell.execDetached(["bash", `${root.scriptDir}/set-gtk-theme.sh`, theme])
    }

    // Writes every cursor sink: gsettings + ~/.icons/default + niri (qssettings/shell.kdl)
    function applyCursorTheme(theme, size) {
        root.currentCursorTheme = theme
        root.currentCursorSize = size
        NiriConfig.options.cursor.theme = theme
        NiriConfig.options.cursor.size = size
        if (theme !== "")
            Quickshell.execDetached(["bash", `${root.scriptDir}/set-cursor-theme.sh`, theme, String(size)])
    }

    function regenerateColors() {
        Quickshell.execDetached(["bash", Directories.wallpaperSwitchScriptPath, "--noswitch"])
    }

    Process {
        id: matugenSetupProc
        running: Config.ready
        command: ["python3", FileUtils.trimFileProtocol(`${Directories.scriptPath}/colors/matugen.py`), "--install"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                console.warn("[SystemTheming] Matugen setup failed:", exitCode)
            root.refreshTemplates()
        }
    }

    Timer {
        id: templateRefresh
        interval: 100
        onTriggered: {
            if (matugenSourceProc.running || matugenSetupProc.running) return
            root.templateRefreshPending = false
            matugenSourceProc.running = true
        }
    }

    FileView {
        id: matugenConfigFile
        path: Qt.resolvedUrl(`${Directories.config}/matugen/config.toml`)
        watchChanges: true
        printErrors: false
        onFileChanged: {
            reload()
            root.refreshTemplates()
        }
    }

    Process {
        id: matugenSourceProc
        command: ["python3", FileUtils.trimFileProtocol(`${Directories.scriptPath}/colors/matugen.py`), "--list"]
        onExited: if (root.templateRefreshPending) root.refreshTemplates()
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.matugenTemplates = JSON.parse(text).filter(t => t.name !== "quickshell-seed")
                } catch (error) {
                    console.warn("[SystemTheming] Could not read Matugen templates:", error)
                }
            }
        }
    }

    Process {
        id: scanProc
        running: true
        command: ["bash", "-c", `
            echo :::ICON
            find /usr/share/icons "$HOME/.local/share/icons" "$HOME/.icons" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | xargs -r -n1 basename | sort -u | grep -Evx 'hicolor|default'
            echo :::GTK
            find /usr/share/themes "$HOME/.themes" "$HOME/.local/share/themes" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | xargs -r -n1 basename | sort -u
            echo :::CURSOR
            find /usr/share/icons "$HOME/.local/share/icons" "$HOME/.icons" -mindepth 2 -maxdepth 2 -type d -name cursors 2>/dev/null | sed 's|/cursors$||' | xargs -r -n1 basename | sort -u
            echo :::CURRENT
            (gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || echo) | tr -d "'"
            (gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo) | tr -d "'"
            (gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null || echo) | tr -d "'"
            gsettings get org.gnome.desktop.interface cursor-size 2>/dev/null || echo 24
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                const data = { ICON: [], GTK: [], CURSOR: [], CURRENT: [] }
                let bucket = ""
                for (const rawLine of text.split("\n")) {
                    const line = rawLine.trim()
                    if (line.startsWith(":::")) {
                        bucket = line.slice(3)
                        continue
                    }
                    if (bucket && bucket in data) data[bucket].push(line)
                }
                root.iconThemes = data.ICON.filter(l => l !== "")
                root.gtkThemes = data.GTK.filter(l => l !== "")
                root.cursorThemes = data.CURSOR.filter(l => l !== "")
                root.currentIconTheme = data.CURRENT[0] ?? ""
                root.currentGtkTheme = data.CURRENT[1] ?? ""
                root.currentCursorTheme = data.CURRENT[2] ?? ""
                root.currentCursorSize = parseInt(data.CURRENT[3]) || 24
            }
        }
    }
}
