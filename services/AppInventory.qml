pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    property list<var> flatpaks: []
    property var permissions: ({})
    property bool flatsealInstalled: false
    readonly property list<var> apps: {
        const systemApps = AppSearch.list.filter(app => !app.noDisplay).map(app => ({
            id: app.id,
            name: app.name,
            comment: app.comment ?? "",
            icon: app.icon,
            source: "system",
            package: "",
            size: ""
        }))
        const knownIds = systemApps.map(app => app.id)
        const flatpakApps = root.flatpaks.map(app => ({
            id: app.id,
            name: app.name || app.id,
            comment: app.comment || "",
            icon: AppSearch.guessIcon(app.id),
            source: "flatpak",
            package: app.id,
            size: app.size || ""
        }))
        return systemApps.concat(flatpakApps.filter(app => !knownIds.includes(app.id)))
            .sort((a, b) => a.name.localeCompare(b.name))
    }

    signal changed()

    Process {
        id: packageOwnerProc
        property string appId: ""
        stdout: StdioCollector {
            onStreamFinished: {
                const packageName = text.trim()
                if (packageName) Quickshell.execDetached(["pkexec", "pacman", "-Rns", packageName])
            }
        }
    }

    Process {
        id: flatpakProc
        command: ["bash", "-c", "flatpak list --app --columns=application,name,comment,size 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const rows = []
                for (const line of text.trim().split("\\n")) {
                    if (!line.trim()) continue
                    const parts = line.split("\\t")
                    if (parts[0]) rows.push({ id: parts[0], name: parts[1] ?? parts[0], comment: parts[2] ?? "", size: parts[3] ?? "" })
                }
                root.flatpaks = rows
                root.changed()
            }
        }
    }

    Process {
        id: flatsealCheckProc
        command: ["flatpak", "info", "com.github.tchx84.Flatseal"]
        onExited: exitCode => root.flatsealInstalled = exitCode === 0
    }

    Process {
        id: permissionProc
        command: ["flatpak", "permissions", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                const values = {}
                try {
                    for (const entry of JSON.parse(text || "[]")) {
                        if (entry.table !== "notifications" || entry.object !== "notification") continue
                        values[entry.app] = String(entry.permissions).split(",").includes("yes")
                    }
                } catch (error) {
                    console.warn("Could not parse Flatpak permissions:", error)
                }
                root.permissions = values
                root.changed()
            }
        }
    }

    function refresh() {
        flatpakProc.running = false
        flatpakProc.running = true
        permissionProc.running = false
        permissionProc.running = true
        flatsealCheckProc.running = false
        flatsealCheckProc.running = true
    }

    function notificationPermission(appId) {
        return root.permissions[appId] ?? true
    }

    function setNotificationPermission(appId, allowed) {
        Quickshell.execDetached(["flatpak", "permission-set", "notifications", "notification", appId, allowed ? "yes" : "no"])
        const values = Object.assign({}, root.permissions)
        values[appId] = allowed
        root.permissions = values
        root.changed()
    }

    function openPermissions(appId) {
        Quickshell.execDetached(["flatpak", "run", "com.github.tchx84.Flatseal", appId])
    }

    function open(app) {
        const entry = DesktopEntries.byId(app.id)
        if (entry) entry.execute()
        else if (app.source === "flatpak") Quickshell.execDetached(["flatpak", "run", app.id])
    }

    function uninstall(app) {
        if (app.source === "flatpak") {
            Quickshell.execDetached(["flatpak", "uninstall", "--delete-data", app.id])
            return
        }
        packageOwnerProc.appId = app.id
        packageOwnerProc.exec(["bash", "-c", "pacman -Qqo /usr/share/applications/" + "$1" + ".desktop 2>/dev/null || pacman -Qqo /usr/local/share/applications/" + "$1" + ".desktop 2>/dev/null", "app-owner", app.id])
    }

    Component.onCompleted: refresh()
}
