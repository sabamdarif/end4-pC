import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

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
}
