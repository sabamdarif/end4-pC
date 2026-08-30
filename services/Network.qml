pragma Singleton
pragma ComponentBehavior: Bound

// Took many bits from https://github.com/caelestia-dots/shell (GPLv3)

import Quickshell
import Quickshell.Io
import QtQuick
import qs.services.network

/**
 * Network service with nmcli.
 */
Singleton {
    id: root

    property bool wifi: true
    property bool ethernet: false

    property bool wifiEnabled: false
    property bool wifiScanning: false
    property bool wifiConnecting: connectProc.running
    property WifiAccessPoint wifiConnectTarget
    readonly property list<WifiAccessPoint> wifiNetworks: []
    readonly property WifiAccessPoint active: wifiNetworks.find(n => n.active) ?? null
    readonly property list<var> friendlyWifiNetworks: [...wifiNetworks].sort((a, b) => {
        if (a.active && !b.active)
            return -1;
        if (!a.active && b.active)
            return 1;
        return b.strength - a.strength;
    })
    property string wifiStatus: "disconnected"
    // Saved wifi profiles as {name, uuid, timestamp}
    property list<var> savedWifiProfiles: []

    property string networkName: ""
    property int networkStrength
    property string networkInterface: ""
    property string ipAddress: ""
    property string publicIpAddress: ""
    property string gateway: ""
    property string macAddress: ""
    property string materialSymbol: root.ethernet
        ? "lan"
        : (root.wifiEnabled && root.wifiStatus === "connected")
            ? (
                (root.active?.strength ?? 0) > 83 ? "signal_wifi_4_bar" :
                (root.active?.strength ?? 0) > 67 ? "network_wifi" :
                (root.active?.strength ?? 0) > 50 ? "network_wifi_3_bar" :
                (root.active?.strength ?? 0) > 33 ? "network_wifi_2_bar" :
                (root.active?.strength ?? 0) > 17 ? "network_wifi_1_bar" :
                "signal_wifi_0_bar"
            )
            : (root.wifiStatus === "connecting")
                ? "signal_wifi_statusbar_not_connected"
                : (root.wifiStatus === "disconnected")
                    ? "wifi_find"
                    : (root.wifiStatus === "disabled")
                        ? "signal_wifi_off"
                        : "signal_wifi_bad"

    // Control
    function enableWifi(enabled = true): void {
        const cmd = enabled ? "on" : "off";
        enableWifiProc.exec(["nmcli", "radio", "wifi", cmd]);
    }

    function toggleWifi(): void {
        enableWifi(!wifiEnabled);
    }

    function rescanWifi(): void {
        wifiScanning = true;
        rescanProcess.running = true;
    }

    // NetworkManager names a profile after the SSID it was created for and
    // suffixes duplicates ("MyWifi 1"), so several profiles can belong to one
    // network.
    function profileNameMatchesSsid(name, ssid): bool {
        if (name === ssid)
            return true;
        if (!name.startsWith(`${ssid} `))
            return false;
        return /^[0-9]+$/.test(name.slice(ssid.length + 1));
    }

    // Of those, take the one activated most recently: an older duplicate can
    // describe the network as it no longer is (open while the AP now wants a
    // password), and bringing that one up only fails with "network could not be
    // found" once NetworkManager's 90s activation timeout runs out.
    function savedWifiProfileFor(ssid) {
        const candidates = root.savedWifiProfiles.filter(p => root.profileNameMatchesSsid(p.name, ssid));
        if (candidates.length === 0)
            return null;
        return candidates.reduce((best, p) => p.timestamp > best.timestamp ? p : best);
    }

    // nmcli runs without a secret agent, so NetworkManager can never ask anyone
    // for a missing password: a secured network without a profile has to be
    // joined with a password we collect ourselves.
    function connectToWifiNetwork(accessPoint: WifiAccessPoint): void {
        if (!accessPoint)
            return;
        const saved = root.savedWifiProfileFor(accessPoint.ssid);
        if (accessPoint.isSecure && !saved) {
            accessPoint.passwordError = "";
            accessPoint.askingPassword = true;
            return;
        }
        accessPoint.askingPassword = false;
        accessPoint.passwordError = "";
        root.runConnect(accessPoint, "", saved
            ? 'nmcli connection up uuid "$UUID"'
            // Also creates a connection profile, unlike `nmcli connection up`
            : 'nmcli device wifi connect "$SSID"');
    }

    // Joins with `password`, written into the saved profile when there is one so
    // that nmcli does not add a duplicate ("SSID 1") next to it.
    function connectWithPassword(accessPoint: WifiAccessPoint, password: string): void {
        if (!accessPoint || password.length === 0)
            return;
        accessPoint.askingPassword = false;
        accessPoint.passwordError = "";
        root.runConnect(accessPoint, password, root.savedWifiProfileFor(accessPoint.ssid)
            ? 'nmcli connection modify uuid "$UUID" wifi-sec.psk "$PASSWORD" && nmcli connection up uuid "$UUID"'
            : 'nmcli device wifi connect "$SSID" password "$PASSWORD"');
    }

    // The password travels in the environment, never in argv, where `ps` would
    // show it to every user on the machine.
    function runConnect(accessPoint: WifiAccessPoint, password: string, script: string): void {
        root.wifiConnectTarget = accessPoint;
        connectProc.lastError = "";
        connectProc.exec({
            "environment": {
                "LANG": "C",
                "LC_ALL": "C",
                "SSID": accessPoint.ssid,
                "UUID": root.savedWifiProfileFor(accessPoint.ssid)?.uuid ?? "",
                "PASSWORD": password
            },
            "command": ["bash", "-c", script]
        });
    }

    function disconnectWifiNetwork(): void {
        // Taking the profile down by SSID fails whenever the profile name is not
        // the SSID (NetworkManager suffixes duplicates, e.g. "MyWifi 1"), and a
        // manual disconnect should also block autoconnect until the user picks a
        // network again, so disconnect the wifi device itself.
        disconnectProc.exec(["bash", "-c", "dev=$(nmcli -g DEVICE,TYPE,STATE device status | awk -F: '$2 == \"wifi\" && $3 ~ /^connected/ { print $1; exit }'); [ -n \"$dev\" ] && nmcli device disconnect \"$dev\""]);
    }

    function openPublicWifiPortal() {
        Quickshell.execDetached(["xdg-open", "https://nmcheck.gnome.org/"]) // From some StackExchange thread, seems to work
    }

    Process {
        id: enableWifiProc
    }

    Process {
        id: connectProc
        property string lastError: ""
        stdout: SplitParser {
            onRead: getNetworks.running = true
        }
        stderr: StdioCollector {
            onStreamFinished: connectProc.lastError = text.trim()
        }
        onExited: (exitCode, exitStatus) => {
            const target = root.wifiConnectTarget;
            root.wifiConnectTarget = null;
            getNetworks.running = true;
            getSavedNetworks.running = true;
            if (!target || exitCode === 0) {
                if (target) {
                    target.askingPassword = false;
                    target.passwordError = "";
                }
                return;
            }
            // Only a secured network has something left to ask the user for
            if (!target.isSecure)
                return;
            target.askingPassword = true;
            target.passwordError = /secret|password|not provided/i.test(connectProc.lastError)
                ? Translation.tr("Wrong password")
                : (connectProc.lastError !== "" ? connectProc.lastError : Translation.tr("Could not connect"));
        }
    }

    Process {
        id: disconnectProc
        stdout: SplitParser {
            onRead: getNetworks.running = true
        }
    }

    Process {
        id: getSavedNetworks
        running: true
        command: ["nmcli", "-t", "-f", "NAME,UUID,TYPE,TIMESTAMP", "connection", "show"]
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            onStreamFinished: {
                // Only NAME can hold a ':', which nmcli -t escapes as '\:'
                const PLACEHOLDER = "STRINGWHICHHOPEFULLYWONTBEUSED";
                const unescape = new RegExp(PLACEHOLDER, "g");
                const profiles = [];
                for (const line of text.trim().split("\n")) {
                    const parts = line.replace(/\\:/g, PLACEHOLDER).split(":");
                    if (parts[2] !== "802-11-wireless" || !parts[0])
                        continue;
                    profiles.push({
                        name: parts[0].replace(unescape, ":"),
                        uuid: parts[1],
                        // Seconds since the epoch of the last successful activation, 0 if never
                        timestamp: parseInt(parts[3]) || 0
                    });
                }
                root.savedWifiProfiles = profiles;
            }
        }
    }

    Process {
        id: rescanProcess
        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        stdout: SplitParser {
            onRead: {
                wifiScanning = false;
                getNetworks.running = true;
            }
        }
    }

    // Status update
    function update() {
        updateConnectionType.startCheck();
        wifiStatusProcess.running = true
        getSavedNetworks.running = true;
        updateNetworkName.running = true;
        updateNetworkStrength.running = true;
        updateNetworkDetails.running = true;
        updatePublicIp.running = true;
    }

    Process {
        id: subscriber
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: root.update()
        }
    }

    Process {
        id: updateConnectionType
        property string buffer
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE d status && nmcli -t -f CONNECTIVITY g"]
        running: true
        function startCheck() {
            buffer = "";
            updateConnectionType.running = true;
        }
        stdout: SplitParser {
            onRead: data => {
                updateConnectionType.buffer += data + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            const lines = updateConnectionType.buffer.trim().split('\n');
            const connectivity = lines.pop() // none, limited, full
            let hasEthernet = false;
            let hasWifi = false;
            let wifiStatus = "disconnected";
            lines.forEach(line => {
                if (line.includes("ethernet") && line.includes("connected"))
                    hasEthernet = true;
                else if (line.includes("wifi:")) {
                    if (line.includes("disconnected")) {
                        wifiStatus = "disconnected"
                    }
                    else if (line.includes("connected")) {
                        hasWifi = true;
                        wifiStatus = "connected"

                        if (connectivity === "limited") {
                            hasWifi = false;
                            wifiStatus = "limited"
                        }
                    }
                    else if (line.includes("connecting")) {
                        wifiStatus = "connecting"
                    }
                    else if (line.includes("unavailable")) {
                        wifiStatus = "disabled"
                    }
                }
            });
            root.wifiStatus = wifiStatus;
            root.ethernet = hasEthernet;
            root.wifi = hasWifi;
        }
    }

    Process {
        id: updateNetworkName
        command: ["sh", "-c", "nmcli -t -f NAME c show --active | head -1"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                root.networkName = data;
            }
        }
    }

    Process {
        id: updateNetworkStrength
        running: true
        command: ["sh", "-c", "nmcli -f IN-USE,SIGNAL,SSID device wifi | awk '/^\\*/{if (NR!=1) {print $2}}'"]
        stdout: SplitParser {
            onRead: data => {
                root.networkStrength = parseInt(data);
            }
        }
    }

    Process {
        id: updateNetworkDetails
        running: true
        command: ["sh", "-c", "device=$(nmcli -t -f DEVICE,TYPE,STATE device status | awk -F: '$3 == \"connected\" && $2 ~ /^(wifi|ethernet)$/ { print $1; exit }'); if [ -n \"$device\" ]; then nmcli -t -f GENERAL.DEVICE,GENERAL.HWADDR,IP4.ADDRESS,IP4.GATEWAY device show \"$device\"; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                let networkInterface = "";
                let ipAddress = "";
                let gateway = "";
                let macAddress = "";

                for (const line of text.trim().split("\n")) {
                    const separator = line.indexOf(":");
                    if (separator < 0) continue;

                    const key = line.slice(0, separator);
                    const value = line.slice(separator + 1);
                    if (key === "GENERAL.DEVICE")
                        networkInterface = value;
                    else if (key === "GENERAL.HWADDR")
                        macAddress = value;
                    else if (key.startsWith("IP4.ADDRESS") && ipAddress === "")
                        ipAddress = value.split("/")[0];
                    else if (key === "IP4.GATEWAY")
                        gateway = value;
                }

                root.networkInterface = networkInterface;
                root.ipAddress = ipAddress;
                root.gateway = gateway;
                root.macAddress = macAddress;
            }
        }
    }

    Process {
        id: updatePublicIp
        running: true
        command: ["curl", "-fsS", "--max-time", "5", "https://api.ipify.org"]
        stdout: StdioCollector {
            onStreamFinished: {
                const candidate = text.trim();
                root.publicIpAddress = /^[0-9a-fA-F:.]+$/.test(candidate)
                    ? candidate
                    : "";
            }
        }
    }

    Process {
        id: wifiStatusProcess
        command: ["nmcli", "radio", "wifi"]
        Component.onCompleted: running = true
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled";
            }
        }
    }

    Process {
        id: getNetworks
        running: true
        command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "w"]
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            onStreamFinished: {
                const PLACEHOLDER = "STRINGWHICHHOPEFULLYWONTBEUSED";
                const rep = new RegExp("\\\\:", "g");
                const rep2 = new RegExp(PLACEHOLDER, "g");

                const allNetworks = text.trim().split("\n").map(n => {
                    const net = n.replace(rep, PLACEHOLDER).split(":");
                    return {
                        active: net[0] === "yes",
                        strength: parseInt(net[1]),
                        frequency: parseInt(net[2]),
                        ssid: net[3],
                        bssid: net[4]?.replace(rep2, ":") ?? "",
                        security: net[5] || ""
                    };
                }).filter(n => n.ssid && n.ssid.length > 0);

                // Group networks by SSID and prioritize connected ones
                const networkMap = new Map();
                for (const network of allNetworks) {
                    const existing = networkMap.get(network.ssid);
                    if (!existing) {
                        networkMap.set(network.ssid, network);
                    } else {
                        // Prioritize active/connected networks
                        if (network.active && !existing.active) {
                            networkMap.set(network.ssid, network);
                        } else if (!network.active && !existing.active) {
                            // If both are inactive, keep the one with better signal
                            if (network.strength > existing.strength) {
                                networkMap.set(network.ssid, network);
                            }
                        }
                        // If existing is active and new is not, keep existing
                    }
                }

                const wifiNetworks = Array.from(networkMap.values());

                const rNetworks = root.wifiNetworks;

                const destroyed = rNetworks.filter(rn => !wifiNetworks.find(n => n.frequency === rn.frequency && n.ssid === rn.ssid && n.bssid === rn.bssid));
                for (const network of destroyed)
                    rNetworks.splice(rNetworks.indexOf(network), 1).forEach(n => n.destroy());

                for (const network of wifiNetworks) {
                    const match = rNetworks.find(n => n.frequency === network.frequency && n.ssid === network.ssid && n.bssid === network.bssid);
                    if (match) {
                        match.lastIpcObject = network;
                    } else {
                        rNetworks.push(apComp.createObject(root, {
                            lastIpcObject: network
                        }));
                    }
                }
            }
        }
    }

    Component {
        id: apComp

        WifiAccessPoint {}
    }
}
