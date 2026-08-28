import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    ContentSection {
        icon: "splitscreen_left"
        shape: MaterialShape.Shape.Clover4Leaf
        title: Translation.tr("Left Sidebar")

        GroupedList {
            ConfigSwitch {
                buttonIcon: "left_panel_open"
                text: Translation.tr("Enable left sidebar")
                checked: Config.options.sidebar.leftEnabled
                onCheckedChanged: Config.options.sidebar.leftEnabled = checked
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: mediaCol.implicitHeight + 24
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: "transparent"

                ColumnLayout {
                    id: mediaCol
                    anchors { fill: parent; margins: 12 }
                    spacing: 8

                    MaterialSymbol {
                        text: "music_note_2"
                        iconSize: Appearance.font.pixelSize.huge
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: Translation.tr("Media Player")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                    Item { Layout.fillHeight: true }
                    GroupedList {
                        Layout.fillWidth: true
                        bgcolor: Appearance.colors.colLayer2
                        ConfigSwitch {
                            buttonIcon: "check"
                            text: Translation.tr("Enable")
                            checked: Config.options.sidebar.media.enable
                            onCheckedChanged: { Config.options.sidebar.media.enable = checked }
                        }
                        ConfigSwitch {
                            buttonIcon: "radio_button_partial"
                            text: Translation.tr("Follow Album Colors")
                            checked: Config.options.sidebar.media.artColors
                            onCheckedChanged: { Config.options.sidebar.media.artColors = checked }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: aiCol.implicitHeight + 24
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: "transparent"

                    ColumnLayout {
                        id: aiCol
                        anchors { fill: parent; margins: 12 }
                        spacing: 8

                        MaterialSymbol {
                            text: "smart_toy"
                            iconSize: Appearance.font.pixelSize.huge
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            text: Translation.tr("AI")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        ConfigSelectionArray {
                            Layout.fillWidth: false
                            Layout.alignment: Qt.AlignRight
                            currentValue: Config.options.policies.ai
                            onSelected: newValue => { Config.options.policies.ai = newValue }
                            options: [
                                { displayName: Translation.tr("No"), icon: "close", value: 0 },
                                { displayName: Translation.tr("Yes"), icon: "check", value: 1 },
                                { displayName: Translation.tr("Local"), icon: "sync_saved_locally", value: 2 }
                            ]
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: weebCol.implicitHeight + 24
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: "transparent"

                    ColumnLayout {
                        id: weebCol
                        anchors { fill: parent; margins: 12 }
                        spacing: 8

                        MaterialSymbol {
                            text: "playing_cards"
                            iconSize: Appearance.font.pixelSize.huge
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            text: Translation.tr("Weeb")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        ConfigSelectionArray {
                            Layout.fillWidth: false
                            Layout.alignment: Qt.AlignRight
                            currentValue: Config.options.policies.weeb
                            onSelected: newValue => { Config.options.policies.weeb = newValue }
                            options: [
                                { displayName: Translation.tr("No"), icon: "close", value: 0 },
                                { displayName: Translation.tr("Yes"), icon: "check", value: 1 },
                                { displayName: Translation.tr("Closet"), icon: "ev_shadow", value: 2 }
                            ]
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 4
            implicitHeight: translatorCol.implicitHeight + 24
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1
            border.width: 1
            border.color: "transparent"

            ColumnLayout {
                id: translatorCol
                anchors { fill: parent; margins: 12 }
                spacing: 8

                RowLayout {
                    spacing: 8
                    ConfigSwitch {
                        buttonIcon: "translate"
                        text: Translation.tr("Enable Translator")
                        checked: Config.options.sidebar.translator.enable
                        onCheckedChanged: { Config.options.sidebar.translator.enable = checked }
                    }
                }
            }
        }
    }
}
