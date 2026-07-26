pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * xdg default applications for the Apps settings page.
 *
 * Current defaults are read via `xdg-settings get default-web-browser`
 * (browser) and `xdg-mime query default <mime>` (everything else).
 * Candidate apps per role come from the mimeinfo.cache index in every XDG
 * data dir (the same index xdg-open consults — quickshell's DesktopEntry
 * doesn't expose MimeType, so the cache is the reliable source), resolved
 * to display names through DesktopEntries. Applying uses
 * `xdg-settings set default-web-browser` / `xdg-mime default`.
 */
Singleton {
    id: root

    // role key -> mimetypes. The FIRST entry is queried for the current
    // default and used for candidate listing; the WHOLE list is applied
    // when the user picks a new default.
    readonly property var roleMimes: ({
        browser: ["x-scheme-handler/http", "x-scheme-handler/https", "text/html"],
        mail: ["x-scheme-handler/mailto"],
        files: ["inode/directory"],
        editor: ["text/plain"],
        image: ["image/png", "image/jpeg", "image/webp", "image/gif", "image/bmp", "image/svg+xml", "image/tiff"],
        pdf: ["application/pdf"],
        music: ["audio/mpeg", "audio/flac", "audio/x-wav", "audio/ogg", "audio/mp4", "audio/aac"],
        video: ["video/mp4", "video/x-matroska", "video/webm", "video/x-msvideo", "video/quicktime", "video/ogg"]
    })

    property var current: ({})     // role key -> desktop file id ("app.desktop")
    property var candidates: ({})  // role key -> [desktop file ids]
    property string lastError: ""

    function refresh() {
        readProc.running = false
        readProc.running = true
    }

    function entryFor(desktopId) {
        const bare = String(desktopId ?? "").replace(/\.desktop$/, "")
        if (bare === "") return null
        return DesktopEntries.byId(bare) ?? DesktopEntries.heuristicLookup(bare)
    }

    function displayName(desktopId) {
        return entryFor(desktopId)?.name ?? String(desktopId ?? "").replace(/\.desktop$/, "")
    }

    function iconFor(desktopId) {
        return entryFor(desktopId)?.icon ?? "application-x-executable"
    }

    function setDefault(key, desktopId) {
        if (!desktopId || desktopId === "" || !(key in roleMimes)) return
        if (key === "browser") {
            // Also sets the http/https scheme handlers + text/html internally
            applyProc.exec({ command: ["xdg-settings", "set", "default-web-browser", desktopId] })
        } else {
            applyProc.exec({ command: ["xdg-mime", "default", desktopId, ...roleMimes[key]] })
        }
    }

    function buildReadScript() {
        let s = 'set -f\n'
        s += 'caches=""\n'
        s += 'IFS=":"\n'
        s += 'for d in ${XDG_DATA_HOME:-$HOME/.local/share} ${XDG_DATA_DIRS:-/usr/local/share:/usr/share}; do\n'
        s += '  [ -f "$d/applications/mimeinfo.cache" ] && caches="$caches $d/applications/mimeinfo.cache"\n'
        s += 'done\n'
        s += 'unset IFS\n'
        s += 'cand() { grep -hs "^$1=" $caches | cut -d= -f2- | tr ";" "\\n" | grep -v "^$" | sort -u | tr "\\n" ";"; }\n'
        for (const key in roleMimes) {
            const primary = roleMimes[key][0]
            if (key === "browser")
                s += 'echo "CUR|browser|$(xdg-settings get default-web-browser 2>/dev/null)"\n'
            else
                s += `echo "CUR|${key}|$(xdg-mime query default ${primary} 2>/dev/null)"\n`
            s += `echo "CAND|${key}|$(cand ${primary})"\n`
        }
        return s
    }

    Process {
        id: applyProc
        environment: ({ LANG: "C", LC_ALL: "C" })
        property string collected: ""
        stderr: StdioCollector {
            onStreamFinished: applyProc.collected += text
        }
        onExited: (exitCode, exitStatus) => {
            root.lastError = exitCode === 0 ? "" : applyProc.collected.trim()
            applyProc.collected = ""
            root.refresh()
        }
    }

    Process {
        id: readProc
        running: true
        environment: ({ LANG: "C", LC_ALL: "C" })
        command: ["bash", "-c", root.buildReadScript()]
        stdout: StdioCollector {
            onStreamFinished: {
                const cur = {}
                const cand = {}
                for (const line of text.split("\n")) {
                    const parts = line.split("|")
                    if (parts.length < 3) continue
                    const kind = parts[0]
                    const key = parts[1]
                    const payload = parts.slice(2).join("|")
                    if (kind === "CUR")
                        cur[key] = payload.trim()
                    else if (kind === "CAND")
                        cand[key] = payload.split(";").map(s => s.trim()).filter(s => s !== "")
                }
                root.current = cur
                root.candidates = cand
            }
        }
    }
}
