pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

/**
 * User accounts for the (hidden) Profile settings page.
 *
 * Listing: `getent passwd` filtered to 1000 <= uid < 65000 (real users,
 * excludes nobody). Admin = member of the wheel group (`id -nG` — this
 * is Arch/CachyOS, wheel is the admin group).
 *
 * Mutations (create/delete/admin toggle) go through pkexec — the polkit
 * agent shows a system authentication prompt. Every one of them is only
 * ever invoked from behind an explicit confirm dialog in the UI, and the
 * service enforces its own guard rails on top:
 *  - usernames are validated against ^[a-z_][a-z0-9_-]*$ before any
 *    command is built (commands are argv arrays, never shell strings)
 *  - deleting or de-admining the currently logged-in user is refused
 */
Singleton {
    id: root

    // wheel is the admin group on Arch/CachyOS
    readonly property string adminGroup: "wheel"

    property string currentUsername: ""
    // {username, uid, fullName, home, shell, isCurrent, isAdmin}
    property list<var> users: []
    property bool actionRunning: false
    property string lastActionOutput: ""

    function isValidUsername(name) {
        return /^[a-z_][a-z0-9_-]*$/.test(name)
    }

    function userExists(name) {
        return users.some(u => u.username === name)
    }

    function refresh() {
        listProc.running = true
    }

    // ── pkexec actions (UI must confirm first — see header) ──────────────

    function createUser(username, admin) {
        if (!isValidUsername(username)) {
            root.lastActionOutput = Translation.tr("Invalid username: %1").arg(username)
            return false
        }
        if (userExists(username)) {
            root.lastActionOutput = Translation.tr("User %1 already exists").arg(username)
            return false
        }
        let cmd = ["pkexec", "useradd", "-m"]
        if (admin) cmd = cmd.concat(["-G", root.adminGroup])
        cmd.push(username)
        runAction(cmd)
        return true
    }

    function deleteUser(username, removeHome) {
        if (!isValidUsername(username)) {
            root.lastActionOutput = Translation.tr("Invalid username: %1").arg(username)
            return false
        }
        if (username === root.currentUsername) {
            root.lastActionOutput = Translation.tr("Refusing to delete the currently logged-in user")
            return false
        }
        let cmd = ["pkexec", "userdel"]
        if (removeHome) cmd.push("--remove")
        cmd.push(username)
        runAction(cmd)
        return true
    }

    function setAdmin(username, on) {
        if (!isValidUsername(username)) {
            root.lastActionOutput = Translation.tr("Invalid username: %1").arg(username)
            return false
        }
        if (!on && username === root.currentUsername) {
            root.lastActionOutput = Translation.tr("Refusing to remove admin rights from the currently logged-in user")
            return false
        }
        runAction(["pkexec", "gpasswd", on ? "-a" : "-d", username, root.adminGroup])
        return true
    }

    // ── Plumbing ─────────────────────────────────────────────────────────

    function runAction(cmd) {
        root.lastActionOutput = ""
        root.actionRunning = true
        actionProc.exec({ "command": cmd })
    }

    Process {
        id: actionProc
        property string collected: ""
        stdout: StdioCollector {
            onStreamFinished: actionProc.collected += text
        }
        stderr: StdioCollector {
            onStreamFinished: actionProc.collected += text
        }
        onExited: (exitCode, exitStatus) => {
            root.actionRunning = false
            const out = actionProc.collected.trim()
            actionProc.collected = ""
            if (exitCode === 126 || exitCode === 127) {
                // polkit: dismissed / not authorized
                root.lastActionOutput = Translation.tr("Authentication cancelled or denied")
            } else if (exitCode !== 0) {
                root.lastActionOutput = out !== "" ? out : Translation.tr("Command failed (exit code %1)").arg(exitCode)
            } else {
                root.lastActionOutput = out
            }
            root.refresh()
        }
    }

    Process {
        id: listProc
        running: true
        environment: ({ LANG: "C", LC_ALL: "C" })
        command: ["bash", "-c",
            'echo :::ME\n'
            + 'id -un\n'
            + 'echo :::USERS\n'
            + 'getent passwd | awk -F: \'$3 >= 1000 && $3 < 65000\'\n'
            + 'echo :::ADMINS\n'
            + 'getent passwd | awk -F: \'$3 >= 1000 && $3 < 65000 {print $1}\' | while IFS= read -r u; do\n'
            + `    id -nG "$u" 2>/dev/null | tr " " "\\n" | grep -qx "${root.adminGroup}" && echo "$u"\n`
            + 'done\n'
            + 'true\n']
        stdout: StdioCollector {
            onStreamFinished: {
                const sections = { ME: [], USERS: [], ADMINS: [] }
                let bucket = ""
                for (const rawLine of text.split("\n")) {
                    const line = rawLine.trim()
                    if (line.startsWith(":::")) {
                        bucket = line.slice(3)
                        continue
                    }
                    if (bucket && bucket in sections && line !== "") sections[bucket].push(line)
                }

                const me = sections.ME[0] ?? ""
                const admins = sections.ADMINS
                const parsed = []
                for (const line of sections.USERS) {
                    // name:pw:uid:gid:gecos:home:shell
                    const parts = line.split(":")
                    if (parts.length < 7) continue
                    parsed.push({
                        username: parts[0],
                        uid: parseInt(parts[2]),
                        fullName: (parts[4] ?? "").split(",")[0],
                        home: parts[5],
                        shell: parts[6],
                        isCurrent: parts[0] === me,
                        isAdmin: admins.includes(parts[0])
                    })
                }
                parsed.sort((a, b) => a.uid - b.uid)
                root.currentUsername = me
                root.users = parsed
            }
        }
    }
}
