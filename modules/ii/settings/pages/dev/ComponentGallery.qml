import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.modules.common
import qs.modules.common.widgets

SettingsPage {
    id: root

    title: Translation.tr("Component Gallery")
    subtitle: Translation.tr("Dev-only verification of settings controls, states, and responsive layouts")
    tabs: [Translation.tr("Controls"), Translation.tr("Lists & Dialogs"), Translation.tr("WIP Overlays")]

    headerActions: [
        RippleButton {
            implicitHeight: 34
            implicitWidth: themeToggleLabel.implicitWidth + 24
            buttonRadius: Appearance.rounding.small
            colBackground: Appearance.colors.colSecondaryContainer
            colBackgroundHover: Appearance.colors.colSecondaryContainerHover

            onClicked: {
                Appearance.m3colors.darkmode = !Appearance.m3colors.darkmode
            }

            contentItem: RowLayout {
                id: themeToggleLabel
                anchors.centerIn: parent
                spacing: 6

                MaterialSymbol {
                    text: Appearance.m3colors.darkmode ? "light_mode" : "dark_mode"
                    iconSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnSecondaryContainer
                }

                StyledText {
                    text: Appearance.m3colors.darkmode ? Translation.tr("Light preview") : Translation.tr("Dark preview")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnSecondaryContainer
                }
            }
        }
    ]

    // Confirm Dialog instance
    ConfirmDialog {
        id: demoConfirmDialog
        title: Translation.tr("Delete Saved Network")
        targetName: "Office-Guest-Wi-Fi"
        onConfirmed: console.log("Demo confirmed deletion")
        onCancelled: console.log("Demo cancelled deletion")
    }

    // Apply / Revert bar demo
    ApplyRevertBar {
        id: demoApplyBar
        onKeepChanges: console.log("Demo changes kept")
        onRevertChanges: console.log("Demo changes reverted")
    }

    // Tab 0: Controls
    ColumnLayout {
        visible: root.currentTab === 0
        Layout.fillWidth: true
        spacing: 20

        StatusCard {
            icon: "wifi"
            title: "Home-Network-5G"
            subtitle: "Connected, 5 GHz • 192.168.1.104 • 866 Mbps"
            statusText: Translation.tr("Connected")
            actionText: Translation.tr("Disconnect")
            onActionClicked: console.log("StatusCard disconnect clicked")
        }

        SetupGate {}

        SettingsSection {
            title: Translation.tr("Control Rules")
            subtitle: Translation.tr("One dedicated component per control rule")
            icon: "tune"

            SettingSwitchRow {
                rowId: "gallery_switch"
                label: Translation.tr("On or off toggle")
                subtitle: Translation.tr("Switch control for binary on/off options")
                checked: true
            }

            SettingSegmentedRow {
                rowId: "gallery_segmented"
                label: Translation.tr("Exclusive choices (2 to 4)")
                subtitle: Translation.tr("Segmented selector pill for small sets of exclusive choices")
                options: [
                    { label: Translation.tr("Top"), value: "top" },
                    { label: Translation.tr("Bottom"), value: "bottom" },
                    { label: Translation.tr("Left"), value: "left" },
                    { label: Translation.tr("Right"), value: "right" }
                ]
                value: "top"
            }

            SettingDropdownRow {
                rowId: "gallery_dropdown"
                label: Translation.tr("Exclusive choices (5 to 10)")
                subtitle: Translation.tr("Dropdown menu when choices exceed four items")
                model: [
                    { text: Translation.tr("Default Profile"), value: "default" },
                    { text: Translation.tr("High Performance"), value: "perf" },
                    { text: Translation.tr("Power Saver"), value: "powersave" },
                    { text: Translation.tr("Presentation"), value: "presentation" },
                    { text: Translation.tr("Gaming Low Latency"), value: "gaming" }
                ]
                currentIndex: 0
            }

            SettingSliderRow {
                rowId: "gallery_slider"
                label: Translation.tr("Natural scale number")
                subtitle: Translation.tr("Slider with live value label and unit suffix")
                from: 0
                to: 100
                stepSize: 5
                value: 65
                unit: "%"
            }

            SettingSpinRow {
                rowId: "gallery_spin"
                label: Translation.tr("Exact number")
                subtitle: Translation.tr("Spinbox for precise integer values with units")
                from: 0
                to: 60
                stepSize: 1
                value: 12
                unit: "px"
            }

            SettingRevealerRow {
                rowId: "gallery_revealer"
                label: Translation.tr("Value where 0 means off")
                subtitle: Translation.tr("Switch expands and reveals the value when non-zero")
                from: 5
                to: 120
                stepSize: 5
                offValue: 0
                defaultOnValue: 30
                value: 30
                unit: "s"
            }

            SettingPickerRow {
                rowId: "gallery_picker"
                label: Translation.tr("Resource picker")
                subtitle: Translation.tr("Picker for files, fonts, or directories instead of free text")
                pickerType: "font"
                value: "Google Sans Flex"
            }

            SettingTextRow {
                rowId: "gallery_text"
                label: Translation.tr("Text input")
                subtitle: Translation.tr("Validated text field for strings")
                text: "desktop-hostname"
            }
        }

        SettingsSection {
            title: Translation.tr("Row States and Validation")
            subtitle: Translation.tr("Modified indicators, restart badges, and overflow handling")
            icon: "verified"

            SettingSliderRow {
                rowId: "gallery_modified_demo"
                label: Translation.tr("Modified setting indicator")
                subtitle: Translation.tr("Shows primary colored dot when different from default, with reset on hover")
                defaultValue: 20
                value: 45
                from: 0
                to: 100
                unit: "px"
                onResetRequested: value = 20
            }

            SettingSwitchRow {
                rowId: "gallery_restart_tag"
                label: Translation.tr("Restart required setting")
                subtitle: Translation.tr("Carries small tag indicating a shell restart is needed")
                requiresRestart: true
                checked: false
            }

            SettingSwitchRow {
                rowId: "gallery_relogin_tag"
                label: Translation.tr("Session re-login required")
                subtitle: Translation.tr("Carries small tag indicating a full desktop logout is needed")
                requiresRelogin: true
                checked: false
            }

            SettingSwitchRow {
                rowId: "gallery_long_label"
                label: Translation.tr("Extraordinarily long label testing wrapping and responsiveness across varied window sizes without truncating crucial instructions")
                subtitle: Translation.tr("Very detailed secondary explanation describing why this setting operates the way it does and how it affects compositor rendering")
                checked: true
            }

            SettingRow {
                label: Translation.tr("Test Apply and Revert countdown")
                subtitle: Translation.tr("Simulates a risky monitor or DNS setting change with a 15-second safety timer")

                RippleButton {
                    implicitHeight: 34
                    implicitWidth: triggerLabel.implicitWidth + 20
                    buttonRadius: Appearance.rounding.small
                    colBackground: Appearance.colors.colPrimaryContainer
                    onClicked: demoApplyBar.start(15)

                    contentItem: StyledText {
                        id: triggerLabel
                        anchors.centerIn: parent
                        text: Translation.tr("Trigger 15s Revert Bar")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnPrimaryContainer
                    }
                }
            }

            SettingRow {
                label: Translation.tr("Test Confirm Dialog")
                subtitle: Translation.tr("Simulates destructive action that names the target object")

                RippleButton {
                    implicitHeight: 34
                    implicitWidth: dialogLabel.implicitWidth + 20
                    buttonRadius: Appearance.rounding.small
                    colBackground: Appearance.colors.colErrorContainer
                    onClicked: demoConfirmDialog.open("Office-Guest-Wi-Fi")

                    contentItem: StyledText {
                        id: dialogLabel
                        anchors.centerIn: parent
                        text: Translation.tr("Open Confirm Dialog")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnErrorContainer
                    }
                }
            }
        }
    }

    // Tab 1: Lists & Dialogs
    ColumnLayout {
        visible: root.currentTab === 1
        Layout.fillWidth: true
        spacing: 20

        SettingsSection {
            title: Translation.tr("List Rows with Secondary Actions")
            subtitle: Translation.tr("Click row for primary action; chevron edits; secondary actions on hover")
            icon: "list"

            ListRow {
                icon: "wifi"
                title: "CoffeeShop_Guest"
                subtitle: "Secured, 2.4 GHz • Good signal"
                trailingText: Translation.tr("Saved")

                RippleButton {
                    implicitWidth: 28
                    implicitHeight: 28
                    buttonRadius: Appearance.rounding.full
                    colBackground: "transparent"
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "share"
                        iconSize: 16
                        color: Appearance.colors.colSubtext
                    }
                }

                RippleButton {
                    implicitWidth: 28
                    implicitHeight: 28
                    buttonRadius: Appearance.rounding.full
                    colBackground: "transparent"
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "delete"
                        iconSize: 16
                        color: Appearance.colors.colError
                    }
                }
            }

            ListRow {
                icon: "headphones"
                title: "Sony WH-1000XM4"
                subtitle: "Audio device • Paired"
                trailingText: "80%"
            }
        }

        SettingsSection {
            title: Translation.tr("Collapsible List (Filter above 10 items)")
            subtitle: Translation.tr("Shows first 5 items, 'Show N more', filter search when exceeding 10 items")
            icon: "filter_list"

            CollapsibleList {
                items: [
                    { title: "Alpha Network", type: "Wi-Fi" },
                    { title: "Beta Station", type: "Wi-Fi" },
                    { title: "Gamma Lab", type: "Wi-Fi" },
                    { title: "Delta Airport", type: "Wi-Fi" },
                    { title: "Epsilon Hotspot", type: "Wi-Fi" },
                    { title: "Zeta Office", type: "Wi-Fi" },
                    { title: "Eta Guest", type: "Wi-Fi" },
                    { title: "Theta Conference", type: "Wi-Fi" },
                    { title: "Iota Cafe", type: "Wi-Fi" },
                    { title: "Kappa Home", type: "Wi-Fi" },
                    { title: "Lambda Studio", type: "Wi-Fi" },
                    { title: "Mu Outdoor", type: "Wi-Fi" }
                ]

                delegate: ListRow {
                    required property var modelData
                    icon: "wifi"
                    title: modelData.title
                    subtitle: modelData.type
                }
            }
        }
    }

    // Tab 2: WIP Overlays
    ColumnLayout {
        visible: root.currentTab === 2
        Layout.fillWidth: true
        spacing: 20

        SettingsSection {
            title: Translation.tr("Active Setting Rows with WIP Flag")
            subtitle: Translation.tr("Single rows get dimmed appearance and WIP badge")
            icon: "construction"

            SettingSwitchRow {
                rowId: "gallery_wip_row"
                label: Translation.tr("Share Wi-Fi via QR Code")
                subtitle: Translation.tr("Generates standard WIFI: QR payload (Phase 2 placeholder)")
                wipFeature: "wifi_qr"
                checked: false
            }

            SettingDropdownRow {
                rowId: "gallery_wip_dropdown"
                label: Translation.tr("Inactive window opacity")
                subtitle: Translation.tr("Dims unselected windows (Phase 2 placeholder)")
                wipFeature: "inactive_window_opacity"
                model: ["100%", "90%", "80%", "70%"]
            }
        }

        SettingsSection {
            title: Translation.tr("Section with Full WIP Overlay")
            subtitle: Translation.tr("Whole section blocked by scrim and rotated watermark")
            icon: "security"
            wipFeature: "firewall"

            SettingSwitchRow {
                label: "Firewall Status"
                checked: true
            }

            SettingSwitchRow {
                label: "Block incoming connections"
                checked: true
            }
        }
    }
}
