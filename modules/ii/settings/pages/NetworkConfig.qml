import QtQuick
import QtQuick.Layouts
import Quickshell
// Aliased: Quickshell.Networking also exports a type called `Network`, which
// would shadow the nmcli service singleton of the same name from qs.services
import Quickshell.Networking as QsNetworking
import qs.services
import qs.modules.common
import qs.modules.common.widgets

/**
 * Network page — backend choice (see plan.md "4. Network page" + risks):
 *
 * The native Quickshell.Networking module (new in 0.3) could not be
 * live smoke-tested while building this page, so it is used ONLY for
 * read-only state whose API the local docs/qmltypes confirm: the wired
 * device link speed / link state (WiredDevice.linkSpeed/hasLink, matched
 * to nmcli devices by interface name).
 *
 * Everything else stays on nmcli, the safe fallback the plan allows:
 *  - WiFi state + scan + connect/PSK: services/Network.qml — the existing,
 *    proven nmcli service that already powers the sidebar WiFi dialog.
 *    Reusing it keeps a single source of truth for wifi state shell-wide.
 *  - All mutations (forget, autoconnect, VPN up/down/import/delete, DNS
 *    modify + connection up, blocky via pkexec): services/NetworkExtras.qml
 *    nmcli Process wrappers. The DNS mechanism is ported 1:1 from
 *    ~/.config/rofi/bin/dns-changer-menu.
 */
ContentPage {
    id: page
    forceWidth: true

    property string selectedDnsConn: ""
    property string selectedDnsProvider: ""
    readonly property string dnsConn: selectedDnsConn !== "" ? selectedDnsConn : NetworkExtras.activeConnectionName
    readonly property bool customDnsProviderVisible: selectedDnsProvider === "custom"
        || (selectedDnsProvider === "" && NetworkExtras.currentPresetName === ""
            && (NetworkExtras.currentDnsV4 !== "" || NetworkExtras.currentDnsV6 !== ""))

    onDnsConnChanged: {
        selectedDnsProvider = ""
        if (dnsConn !== "" && dnsConn !== NetworkExtras.dnsConnection)
            NetworkExtras.readDns(dnsConn)
    }

    Component.onCompleted: {
        NetworkExtras.refresh()
        if (page.dnsConn !== "") NetworkExtras.readDns(page.dnsConn)
    }

    function goTo(term) {
        const t = term.toLowerCase().trim()

        function findTarget(rootItem) {
            for (let i = 0; i < rootItem.children.length; i++) {
                let child = rootItem.children[i]
                if (child.title && child.title.toLowerCase().includes(t)) {
                    return child
                }
            }
            for (let i = 0; i < rootItem.children.length; i++) {
                let found = findTarget(rootItem.children[i])
                if (found) return found
            }
            return null
        }

        let target = findTarget(mainLayout)
        if (target) {
            let pos = target.mapToItem(mainLayout, 0, 0)
            page.contentY = Math.max(0, pos.y - 0)
        }
    }

    function wifiSignalIcon(strength) {
        return strength > 80 ? "signal_wifi_4_bar"
            : strength > 60 ? "network_wifi_3_bar"
            : strength > 40 ? "network_wifi_2_bar"
            : strength > 20 ? "network_wifi_1_bar"
            : "signal_wifi_0_bar"
    }

    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        // ── Wi-Fi ────────────────────────────────────────────────────────
        ContentSection {
            icon: "wifi"
            shape: MaterialShape.Shape.Circle
            title: Translation.tr("Wi-Fi")

            GroupedList {
                ConfigSwitch {
                    id: wifiEnableSwitch
                    buttonIcon: "wifi"
                    text: Translation.tr("Enable Wi-Fi")
                    checked: Network.wifiEnabled
                    onCheckedChanged: {
                        if (checked !== Network.wifiEnabled)
                            Network.enableWifi(checked)
                    }
                    // Clicking breaks the `checked` binding — re-sync when the
                    // state changes elsewhere (sidebar toggle, nmcli, hardware)
                    Connections {
                        target: Network
                        function onWifiEnabledChanged() {
                            wifiEnableSwitch.checked = Network.wifiEnabled
                        }
                    }
                }
                RowLayout {
                    spacing: 10
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                    MaterialSymbol {
                        text: "radar"
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnSecondaryContainer
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: Network.wifiScanning
                            ? Translation.tr("Scanning for networks…")
                            : Translation.tr("%1 networks found").arg(Network.wifiNetworks.length)
                        color: Appearance.colors.colOnSecondaryContainer
                    }
                    RippleButtonWithIcon {
                        materialIcon: "refresh"
                        mainText: Translation.tr("Scan")
                        enabled: Network.wifiEnabled && !Network.wifiScanning
                        onClicked: Network.rescanWifi()
                    }
                }
            }

            // Dynamic list: NOT inside GroupedList (it reparents static
            // children only) — card + ColumnLayout + Repeater instead
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: wifiListCol.implicitHeight + 20
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1

                ColumnLayout {
                    id: wifiListCol
                    anchors { fill: parent; margins: 10 }
                    spacing: 2

                    StyledText {
                        visible: Network.friendlyWifiNetworks.length === 0
                        Layout.leftMargin: 8
                        text: Network.wifiEnabled ? Translation.tr("No networks found") : Translation.tr("Wi-Fi is disabled")
                        color: Appearance.colors.colSubtext
                    }

                    Repeater {
                        model: Network.friendlyWifiNetworks
                        delegate: ColumnLayout {
                            id: wifiRow
                            required property var modelData
                            readonly property bool known: NetworkExtras.isKnownWifi(modelData.ssid)
                            property bool confirmingForget: false
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                RippleButton {
                                    Layout.fillWidth: true
                                    implicitHeight: 44
                                    buttonRadius: Appearance.rounding.small
                                    colBackground: "transparent"
                                    onClicked: {
                                        if (wifiRow.modelData.active)
                                            Network.disconnectWifiNetwork()
                                        else
                                            Network.connectToWifiNetwork(wifiRow.modelData)
                                    }
                                    StyledToolTip {
                                        text: wifiRow.modelData.active ? Translation.tr("Click to disconnect") : Translation.tr("Click to connect")
                                    }
                                    contentItem: RowLayout {
                                        spacing: 10
                                        MaterialSymbol {
                                            text: page.wifiSignalIcon(wifiRow.modelData.strength)
                                            iconSize: Appearance.font.pixelSize.huge
                                            color: Appearance.colors.colOnSecondaryContainer
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 0
                                            StyledText {
                                                Layout.fillWidth: true
                                                text: wifiRow.modelData.ssid
                                                elide: Text.ElideRight
                                                color: Appearance.colors.colOnSecondaryContainer
                                            }
                                            StyledText {
                                                Layout.fillWidth: true
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                color: Appearance.colors.colSubtext
                                                text: {
                                                    let parts = []
                                                    parts.push(wifiRow.modelData.isSecure ? wifiRow.modelData.security : Translation.tr("Open"))
                                                    if (wifiRow.modelData.active) parts.push(Translation.tr("Connected"))
                                                    else if (Network.wifiConnectTarget === wifiRow.modelData) parts.push(Translation.tr("Connecting…"))
                                                    if (wifiRow.known) parts.push(Translation.tr("Saved"))
                                                    return parts.join(" • ")
                                                }
                                            }
                                        }
                                        MaterialSymbol {
                                            visible: wifiRow.modelData.active
                                            text: "check_circle"
                                            iconSize: Appearance.font.pixelSize.larger
                                            color: Appearance.colors.colPrimary
                                        }
                                        MaterialSymbol {
                                            visible: !wifiRow.modelData.active && wifiRow.modelData.isSecure
                                            text: "lock"
                                            iconSize: Appearance.font.pixelSize.larger
                                            color: Appearance.colors.colSubtext
                                        }
                                    }
                                }

                                // Autoconnect toggle (saved networks only)
                                StyledSwitch {
                                    visible: wifiRow.known
                                    checked: NetworkExtras.autoconnectFor(wifiRow.modelData.ssid)
                                    onClicked: NetworkExtras.setAutoconnect(wifiRow.modelData.ssid, checked)
                                    StyledToolTip {
                                        text: Translation.tr("Connect automatically")
                                    }
                                }

                                // Forget (saved networks only), two-step confirm
                                RippleButtonWithIcon {
                                    visible: wifiRow.known && !wifiRow.confirmingForget
                                    materialIcon: "delete"
                                    mainText: ""
                                    onClicked: wifiRow.confirmingForget = true
                                    StyledToolTip {
                                        text: Translation.tr("Forget this network")
                                    }
                                }
                                DialogButton {
                                    visible: wifiRow.confirmingForget
                                    buttonText: Translation.tr("Forget?")
                                    colText: Appearance.m3colors.m3error
                                    onClicked: {
                                        wifiRow.confirmingForget = false
                                        NetworkExtras.forgetWifi(wifiRow.modelData.ssid)
                                    }
                                }
                                DialogButton {
                                    visible: wifiRow.confirmingForget
                                    buttonText: Translation.tr("Cancel")
                                    onClicked: wifiRow.confirmingForget = false
                                }
                            }

                            // PSK prompt (appears when connecting to a secured
                            // network whose secrets nmcli doesn't have yet)
                            ColumnLayout {
                                visible: wifiRow.modelData.askingPassword
                                Layout.fillWidth: true
                                Layout.leftMargin: 40
                                Layout.bottomMargin: 6

                                MaterialTextField {
                                    id: pskField
                                    Layout.fillWidth: true
                                    placeholderText: Translation.tr("Password")
                                    echoMode: TextInput.Password
                                    inputMethodHints: Qt.ImhSensitiveData
                                    onAccepted: Network.changePassword(wifiRow.modelData, pskField.text)
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    Item { Layout.fillWidth: true }
                                    DialogButton {
                                        buttonText: Translation.tr("Cancel")
                                        onClicked: wifiRow.modelData.askingPassword = false
                                    }
                                    DialogButton {
                                        buttonText: Translation.tr("Connect")
                                        onClicked: Network.changePassword(wifiRow.modelData, pskField.text)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Ethernet ─────────────────────────────────────────────────────
        ContentSection {
            icon: "lan"
            shape: MaterialShape.Shape.Arch
            title: Translation.tr("Ethernet")

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: ethCol.implicitHeight + 28
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1

                ColumnLayout {
                    id: ethCol
                    anchors { fill: parent; margins: 14 }
                    spacing: 10

                    StyledText {
                        visible: NetworkExtras.ethernetDevices.length === 0
                        Layout.leftMargin: 8
                        text: Translation.tr("No wired network devices")
                        color: Appearance.colors.colSubtext
                    }

                    Repeater {
                        model: NetworkExtras.ethernetDevices
                        delegate: ColumnLayout {
                            id: ethRow
                            required property var modelData
                            // Read-only native state (Quickshell.Networking),
                            // matched to the nmcli device by interface name
                            readonly property var nativeDev: QsNetworking.Networking.devices.values.find(d => d.name === ethRow.modelData.iface) ?? null
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                spacing: 10
                                MaterialSymbol {
                                    text: "settings_ethernet"
                                    iconSize: Appearance.font.pixelSize.huge
                                    color: Appearance.colors.colOnSecondaryContainer
                                }
                                StyledText {
                                    text: ethRow.modelData.iface
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colOnSecondaryContainer
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: ethRow.modelData.connection !== ""
                                        ? "• " + ethRow.modelData.connection
                                        : ""
                                    elide: Text.ElideRight
                                    color: Appearance.colors.colSubtext
                                }
                                StyledText {
                                    text: ethRow.modelData.state
                                    color: ethRow.modelData.state === "connected" ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                }
                            }
                            StyledText {
                                Layout.leftMargin: 34
                                visible: ethRow.modelData.ip4.length > 0
                                text: Translation.tr("IPv4: %1").arg(ethRow.modelData.ip4.join(", "))
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                            }
                            StyledText {
                                Layout.leftMargin: 34
                                visible: ethRow.modelData.ip6.length > 0
                                text: Translation.tr("IPv6: %1").arg(ethRow.modelData.ip6.join(", "))
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            StyledText {
                                Layout.leftMargin: 34
                                visible: ethRow.modelData.mac !== ""
                                text: Translation.tr("MAC: %1").arg(ethRow.modelData.mac)
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                            }
                            StyledText {
                                Layout.leftMargin: 34
                                visible: ethRow.nativeDev !== null && ethRow.nativeDev.linkSpeed > 0
                                text: Translation.tr("Link speed: %1 Mb/s").arg(ethRow.nativeDev !== null ? ethRow.nativeDev.linkSpeed : 0)
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }
                }
            }
        }

        // ── VPN ──────────────────────────────────────────────────────────
        ContentSection {
            icon: "vpn_lock"
            shape: MaterialShape.Shape.Pill
            title: Translation.tr("VPN")

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: vpnCol.implicitHeight + 20
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1

                ColumnLayout {
                    id: vpnCol
                    anchors { fill: parent; margins: 10 }
                    spacing: 2

                    StyledText {
                        visible: NetworkExtras.vpnConnections.length === 0
                        Layout.leftMargin: 8
                        text: Translation.tr("No VPN connections configured")
                        color: Appearance.colors.colSubtext
                    }

                    Repeater {
                        model: NetworkExtras.vpnConnections
                        delegate: RowLayout {
                            id: vpnRow
                            required property var modelData
                            property bool confirmingDelete: false
                            Layout.fillWidth: true
                            spacing: 10

                            MaterialSymbol {
                                Layout.leftMargin: 8
                                text: "vpn_key"
                                iconSize: Appearance.font.pixelSize.huge
                                color: vpnRow.modelData.active ? Appearance.colors.colPrimary : Appearance.colors.colOnSecondaryContainer
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                StyledText {
                                    Layout.fillWidth: true
                                    text: vpnRow.modelData.name
                                    elide: Text.ElideRight
                                    color: Appearance.colors.colOnSecondaryContainer
                                }
                                StyledText {
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                    text: (vpnRow.modelData.type === "wireguard" ? "WireGuard" : "VPN")
                                        + (vpnRow.modelData.active ? " • " + Translation.tr("Connected") : "")
                                }
                            }

                            RippleButtonWithIcon {
                                visible: !vpnRow.confirmingDelete
                                materialIcon: vpnRow.modelData.active ? "link_off" : "link"
                                mainText: vpnRow.modelData.active ? Translation.tr("Disconnect") : Translation.tr("Connect")
                                onClicked: {
                                    if (vpnRow.modelData.active)
                                        NetworkExtras.vpnDown(vpnRow.modelData.name)
                                    else
                                        NetworkExtras.vpnUp(vpnRow.modelData.name)
                                }
                            }
                            RippleButtonWithIcon {
                                visible: !vpnRow.confirmingDelete
                                materialIcon: "delete"
                                mainText: ""
                                onClicked: vpnRow.confirmingDelete = true
                                StyledToolTip {
                                    text: Translation.tr("Delete this VPN connection")
                                }
                            }
                            DialogButton {
                                visible: vpnRow.confirmingDelete
                                buttonText: Translation.tr("Delete?")
                                colText: Appearance.m3colors.m3error
                                onClicked: {
                                    vpnRow.confirmingDelete = false
                                    NetworkExtras.vpnDelete(vpnRow.modelData.name)
                                }
                            }
                            DialogButton {
                                visible: vpnRow.confirmingDelete
                                buttonText: Translation.tr("Cancel")
                                onClicked: vpnRow.confirmingDelete = false
                            }
                        }
                    }
                }
            }

            GroupedList {
                ConfigTextArea {
                    id: vpnImportField
                    buttonIcon: "download"
                    text: Translation.tr("Import VPN config")
                    description: Translation.tr(".ovpn (OpenVPN) or .conf (WireGuard) file path")
                    placeholderText: Translation.tr("/path/to/vpn-config.ovpn")
                    confirmButtonVisible: vpnImportField.value.trim() !== ""
                    confirmButtonIcon: "add"
                    onConfirmClicked: {
                        NetworkExtras.vpnImport(vpnImportField.value)
                        vpnImportField.value = ""
                    }
                }
            }

            StyledText {
                visible: NetworkExtras.lastActionOutput !== ""
                Layout.leftMargin: 8
                Layout.fillWidth: true
                text: NetworkExtras.lastActionOutput
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }
        }

        // ── DNS ──────────────────────────────────────────────────────────
        ContentSection {
            icon: "dns"
            shape: MaterialShape.Shape.Clover4Leaf
            title: Translation.tr("DNS")

            GroupedList {
                ConfigComboBox {
                    buttonIcon: "settings_input_antenna"
                    text: Translation.tr("Connection")
                    description: Translation.tr("DNS settings apply per connection")
                    model: NetworkExtras.dnsCapableConnections.map(c => ({
                        displayName: c.name + (c.active ? " (" + Translation.tr("active") + ")" : ""),
                        value: c.name
                    }))
                    currentValue: page.dnsConn
                    onSelected: newValue => {
                        page.selectedDnsConn = newValue
                    }
                }

                ColumnLayout {
                    spacing: 2
                    RowLayout {
                        Layout.leftMargin: 8
                        spacing: 10
                        MaterialSymbol {
                            text: "info"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.colors.colOnSecondaryContainer
                        }
                        StyledText {
                            Layout.fillWidth: true
                            color: Appearance.colors.colOnSecondaryContainer
                            text: {
                                if (NetworkExtras.currentPresetName !== "")
                                    return Translation.tr("Current: %1").arg(NetworkExtras.currentPresetName)
                                            + (NetworkExtras.currentDotEnabled ? " [DoT]" : "")
                                if (NetworkExtras.blockyActive && NetworkExtras.currentDnsV4.includes("127.0.0.1"))
                                    return Translation.tr("Current: Blocky (local DoH proxy)")
                                if (NetworkExtras.currentDnsV4 !== "" || NetworkExtras.currentDnsV6 !== "")
                                    return Translation.tr("Current: custom")
                                return Translation.tr("Current: automatic (DHCP)")
                            }
                        }
                        RippleButtonWithIcon {
                            materialIcon: "refresh"
                            mainText: ""
                            onClicked: NetworkExtras.readDns(page.dnsConn)
                            StyledToolTip {
                                text: Translation.tr("Re-read DNS of the selected connection")
                            }
                        }
                    }
                    StyledText {
                        Layout.leftMargin: 42
                        visible: NetworkExtras.currentDnsV4 !== ""
                        text: Translation.tr("IPv4: %1").arg(NetworkExtras.currentDnsV4)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                    StyledText {
                        Layout.leftMargin: 42
                        visible: NetworkExtras.currentDnsV6 !== ""
                        text: Translation.tr("IPv6: %1").arg(NetworkExtras.currentDnsV6)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }

                ConfigSwitch {
                    id: dotSwitch
                    buttonIcon: "encrypted"
                    text: Translation.tr("DNS over TLS (DoT)")
                    checked: NetworkExtras.currentDotEnabled
                    onCheckedChanged: {
                        if (checked !== NetworkExtras.currentDotEnabled && page.dnsConn !== "")
                            NetworkExtras.setDot(page.dnsConn, checked)
                    }
                    // Re-sync after readDns() of another connection (clicking
                    // breaks the `checked` binding)
                    Connections {
                        target: NetworkExtras
                        function onCurrentDotEnabledChanged() {
                            dotSwitch.checked = NetworkExtras.currentDotEnabled
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Provider")

                GroupedList {
                    ConfigComboBox {
                        buttonIcon: "dns"
                        text: Translation.tr("DNS provider")
                        description: Translation.tr("Choose a preset or enter custom DNS servers")
                        enabled: page.dnsConn !== ""
                        model: [
                            { displayName: Translation.tr("Automatic (DHCP)"), value: "automatic" }
                        ].concat(NetworkExtras.dnsPresets.map(preset => ({
                            displayName: preset.name,
                            value: preset.name
                        }))).concat([
                            { displayName: Translation.tr("Custom"), value: "custom" }
                        ])
                        currentValue: {
                            if (page.selectedDnsProvider !== "") return page.selectedDnsProvider
                            if (NetworkExtras.currentPresetName !== "") return NetworkExtras.currentPresetName
                            if (NetworkExtras.currentDnsV4 !== "" || NetworkExtras.currentDnsV6 !== "") return "custom"
                            return "automatic"
                        }
                        onSelected: newValue => {
                            page.selectedDnsProvider = newValue
                            if (newValue === "custom") return
                            if (newValue === "automatic") {
                                NetworkExtras.resetDns(page.dnsConn)
                                return
                            }

                            const preset = NetworkExtras.dnsPresets.find(item => item.name === newValue)
                            if (preset) {
                                NetworkExtras.applyDns(page.dnsConn,
                                    preset.ipv4,
                                    preset.ipv6,
                                    NetworkExtras.currentDotEnabled && preset.dot !== "")
                            }
                        }
                    }
                }
            }

            ContentSubsection {
                visible: page.customDnsProviderVisible
                title: Translation.tr("Custom provider")

                GroupedList {
                    ConfigTextArea {
                        id: customDnsV4Field
                        buttonIcon: "dns"
                        text: Translation.tr("Custom IPv4 DNS")
                        placeholderText: Translation.tr("e.g. 1.1.1.1,1.0.0.1")
                    }
                    ConfigTextArea {
                        id: customDnsV6Field
                        buttonIcon: "dns"
                        text: Translation.tr("Custom IPv6 DNS")
                        placeholderText: Translation.tr("e.g. 2606:4700:4700::1111")
                    }
                    RowLayout {
                        spacing: 10
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8

                        RippleButtonWithIcon {
                            materialIcon: "check"
                            mainText: Translation.tr("Apply custom DNS")
                            enabled: page.dnsConn !== "" && (customDnsV4Field.value.trim() !== "" || customDnsV6Field.value.trim() !== "")
                            onClicked: {
                                NetworkExtras.applyDns(page.dnsConn,
                                    customDnsV4Field.value.trim().replace(/\s+/g, ","),
                                    customDnsV6Field.value.trim().replace(/\s+/g, ","),
                                    NetworkExtras.currentDotEnabled)
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }
                }
            }
        }

        // ── Blocky (only shown when /etc/blocky/config.yml exists) ───────
        ContentSection {
            visible: NetworkExtras.blockyPresent
            icon: "shield"
            shape: MaterialShape.Shape.Clover8Leaf
            title: Translation.tr("Blocky (DNS proxy)")

            GroupedList {
                RowLayout {
                    id: blockyRow
                    property bool confirming: false
                    spacing: 10
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8

                    MaterialSymbol {
                        text: "shield"
                        iconSize: Appearance.font.pixelSize.larger
                        color: NetworkExtras.blockyActive ? Appearance.colors.colPrimary : Appearance.colors.colOnSecondaryContainer
                    }
                    StyledText {
                        Layout.fillWidth: true
                        color: Appearance.colors.colOnSecondaryContainer
                        text: NetworkExtras.blockyActive
                            ? Translation.tr("Blocky service is running")
                            : Translation.tr("Blocky service is stopped")
                    }
                    RippleButtonWithIcon {
                        visible: !blockyRow.confirming
                        materialIcon: NetworkExtras.blockyActive ? "stop" : "play_arrow"
                        mainText: NetworkExtras.blockyActive ? Translation.tr("Stop") : Translation.tr("Start")
                        onClicked: blockyRow.confirming = true
                    }
                    DialogButton {
                        visible: blockyRow.confirming
                        buttonText: NetworkExtras.blockyActive ? Translation.tr("Stop it?") : Translation.tr("Start it?")
                        colText: Appearance.m3colors.m3error
                        onClicked: {
                            blockyRow.confirming = false
                            NetworkExtras.blockySetActive(!NetworkExtras.blockyActive)
                        }
                    }
                    DialogButton {
                        visible: blockyRow.confirming
                        buttonText: Translation.tr("Cancel")
                        onClicked: blockyRow.confirming = false
                    }
                }
            }

            StyledText {
                Layout.leftMargin: 8
                Layout.fillWidth: true
                text: Translation.tr("Uses pkexec — a system authentication prompt will appear")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }
        }
    }
}
