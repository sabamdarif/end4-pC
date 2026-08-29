pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

/**
 * One NetworkManager connection profile, for the Wi-Fi settings profile editor.
 *
 * `props` holds the profile settings of the connection last passed to load(),
 * keyed by nmcli's `setting.property` names. Unlike nmcli's list output,
 * `connection show <id>` does not escape ':' inside values, so lines split on
 * their first ':' only. The uppercase GENERAL./IP4./DHCP4. keys trailing the
 * profile settings describe the *active* connection, not the profile, and are
 * dropped.
 */
Singleton {
    id: root

    property string uuid: ""
    property bool ready: false
    property bool applying: false
    property var props: ({})
    property string lastError: ""

    signal applied(bool ok)

    function load(connectionUuid) {
        root.uuid = connectionUuid;
        root.ready = false;
        root.lastError = "";
        root.props = ({});
        loadProc.exec(["nmcli", "--show-secrets", "-t", "connection", "show", "uuid", connectionUuid]);
    }

    // Secrets nmcli may not hand out read back as "<hidden>"; treat those as unset
    // so an untouched field never writes the placeholder back into the profile.
    function get(key, fallback = "") {
        const value = root.props[key];
        return (value === undefined || value === "<hidden>") ? fallback : value;
    }

    /**
     * `changes` maps nmcli properties to their new values. `resetSecurity` drops
     * the whole 802-11-wireless-security setting first, which is the only way to
     * clear a stale PSK (nmcli silently ignores an empty one). `reactivate`
     * re-ups the connection so a live one picks the changes up.
     */
    function applyChanges(changes, resetSecurity, reactivate) {
        if (root.applying || root.uuid === "") return;

        // argv, never a shell string: every value here is user input
        let args = ["nmcli", "connection", "modify", "uuid", root.uuid];
        if (resetSecurity)
            args.push("remove", "802-11-wireless-security");
        for (const key in changes)
            args.push(key, String(changes[key]));

        let pending = [];
        if (args.length > 5)
            pending.push(args);
        if (reactivate)
            pending.push(["nmcli", "connection", "up", "uuid", root.uuid]);

        root.lastError = "";
        if (pending.length === 0) {
            root.applied(true);
            return;
        }
        root.queue = pending;
        root.applying = true;
        root.runNext();
    }

    property var queue: []

    function runNext() {
        if (root.queue.length === 0) {
            root.applying = false;
            root.applied(root.lastError === "");
            return;
        }
        actionProc.exec(root.queue.shift());
    }

    Process {
        id: actionProc
        environment: ({ LANG: "C", LC_ALL: "C" })
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") root.lastError = text.trim()
        }
        onExited: exitCode => {
            if (exitCode !== 0) {
                if (root.lastError === "")
                    root.lastError = Translation.tr("nmcli exited with code %1").arg(exitCode);
                root.queue = [];
            }
            root.runNext();
        }
    }

    Process {
        id: loadProc
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                let parsed = ({});
                for (const line of text.split("\n")) {
                    const separator = line.indexOf(":");
                    if (separator < 0) continue;
                    const key = line.slice(0, separator);
                    if (!/^[a-z0-9-]+\.[a-z0-9-]+$/.test(key)) continue;
                    parsed[key] = line.slice(separator + 1);
                }
                root.props = parsed;
                root.ready = Object.keys(parsed).length > 0;
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") root.lastError = text.trim()
        }
    }
}
