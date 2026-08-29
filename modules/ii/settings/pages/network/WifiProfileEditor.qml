import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

/**
 * nmcli profile editor for one saved Wi-Fi connection, shown by WifiConfig in
 * place of its network lists.
 *
 * Every row registers itself in `fields` and remembers the value it was built
 * with, so Save writes only the properties that actually changed and leaves the
 * rest of the profile untouched. Rows read their value at build time, which is
 * why WifiConfig only creates this editor once WifiProfile.ready is set.
 */
ColumnLayout {
    id: editor

    property string uuid: ""
    // Sentinel for "no security at all": open networks have no
    // 802-11-wireless-security setting rather than an empty key-mgmt.
    readonly property string openSecurity: "__open__"
    readonly property var connection: NetworkExtras.connections.find(c => c.uuid === editor.uuid) ?? null
    readonly property bool enterprise: securityCombo.current === "wpa-eap"
    property var fields: []
    property string errorText: ""

    Layout.fillWidth: true
    spacing: 30

    signal closeRequested()

    function register(field) {
        editor.fields.push(field);
    }

    function isSecurityKey(key) {
        return key.startsWith("802-11-wireless-security.") || key.startsWith("802-1x.");
    }

    function collectChanges() {
        let changes = ({});
        for (const field of editor.fields) {
            if (!field.applies || !field.changed) continue;
            changes[field.fieldKey] = field.current;
        }
        return changes;
    }

    // Resetting the security setting also drops the secrets it held, so every
    // applicable security value has to be written back, changed or not.
    function collectSecurity(changes) {
        for (const field of editor.fields) {
            if (!field.applies || !editor.isSecurityKey(field.fieldKey)) continue;
            if (String(field.current) === "") continue;
            changes[field.fieldKey] = field.current;
        }
    }

    function save() {
        editor.errorText = "";
        let changes = editor.collectChanges();
        const mode = securityCombo.current;
        const resetSecurity = securityCombo.changed;

        if (mode === editor.openSecurity) {
            for (const key in changes) {
                if (editor.isSecurityKey(key)) delete changes[key];
            }
        } else if (resetSecurity) {
            changes["802-11-wireless-security.key-mgmt"] = mode;
            editor.collectSecurity(changes);
            // NetworkManager rejects an enterprise profile with no EAP method
            if (mode === "wpa-eap" && (changes["802-1x.eap"] ?? "") === "")
                changes["802-1x.eap"] = eapCombo.current;
        }

        WifiProfile.applyChanges(changes, resetSecurity, editor.connection?.active ?? false);
    }

    Connections {
        target: WifiProfile
        function onApplied(ok) {
            if (!ok) {
                editor.errorText = WifiProfile.lastError;
                return;
            }
            NetworkExtras.refresh();
            editor.closeRequested();
        }
    }

    component FormCard: Rectangle {
        default property alias content: cardColumn.data
        Layout.fillWidth: true
        implicitHeight: cardColumn.implicitHeight + 20
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer1

        ColumnLayout {
            id: cardColumn
            anchors { fill: parent; margins: 10 }
            spacing: 6
        }
    }

    component FieldText: ConfigTextArea {
        required property string fieldKey
        property bool applies: true
        property string initial: WifiProfile.get(fieldKey)
        readonly property string current: value
        readonly property bool changed: current !== initial
        visible: applies
        value: initial
        fieldWidth: 250
        Component.onCompleted: editor.register(this)
    }

    component FieldSwitch: ConfigSwitch {
        required property string fieldKey
        property bool applies: true
        property string onValue: "yes"
        property string offValue: "no"
        property string initial: WifiProfile.get(fieldKey)
        readonly property string current: checked ? onValue : offValue
        readonly property bool changed: current !== initial
        visible: applies
        checked: initial === onValue
        Component.onCompleted: editor.register(this)
    }

    component FieldCombo: ConfigComboBox {
        required property string fieldKey
        property bool applies: true
        property string initial: WifiProfile.get(fieldKey)
        property string current: initial
        readonly property bool changed: current !== initial
        visible: applies
        currentValue: current
        onSelected: newValue => current = newValue
        Component.onCompleted: editor.register(this)
    }

    component FieldSpin: ConfigSpinBox {
        required property string fieldKey
        property bool applies: true
        property string initial: WifiProfile.get(fieldKey)
        // Unset numeric properties read back as "auto" or an empty string
        readonly property int initialValue: isNaN(parseInt(initial)) ? 0 : parseInt(initial)
        readonly property string current: String(value)
        readonly property bool changed: value !== initialValue
        visible: applies
        value: initialValue
        Component.onCompleted: editor.register(this)
    }

    component FieldPassword: RowLayout {
        id: passwordRow
        required property string fieldKey
        property bool applies: true
        property string label: ""
        property string initial: WifiProfile.get(fieldKey)
        readonly property string current: passwordInput.text
        readonly property bool changed: current !== initial
        visible: applies
        spacing: 10
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        Component.onCompleted: editor.register(this)

        StyledText {
            Layout.fillWidth: true
            text: passwordRow.label
            color: Appearance.colors.colOnSecondaryContainer
        }

        MaterialTextField {
            id: passwordInput
            Layout.preferredWidth: 250
            text: passwordRow.initial
            echoMode: revealButton.toggled ? TextInput.Normal : TextInput.Password
            inputMethodHints: Qt.ImhSensitiveData
            selectByMouse: true
            placeholderText: Translation.tr("Not set")
        }

        RippleButton {
            id: revealButton
            implicitWidth: 36
            implicitHeight: 36
            buttonRadius: Appearance.rounding.full
            onClicked: toggled = !toggled
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                text: revealButton.toggled ? "visibility_off" : "visibility"
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnLayer1
            }
            StyledToolTip {
                text: Translation.tr("Show password")
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        RippleButton {
            implicitWidth: 40
            implicitHeight: 40
            buttonRadius: Appearance.rounding.full
            onClicked: editor.closeRequested()
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                text: "arrow_back"
                iconSize: Appearance.font.pixelSize.huge
                color: Appearance.colors.colOnLayer1
            }
            StyledToolTip {
                text: Translation.tr("Back to Wi-Fi")
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Editing %1").arg(editor.connection?.name ?? editor.uuid)
                font.pixelSize: Appearance.font.pixelSize.larger
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
                elide: Text.ElideRight
            }
            StyledText {
                Layout.fillWidth: true
                text: (editor.connection?.active ?? false)
                    ? Translation.tr("Connected. Saving reconnects this network.")
                    : Translation.tr("Saved network")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                elide: Text.ElideRight
            }
        }
    }

    ContentSection {
        icon: "tune"
        shape: MaterialShape.Shape.Cookie4Sided
        title: Translation.tr("General")

        FormCard {
            FieldText {
                fieldKey: "connection.id"
                text: Translation.tr("Connection name")
            }
            FieldSwitch {
                fieldKey: "connection.autoconnect"
                buttonIcon: "autorenew"
                text: Translation.tr("Connect automatically")
            }
            FieldSpin {
                fieldKey: "connection.autoconnect-priority"
                icon: "low_priority"
                text: Translation.tr("Autoconnect priority")
                from: -999
                to: 999
            }
            FieldSwitch {
                fieldKey: "connection.permissions"
                buttonIcon: "group"
                text: Translation.tr("All users may connect to this network")
                onValue: ""
                offValue: "user:" + SystemInfo.username
            }
            FieldCombo {
                fieldKey: "connection.secondaries"
                buttonIcon: "vpn_key"
                text: Translation.tr("Automatically connect to VPN")
                model: [{ displayName: Translation.tr("None"), value: "" }].concat(
                    NetworkExtras.vpnConnections.map(c => ({ displayName: c.name, value: c.uuid })))
            }
            FieldCombo {
                fieldKey: "connection.metered"
                buttonIcon: "data_usage"
                text: Translation.tr("Metered connection")
                model: [
                    { displayName: Translation.tr("Automatic"), value: "unknown" },
                    { displayName: Translation.tr("Yes"), value: "yes" },
                    { displayName: Translation.tr("No"), value: "no" },
                ]
            }
        }
    }

    ContentSection {
        icon: "wifi"
        shape: MaterialShape.Shape.Circle
        title: Translation.tr("Wi-Fi")

        FormCard {
            FieldText {
                fieldKey: "802-11-wireless.ssid"
                text: Translation.tr("SSID")
            }
            FieldCombo {
                fieldKey: "802-11-wireless.mode"
                text: Translation.tr("Mode")
                model: [
                    { displayName: Translation.tr("Client"), value: "infrastructure" },
                    { displayName: Translation.tr("Hotspot"), value: "ap" },
                    { displayName: Translation.tr("Ad-hoc"), value: "adhoc" },
                ]
            }
            FieldCombo {
                fieldKey: "802-11-wireless.band"
                text: Translation.tr("Band")
                model: [
                    { displayName: Translation.tr("Automatic"), value: "" },
                    { displayName: Translation.tr("2.4 GHz"), value: "bg" },
                    { displayName: Translation.tr("5 GHz"), value: "a" },
                ]
            }
            FieldSpin {
                fieldKey: "802-11-wireless.channel"
                text: Translation.tr("Channel (0 for default)")
                from: 0
                to: 196
            }
            FieldText {
                fieldKey: "802-11-wireless.bssid"
                text: Translation.tr("BSSID")
                placeholderText: Translation.tr("Any")
            }
            FieldText {
                fieldKey: "connection.interface-name"
                text: Translation.tr("Device")
                placeholderText: Translation.tr("Any")
            }
            FieldText {
                fieldKey: "802-11-wireless.cloned-mac-address"
                text: Translation.tr("Cloned MAC address")
                description: Translation.tr("permanent, preserve, random, stable or a MAC address")
                placeholderText: Translation.tr("Default")
            }
            FieldSpin {
                fieldKey: "802-11-wireless.mtu"
                text: Translation.tr("MTU in bytes (0 for automatic)")
                from: 0
                to: 10000
            }
            FieldSwitch {
                fieldKey: "802-11-wireless.hidden"
                buttonIcon: "visibility_off"
                text: Translation.tr("Hidden network")
            }
        }
    }

    ContentSection {
        icon: "lock"
        shape: MaterialShape.Shape.Diamond
        title: Translation.tr("Wi-Fi Security")

        FormCard {
            FieldCombo {
                id: securityCombo
                fieldKey: "802-11-wireless-security.key-mgmt"
                text: Translation.tr("Security")
                fieldWidth: 250
                initial: WifiProfile.props["802-11-wireless-security.key-mgmt"] ?? editor.openSecurity
                model: [
                    { displayName: Translation.tr("None"), value: editor.openSecurity },
                    { displayName: Translation.tr("WEP 40/128-bit key"), value: "none" },
                    { displayName: Translation.tr("WPA/WPA2 Personal"), value: "wpa-psk" },
                    { displayName: Translation.tr("WPA3 Personal"), value: "sae" },
                    { displayName: Translation.tr("Enhanced Open (OWE)"), value: "owe" },
                    { displayName: Translation.tr("WPA/WPA2 Enterprise"), value: "wpa-eap" },
                ]
            }
            FieldPassword {
                fieldKey: "802-11-wireless-security.psk"
                label: Translation.tr("Password")
                applies: securityCombo.current === "wpa-psk" || securityCombo.current === "sae"
            }
            FieldPassword {
                fieldKey: "802-11-wireless-security.wep-key0"
                label: Translation.tr("WEP key")
                applies: securityCombo.current === "none"
            }
            FieldCombo {
                id: eapCombo
                fieldKey: "802-1x.eap"
                text: Translation.tr("EAP method")
                applies: editor.enterprise
                model: [
                    { displayName: "PEAP", value: "peap" },
                    { displayName: "TTLS", value: "ttls" },
                    { displayName: "TLS", value: "tls" },
                    { displayName: "PWD", value: "pwd" },
                    { displayName: "LEAP", value: "leap" },
                ]
            }
            FieldCombo {
                fieldKey: "802-1x.phase2-auth"
                text: Translation.tr("Inner authentication")
                applies: editor.enterprise
                model: [
                    { displayName: Translation.tr("None"), value: "" },
                    { displayName: "MSCHAPv2", value: "mschapv2" },
                    { displayName: "GTC", value: "gtc" },
                    { displayName: "PAP", value: "pap" },
                    { displayName: "MD5", value: "md5" },
                ]
            }
            FieldText {
                fieldKey: "802-1x.identity"
                text: Translation.tr("Identity")
                applies: editor.enterprise
            }
            FieldText {
                fieldKey: "802-1x.anonymous-identity"
                text: Translation.tr("Anonymous identity")
                applies: editor.enterprise
            }
            FieldPassword {
                fieldKey: "802-1x.password"
                label: Translation.tr("Password")
                applies: editor.enterprise
            }
            FieldText {
                fieldKey: "802-1x.ca-cert"
                text: Translation.tr("CA certificate")
                placeholderText: Translation.tr("/path/to/ca.pem")
                applies: editor.enterprise
            }
        }
    }

    ContentSection {
        icon: "captive_portal"
        shape: MaterialShape.Shape.Pill
        title: Translation.tr("Proxy")

        FormCard {
            FieldCombo {
                id: proxyMethodCombo
                fieldKey: "proxy.method"
                text: Translation.tr("Method")
                model: [
                    { displayName: Translation.tr("None"), value: "none" },
                    { displayName: Translation.tr("Automatic"), value: "auto" },
                ]
            }
            FieldSwitch {
                fieldKey: "proxy.browser-only"
                buttonIcon: "public"
                text: Translation.tr("For browser only")
                applies: proxyMethodCombo.current === "auto"
            }
            FieldText {
                fieldKey: "proxy.pac-url"
                text: Translation.tr("PAC URL")
                applies: proxyMethodCombo.current === "auto"
            }
            FieldText {
                fieldKey: "proxy.pac-script"
                text: Translation.tr("PAC script")
                applies: proxyMethodCombo.current === "auto"
            }
        }
    }

    ContentSection {
        icon: "route"
        shape: MaterialShape.Shape.Arch
        title: Translation.tr("IPv4")

        FormCard {
            FieldCombo {
                id: ipv4MethodCombo
                fieldKey: "ipv4.method"
                text: Translation.tr("Method")
                model: [
                    { displayName: Translation.tr("Automatic (DHCP)"), value: "auto" },
                    { displayName: Translation.tr("Manual"), value: "manual" },
                    { displayName: Translation.tr("Link-local only"), value: "link-local" },
                    { displayName: Translation.tr("Shared to other computers"), value: "shared" },
                    { displayName: Translation.tr("Disabled"), value: "disabled" },
                ]
            }
            FieldText {
                fieldKey: "ipv4.addresses"
                text: Translation.tr("Addresses")
                description: Translation.tr("Comma-separated, for example 192.168.1.10/24")
                applies: ipv4MethodCombo.current === "manual"
            }
            FieldText {
                fieldKey: "ipv4.gateway"
                text: Translation.tr("Gateway")
                applies: ipv4MethodCombo.current === "manual"
            }
            FieldText {
                fieldKey: "ipv4.dns"
                text: Translation.tr("Additional DNS servers")
                description: Translation.tr("Comma-separated")
            }
            FieldText {
                fieldKey: "ipv4.dns-search"
                text: Translation.tr("Additional search domains")
            }
            FieldText {
                fieldKey: "ipv4.dhcp-client-id"
                text: Translation.tr("DHCP client ID")
                applies: ipv4MethodCombo.current === "auto"
            }
            FieldText {
                fieldKey: "ipv4.routes"
                text: Translation.tr("Static routes")
                description: Translation.tr("For example 10.0.0.0/8 10.0.0.1 100")
            }
            FieldSwitch {
                fieldKey: "ipv4.ignore-auto-dns"
                buttonIcon: "dns"
                text: Translation.tr("Ignore automatically obtained DNS")
            }
            FieldSwitch {
                fieldKey: "ipv4.never-default"
                buttonIcon: "alt_route"
                text: Translation.tr("Use only for resources on its own network")
            }
            FieldSwitch {
                fieldKey: "ipv4.may-fail"
                buttonIcon: "check_circle"
                text: Translation.tr("Require IPv4 addressing to complete")
                onValue: "no"
                offValue: "yes"
            }
        }
    }

    ContentSection {
        icon: "route"
        shape: MaterialShape.Shape.Fan
        title: Translation.tr("IPv6")

        FormCard {
            FieldCombo {
                id: ipv6MethodCombo
                fieldKey: "ipv6.method"
                text: Translation.tr("Method")
                model: [
                    { displayName: Translation.tr("Automatic"), value: "auto" },
                    { displayName: Translation.tr("Automatic, DHCP only"), value: "dhcp" },
                    { displayName: Translation.tr("Manual"), value: "manual" },
                    { displayName: Translation.tr("Link-local only"), value: "link-local" },
                    { displayName: Translation.tr("Ignore"), value: "ignore" },
                    { displayName: Translation.tr("Disabled"), value: "disabled" },
                ]
            }
            FieldText {
                fieldKey: "ipv6.addresses"
                text: Translation.tr("Addresses")
                description: Translation.tr("Comma-separated, for example fd00::5/64")
                applies: ipv6MethodCombo.current === "manual"
            }
            FieldText {
                fieldKey: "ipv6.gateway"
                text: Translation.tr("Gateway")
                applies: ipv6MethodCombo.current === "manual"
            }
            FieldText {
                fieldKey: "ipv6.dns"
                text: Translation.tr("Additional DNS servers")
                description: Translation.tr("Comma-separated")
            }
            FieldText {
                fieldKey: "ipv6.dns-search"
                text: Translation.tr("Additional search domains")
            }
            FieldCombo {
                fieldKey: "ipv6.ip6-privacy"
                text: Translation.tr("Privacy extensions")
                model: [
                    { displayName: Translation.tr("Default"), value: "-1" },
                    { displayName: Translation.tr("Disabled"), value: "0" },
                    { displayName: Translation.tr("Prefer public address"), value: "1" },
                    { displayName: Translation.tr("Prefer temporary address"), value: "2" },
                ]
            }
            FieldCombo {
                fieldKey: "ipv6.addr-gen-mode"
                text: Translation.tr("Address generation mode")
                model: [
                    { displayName: Translation.tr("Default"), value: "default" },
                    { displayName: Translation.tr("Stable privacy"), value: "stable-privacy" },
                    { displayName: "EUI64", value: "eui64" },
                ]
            }
            FieldText {
                fieldKey: "ipv6.routes"
                text: Translation.tr("Static routes")
            }
            FieldSwitch {
                fieldKey: "ipv6.ignore-auto-dns"
                buttonIcon: "dns"
                text: Translation.tr("Ignore automatically obtained DNS")
            }
            FieldSwitch {
                fieldKey: "ipv6.never-default"
                buttonIcon: "alt_route"
                text: Translation.tr("Use only for resources on its own network")
            }
            FieldSwitch {
                fieldKey: "ipv6.may-fail"
                buttonIcon: "check_circle"
                text: Translation.tr("Require IPv6 addressing to complete")
                onValue: "no"
                offValue: "yes"
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        StyledText {
            visible: editor.errorText !== ""
            Layout.fillWidth: true
            Layout.leftMargin: 8
            text: editor.errorText
            color: Appearance.m3colors.m3error
            font.pixelSize: Appearance.font.pixelSize.smaller
            wrapMode: Text.Wrap
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Item {
                Layout.fillWidth: true
            }
            DialogButton {
                buttonText: Translation.tr("Cancel")
                onClicked: editor.closeRequested()
            }
            DialogButton {
                buttonText: WifiProfile.applying ? Translation.tr("Saving…") : Translation.tr("Save")
                enabled: !WifiProfile.applying
                onClicked: editor.save()
            }
        }
    }
}
