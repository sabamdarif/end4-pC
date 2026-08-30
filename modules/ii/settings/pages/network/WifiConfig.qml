import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: root
    forceWidth: true

    property string editingUuid: ""

    function openEditor(uuid) {
        if (uuid === "") return;
        WifiProfile.load(uuid);
        root.editingUuid = uuid;
    }

    function wifiSignalIcon(strength) {
        return strength > 80 ? "signal_wifi_4_bar"
            : strength > 60 ? "network_wifi_3_bar"
            : strength > 40 ? "network_wifi_2_bar"
            : strength > 20 ? "network_wifi_1_bar"
            : "signal_wifi_0_bar"
    }

    Component.onCompleted: NetworkExtras.refresh()

    // The editor replaces the lists in place: everything here lives in one
    // ContentPage column, so it cannot be overlaid on top of them.
    readonly property bool editing: root.editingUuid !== ""

    ContentSection {
        visible: !root.editing
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
                        readonly property bool known: Network.savedWifiProfileFor(modelData.ssid) !== null
                        readonly property bool connecting: Network.wifiConnectTarget === wifiRow.modelData
                            && !wifiRow.modelData.active
                        Layout.fillWidth: true
                        spacing: 2

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
                                    text: root.wifiSignalIcon(wifiRow.modelData.strength)
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

                        ConnectingWave {
                            Layout.fillWidth: true
                            Layout.leftMargin: 8
                            Layout.rightMargin: 8
                            running: wifiRow.connecting
                        }

                        // PSK prompt (appears when connecting to a secured
                        // network whose password NetworkManager doesn't have yet)
                        ColumnLayout {
                            visible: wifiRow.modelData.askingPassword
                            Layout.fillWidth: true
                            Layout.leftMargin: 40
                            Layout.bottomMargin: 6
                            onVisibleChanged: if (visible) {
                                pskField.clear()
                                pskField.forceActiveFocus()
                            }

                            StyledText {
                                Layout.fillWidth: true
                                visible: wifiRow.modelData.passwordError !== ""
                                text: wifiRow.modelData.passwordError
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.m3colors.m3error
                                wrapMode: Text.Wrap
                            }
                            MaterialTextField {
                                id: pskField
                                Layout.fillWidth: true
                                placeholderText: Translation.tr("Password")
                                echoMode: TextInput.Password
                                inputMethodHints: Qt.ImhSensitiveData
                                onAccepted: Network.connectWithPassword(wifiRow.modelData, pskField.text)
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Item { Layout.fillWidth: true }
                                DialogButton {
                                    buttonText: Translation.tr("Cancel")
                                    onClicked: {
                                        wifiRow.modelData.askingPassword = false
                                        wifiRow.modelData.passwordError = ""
                                    }
                                }
                                DialogButton {
                                    enabled: pskField.text.length > 0
                                    buttonText: Translation.tr("Connect")
                                    onClicked: Network.connectWithPassword(wifiRow.modelData, pskField.text)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ContentSection {
        visible: !root.editing
        icon: "bookmark"
        shape: MaterialShape.Shape.Clover4Leaf
        title: Translation.tr("Saved networks")

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: savedListCol.implicitHeight + 20
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1

            ColumnLayout {
                id: savedListCol
                anchors { fill: parent; margins: 10 }
                spacing: 2

                StyledText {
                    visible: NetworkExtras.wifiConnections.length === 0
                    Layout.leftMargin: 8
                    text: Translation.tr("No saved Wi-Fi networks")
                    color: Appearance.colors.colSubtext
                }

                Repeater {
                    model: NetworkExtras.wifiConnections
                    delegate: RowLayout {
                        id: savedRow
                        required property var modelData
                        // Saved profiles are matched to scan results by name,
                        // which is the SSID for every profile NetworkManager
                        // creates itself.
                        readonly property var inRange: Network.wifiNetworks.find(n => n.ssid === savedRow.modelData.name) ?? null
                        property bool confirmingForget: false
                        Layout.fillWidth: true
                        spacing: 6

                        RippleButton {
                            Layout.fillWidth: true
                            implicitHeight: 48
                            buttonRadius: Appearance.rounding.small
                            colBackground: "transparent"
                            onClicked: root.openEditor(savedRow.modelData.uuid)
                            StyledToolTip {
                                text: Translation.tr("Edit this network")
                            }
                            contentItem: RowLayout {
                                spacing: 10
                                MaterialSymbol {
                                    text: savedRow.inRange ? root.wifiSignalIcon(savedRow.inRange.strength) : "wifi_off"
                                    iconSize: Appearance.font.pixelSize.huge
                                    color: savedRow.modelData.active ? Appearance.colors.colPrimary : Appearance.colors.colOnSecondaryContainer
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: savedRow.modelData.name
                                        elide: Text.ElideRight
                                        color: Appearance.colors.colOnSecondaryContainer
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colSubtext
                                        elide: Text.ElideRight
                                        text: {
                                            let parts = []
                                            if (savedRow.modelData.active) parts.push(Translation.tr("Connected"))
                                            else if (savedRow.inRange) parts.push(Translation.tr("In range"))
                                            else parts.push(Translation.tr("Not in range"))
                                            if (!savedRow.modelData.autoconnect) parts.push(Translation.tr("Auto-connect off"))
                                            return parts.join(" • ")
                                        }
                                    }
                                }
                                MaterialSymbol {
                                    text: "chevron_right"
                                    iconSize: Appearance.font.pixelSize.larger
                                    color: Appearance.colors.colSubtext
                                }
                            }
                        }

                        RippleButtonWithIcon {
                            visible: !savedRow.confirmingForget
                            materialIcon: "delete"
                            mainText: ""
                            onClicked: savedRow.confirmingForget = true
                            StyledToolTip {
                                text: Translation.tr("Forget this network")
                            }
                        }
                        DialogButton {
                            visible: savedRow.confirmingForget
                            buttonText: Translation.tr("Forget?")
                            colText: Appearance.m3colors.m3error
                            onClicked: {
                                savedRow.confirmingForget = false
                                const uuid = savedRow.modelData.uuid
                                if (root.editingUuid === uuid) root.editingUuid = ""
                                NetworkExtras.forgetConnection(uuid)
                            }
                        }
                        DialogButton {
                            visible: savedRow.confirmingForget
                            buttonText: Translation.tr("Cancel")
                            onClicked: savedRow.confirmingForget = false
                        }
                    }
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

    // Shown while nmcli is reading the profile the editor is about to build from
    ColumnLayout {
        visible: root.editing && !editorLoader.active
        Layout.fillWidth: true
        spacing: 14

        StyledIndeterminateProgressBar {
            Layout.fillWidth: true
            visible: WifiProfile.lastError === ""
        }
        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: WifiProfile.lastError === "" ? Translation.tr("Reading connection…") : WifiProfile.lastError
            color: WifiProfile.lastError === "" ? Appearance.colors.colSubtext : Appearance.m3colors.m3error
            wrapMode: Text.Wrap
        }
        DialogButton {
            Layout.alignment: Qt.AlignHCenter
            buttonText: Translation.tr("Back")
            onClicked: root.editingUuid = ""
        }
    }

    // A Loader, not a `visible` binding: the editor's rows read their values
    // once at build time, so it may only be created after WifiProfile is ready.
    // Loaded by URL because page directories are not QML modules, so a sibling
    // file cannot be referenced as a type from here.
    Loader {
        id: editorLoader
        Layout.fillWidth: true
        active: root.editing && WifiProfile.ready && WifiProfile.uuid === root.editingUuid
        visible: active
        source: Qt.resolvedUrl("WifiProfileEditor.qml")
        onLoaded: {
            item.uuid = root.editingUuid;
            item.closeRequested.connect(() => root.editingUuid = "");
        }
    }
}
