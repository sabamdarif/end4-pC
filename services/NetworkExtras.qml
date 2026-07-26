pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * nmcli Process wrappers for the Network settings page.
 *
 * Covers everything services/Network.qml (wifi state/connect, also nmcli)
 * doesn't: the NM connection list (known networks, autoconnect), wifi
 * forget, ethernet device details (IPs), VPN up/down/import/delete, DNS
 * read/modify (mechanism ported 1:1 from the rofi dns-changer-menu script:
 * `nmcli connection modify` + `connection up`), and a minimal Blocky
 * status (only if /etc/blocky/config.yml exists).
 *
 * All values with colons come from `nmcli -t`, which escapes ':' in values
 * as '\:' — parsing below always unescapes.
 */
Singleton {
    id: root

    // ── Connection list ──────────────────────────────────────────────────
    // Each entry: {name, type, active, autoconnect, device}
    property list<var> connections: []
    readonly property list<var> vpnConnections: connections.filter(c => c.type === "vpn" || c.type === "wireguard")
    readonly property list<var> dnsCapableConnections: connections.filter(c => c.type === "802-11-wireless" || c.type === "802-3-ethernet")
    readonly property string activeConnectionName: connections.find(c => c.active && (c.type === "802-11-wireless" || c.type === "802-3-ethernet"))?.name ?? ""

    function isKnownWifi(ssid) {
        return connections.some(c => c.type === "802-11-wireless" && c.name === ssid);
    }

    function autoconnectFor(name) {
        return connections.find(c => c.name === name)?.autoconnect ?? false;
    }

    // ── Ethernet devices ─────────────────────────────────────────────────
    // Each entry: {iface, state, mac, ip4, ip6, connection}
    property list<var> ethernetDevices: []

    // ── Blocky ───────────────────────────────────────────────────────────
    property bool blockyPresent: false
    property bool blockyActive: false

    // ── Action feedback (import errors etc.) ─────────────────────────────
    property string lastActionOutput: ""

    // ── DNS presets — ported verbatim from ~/.config/rofi/bin/dns-changer-menu
    // {name, ipv4, ipv6, dot} — ipv4/ipv6 comma-separated, dot = DoT hostname
    // ("" = provider has no DoT endpoint, so the DoT toggle can't apply to it)
    readonly property list<var> dnsPresets: [
        { name: "Cloudflare",           ipv4: "1.1.1.1,1.0.0.1",                 ipv6: "2606:4700:4700::1111,2606:4700:4700::1001", dot: "cloudflare-dns.com" },
        { name: "Google",               ipv4: "8.8.8.8,8.8.4.4",                 ipv6: "2001:4860:4860::8888,2001:4860:4860::8844", dot: "dns.google" },
        { name: "Quad9",                ipv4: "9.9.9.9,149.112.112.112",         ipv6: "2620:fe::fe,2620:fe::9",                    dot: "dns.quad9.net" },
        { name: "Quad9 (unfiltered)",   ipv4: "9.9.9.10,149.112.112.10",         ipv6: "2620:fe::10,2620:fe::fe:10",                dot: "dns10.quad9.net" },
        { name: "OpenDNS",              ipv4: "208.67.222.222,208.67.220.220",   ipv6: "2620:119:35::35,2620:119:53::53",           dot: "dns.opendns.com" },
        { name: "AdGuard",              ipv4: "94.140.14.14,94.140.15.15",       ipv6: "2a10:50c0::ad1:ff,2a10:50c0::ad2:ff",       dot: "dns.adguard-dns.com" },
        { name: "AdGuard (unfiltered)", ipv4: "94.140.14.140,94.140.14.141",     ipv6: "2a10:50c0::1:ff,2a10:50c0::2:ff",           dot: "dns-unfiltered.adguard.com" },
        { name: "Mullvad",              ipv4: "194.242.2.2",                     ipv6: "2a07:e340::2",                              dot: "dns.mullvad.net" },
        { name: "Mullvad (ad-block)",   ipv4: "194.242.2.3",                     ipv6: "2a07:e340::3",                              dot: "adblock.dns.mullvad.net" },
        { name: "NextDNS",              ipv4: "45.90.28.0,45.90.30.0",           ipv6: "2a07:a8c0::,2a07:a8c1::",                   dot: "" },
        { name: "Control D",            ipv4: "76.76.2.0,76.76.10.0",            ipv6: "2606:1a40::,2606:1a40:1::",                 dot: "" },
        { name: "DNS.SB",               ipv4: "185.222.222.222,45.11.45.11",     ipv6: "2a09::,2a11::",                             dot: "" }
    ]

    // ── DNS state of the connection last passed to readDns() ─────────────
    property string dnsConnection: ""
    property string currentDnsV4: ""
    property string currentDnsV6: ""
    property bool currentDotEnabled: false
    property bool currentIgnoreAutoDns: false

    // Which preset (if any) matches the current DNS — same match rule as the
    // rofi script's current_server_label (exact ipv4 OR ipv6 list match)
    readonly property string currentPresetName: {
        for (const p of dnsPresets) {
            if ((currentDnsV4 !== "" && currentDnsV4 === p.ipv4)
                || (currentDnsV6 !== "" && currentDnsV6 === p.ipv6))
                return p.name;
        }
        return "";
    }

    function refresh() {
        listProc.running = true;
    }

    function readDns(conn) {
        if (!conn || conn.length === 0) return;
        root.dnsConnection = conn;
        dnsReadProc.exec({
            "environment": { "CONN": conn },
            "command": ["bash", "-c",
                'echo :::V4\n'
                + 'nmcli -g ipv4.dns connection show "$CONN" 2>/dev/null | tr " " ","\n'
                + 'echo :::V6\n'
                + 'nmcli -g ipv6.dns connection show "$CONN" 2>/dev/null | tr " " ","\n'
                + 'echo :::DOT\n'
                + 'nmcli -g connection.dns-over-tls connection show "$CONN" 2>/dev/null\n'
                + 'echo :::AUTO\n'
                + 'nmcli -g ipv4.ignore-auto-dns connection show "$CONN" 2>/dev/null\n']
        });
    }

    // ── Wifi extras ──────────────────────────────────────────────────────
    function forgetWifi(ssid) {
        runAction({ "SSID": ssid }, 'nmcli connection delete id "$SSID"');
    }

    function setAutoconnect(name, on) {
        runAction({ "NAME": name, "VAL": on ? "yes" : "no" }, 'nmcli connection modify "$NAME" connection.autoconnect "$VAL"');
    }

    // ── VPN ──────────────────────────────────────────────────────────────
    function vpnUp(name) {
        runAction({ "NAME": name }, 'nmcli connection up "$NAME"');
    }

    function vpnDown(name) {
        runAction({ "NAME": name }, 'nmcli connection down "$NAME"');
    }

    function vpnDelete(name) {
        runAction({ "NAME": name }, 'nmcli connection delete id "$NAME"');
    }

    // .ovpn -> openvpn, .conf/.wg -> wireguard (same rule as `nmcli c import`)
    function vpnImport(path) {
        const p = path.trim();
        if (p === "") return;
        const type = p.toLowerCase().endsWith(".ovpn") ? "openvpn" : "wireguard";
        runAction({ "FILE": p, "TYPE": type }, 'nmcli connection import type "$TYPE" file "$FILE"');
    }

    // ── DNS actions — mechanism identical to the rofi script ─────────────
    // apply_plain/apply_dot: ignore-auto-dns yes, set dns lists,
    // dns-over-tls 3 (DoT, the script's value) or 0, then re-up.
    function applyDns(conn, ipv4, ipv6, dot) {
        runAction({
            "CONN": conn,
            "V4": ipv4 ?? "",
            "V6": ipv6 ?? "",
            "DOT": dot ? "3" : "0"
        },
            'v4=$(echo "$V4" | tr "," " ")\n'
            + 'v6=$(echo "$V6" | tr "," " ")\n'
            + 'nmcli connection modify "$CONN" ipv4.ignore-auto-dns yes 2>/dev/null || true\n'
            + 'nmcli connection modify "$CONN" ipv6.ignore-auto-dns yes 2>/dev/null || true\n'
            + 'nmcli connection modify "$CONN" ipv4.dns "$v4" 2>/dev/null || true\n'
            + 'nmcli connection modify "$CONN" ipv6.dns "$v6" 2>/dev/null || true\n'
            + 'nmcli connection modify "$CONN" connection.dns-over-tls "$DOT" 2>/dev/null || true\n'
            + 'nmcli connection up "$CONN" >/dev/null 2>&1 || true\n');
    }

    // reset_dns: clear dns, ignore-auto-dns no, DoT off, re-up (back to DHCP)
    function resetDns(conn) {
        runAction({ "CONN": conn },
            'nmcli connection modify "$CONN" ipv4.dns "" 2>/dev/null || true\n'
            + 'nmcli connection modify "$CONN" ipv6.dns "" 2>/dev/null || true\n'
            + 'nmcli connection modify "$CONN" ipv4.ignore-auto-dns no 2>/dev/null || true\n'
            + 'nmcli connection modify "$CONN" ipv6.ignore-auto-dns no 2>/dev/null || true\n'
            + 'nmcli connection modify "$CONN" connection.dns-over-tls 0 2>/dev/null || true\n'
            + 'nmcli connection up "$CONN" >/dev/null 2>&1 || true\n');
    }

    function setDot(conn, on) {
        runAction({ "CONN": conn, "DOT": on ? "3" : "0" },
            'nmcli connection modify "$CONN" connection.dns-over-tls "$DOT" 2>/dev/null || true\n'
            + 'nmcli connection up "$CONN" >/dev/null 2>&1 || true\n');
    }

    // ── Blocky (pkexec prompts through the polkit agent) ─────────────────
    function blockySetActive(on) {
        Quickshell.execDetached(["pkexec", "systemctl", on ? "start" : "stop", "blocky.service"]);
        blockyRecheckTimer.restart();
    }

    // ── Plumbing ─────────────────────────────────────────────────────────
    function runAction(env, script) {
        actionProc.exec({
            "environment": env,
            "command": ["bash", "-c", script]
        });
    }

    Process {
        id: actionProc
        environment: ({ LANG: "C", LC_ALL: "C" })
        property string collected: ""
        stdout: StdioCollector {
            onStreamFinished: actionProc.collected += text
        }
        stderr: StdioCollector {
            onStreamFinished: actionProc.collected += text
        }
        onExited: (exitCode, exitStatus) => {
            root.lastActionOutput = actionProc.collected.trim();
            actionProc.collected = "";
            root.refresh();
            if (root.dnsConnection !== "") root.readDns(root.dnsConnection);
        }
    }

    Timer {
        id: blockyRecheckTimer
        interval: 3000
        onTriggered: root.refresh()
    }

    Process {
        id: dnsReadProc
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                const data = { V4: [], V6: [], DOT: [], AUTO: [] };
                let bucket = "";
                for (const rawLine of text.split("\n")) {
                    const line = rawLine.trim();
                    if (line.startsWith(":::")) {
                        bucket = line.slice(3);
                        continue;
                    }
                    if (bucket && bucket in data && line !== "") data[bucket].push(line);
                }
                const clean = s => (s ?? "").replace(/,+$/, "").replace(/^,+/, "");
                root.currentDnsV4 = clean(data.V4.join(","));
                root.currentDnsV6 = clean(data.V6.join(","));
                const dot = data.DOT[0] ?? "";
                root.currentDotEnabled = (dot === "3" || dot === "yes" || dot === "2");
                root.currentIgnoreAutoDns = (data.AUTO[0] ?? "") === "yes";
            }
        }
    }

    Process {
        id: listProc
        running: true
        environment: ({ LANG: "C", LC_ALL: "C" })
        command: ["bash", "-c",
            'echo :::CONNECTIONS\n'
            + 'nmcli -t -f NAME,TYPE,ACTIVE,AUTOCONNECT,DEVICE connection show 2>/dev/null\n'
            + 'echo :::ETHERNET\n'
            + 'nmcli -t -f GENERAL.DEVICE,GENERAL.TYPE,GENERAL.STATE,GENERAL.HWADDR,GENERAL.CONNECTION,IP4.ADDRESS,IP6.ADDRESS device show 2>/dev/null\n'
            + 'echo :::BLOCKY\n'
            + '[ -f /etc/blocky/config.yml ] && echo present || echo absent\n'
            + 'systemctl is-active blocky.service 2>/dev/null || true\n']
        stdout: StdioCollector {
            onStreamFinished: {
                const sections = { CONNECTIONS: [], ETHERNET: [], BLOCKY: [] };
                let bucket = "";
                for (const line of text.split("\n")) {
                    if (line.startsWith(":::")) {
                        bucket = line.slice(3).trim();
                        continue;
                    }
                    if (bucket && bucket in sections) sections[bucket].push(line);
                }

                // Connections: NAME:TYPE:ACTIVE:AUTOCONNECT:DEVICE, ':' in values escaped as '\:'
                const PLACEHOLDER = "STRINGWHICHHOPEFULLYWONTBEUSED";
                const conns = [];
                for (const line of sections.CONNECTIONS) {
                    if (line.trim() === "") continue;
                    const parts = line.replace(/\\:/g, PLACEHOLDER).split(":").map(p => p.replace(new RegExp(PLACEHOLDER, "g"), ":"));
                    if (parts.length < 4) continue;
                    conns.push({
                        name: parts[0],
                        type: parts[1],
                        active: parts[2] === "yes",
                        autoconnect: parts[3] === "yes",
                        device: parts[4] ?? ""
                    });
                }
                root.connections = conns;

                // Ethernet: FIELD:value blocks, one device per GENERAL.DEVICE
                const devices = [];
                let cur = null;
                for (const line of sections.ETHERNET) {
                    const i = line.indexOf(":");
                    if (i < 0) continue;
                    const key = line.slice(0, i);
                    const val = line.slice(i + 1).replace(/\\:/g, ":");
                    if (key === "GENERAL.DEVICE") {
                        cur = { iface: val, type: "", state: "", mac: "", connection: "", ip4: [], ip6: [] };
                        devices.push(cur);
                    } else if (!cur) {
                        continue;
                    } else if (key === "GENERAL.TYPE") {
                        cur.type = val;
                    } else if (key === "GENERAL.STATE") {
                        // "100 (connected)" -> "connected",
                        // "100 (connected (externally))" -> "connected (externally)"
                        const m = val.match(/^\d+\s*\((.*)\)$/);
                        cur.state = m ? m[1] : val;
                    } else if (key === "GENERAL.HWADDR") {
                        cur.mac = val;
                    } else if (key === "GENERAL.CONNECTION") {
                        cur.connection = val === "--" ? "" : val;
                    } else if (key.startsWith("IP4.ADDRESS")) {
                        cur.ip4.push(val);
                    } else if (key.startsWith("IP6.ADDRESS")) {
                        cur.ip6.push(val);
                    }
                }
                root.ethernetDevices = devices.filter(d => d.type === "ethernet");

                // Blocky
                root.blockyPresent = sections.BLOCKY.some(l => l.trim() === "present");
                root.blockyActive = sections.BLOCKY.some(l => l.trim() === "active");
            }
        }
    }
}
