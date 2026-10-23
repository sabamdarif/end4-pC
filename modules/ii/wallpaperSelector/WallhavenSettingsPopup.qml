import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/**
 * Popup for configuring Wallhaven search filters.
 * The search is deferred until the popup closes; `dirty` tracks whether any filter changed.
 * WindowDialog freezes its height on open, so backgroundHeight is fixed at the tallest
 * state (with the Top Range row visible) instead of growing with the content.
 */
WindowDialog {
    id: root
    backgroundWidth: 620
    backgroundHeight: 470

    property bool dirty: false

    WindowDialogTitle {
        text: Translation.tr("Wallhaven Settings")
    }

    WindowDialogSeparator {}

    readonly property bool isToplist: sortingCombo.sortKeys[sortingCombo.currentIndex] === "toplist"

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 16
        rowSpacing: 12

        // Left column: combos
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                StyledText {
                    text: Translation.tr("Sort by")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }

                StyledComboBox {
                    id: sortingCombo
                    Layout.fillWidth: true
                    model: [
                        Translation.tr("Date Added"),
                        Translation.tr("Relevance"),
                        Translation.tr("Random"),
                        Translation.tr("Views"),
                        Translation.tr("Favorites"),
                        Translation.tr("Top List"),
                        Translation.tr("Hot"),
                    ]
                    property var sortKeys: ["date_added", "relevance", "random", "views", "favorites", "toplist", "hot"]
                    currentIndex: sortKeys.indexOf(OnlineWallpapers.wallhavenSorting)
                    onActivated: index => {
                        OnlineWallpapers.wallhavenSorting = sortKeys[index]
                        root.dirty = true
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: root.isToplist

                StyledText {
                    text: Translation.tr("Top Range")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }

                StyledComboBox {
                    Layout.fillWidth: true
                    model: [
                        Translation.tr("1 Day"),
                        Translation.tr("3 Days"),
                        Translation.tr("1 Week"),
                        Translation.tr("1 Month"),
                        Translation.tr("3 Months"),
                        Translation.tr("6 Months"),
                        Translation.tr("1 Year"),
                    ]
                    property var topRangeKeys: ["1d", "3d", "1w", "1m", "3m", "6m", "1y"]
                    currentIndex: topRangeKeys.indexOf(OnlineWallpapers.wallhavenTopRange)
                    onActivated: index => {
                        OnlineWallpapers.wallhavenTopRange = topRangeKeys[index]
                        root.dirty = true
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: sortingCombo.currentIndex !== 2 // order is meaningless for "random"

                StyledText {
                    text: Translation.tr("Order")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }

                StyledComboBox {
                    Layout.fillWidth: true
                    model: [Translation.tr("Descending"), Translation.tr("Ascending")]
                    property var orderKeys: ["desc", "asc"]
                    currentIndex: orderKeys.indexOf(OnlineWallpapers.wallhavenOrder)
                    onActivated: index => {
                        OnlineWallpapers.wallhavenOrder = orderKeys[index]
                        root.dirty = true
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                StyledText {
                    text: Translation.tr("Ratio")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }

                StyledComboBox {
                    Layout.fillWidth: true
                    model: [
                        Translation.tr("Any"),
                        "16x9", "16x10", "21x9", "32x9",
                        "9x16", "10x16",
                        "1x1", "3x2", "4x3", "5x4",
                    ]
                    property var ratioKeys: ["", "16x9", "16x10", "21x9", "32x9", "9x16", "10x16", "1x1", "3x2", "4x3", "5x4"]
                    currentIndex: Math.max(0, ratioKeys.indexOf(OnlineWallpapers.wallhavenRatios))
                    onActivated: index => {
                        OnlineWallpapers.wallhavenRatios = ratioKeys[index]
                        root.dirty = true
                    }
                }
            }
        }

        // Right column: toggles and API key
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                StyledText {
                    text: Translation.tr("Categories")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: [
                            { label: Translation.tr("General"), bit: 0 },
                            { label: Translation.tr("Anime"), bit: 1 },
                            { label: Translation.tr("People"), bit: 2 }
                        ]
                        delegate: RippleButton {
                            required property var modelData
                            implicitHeight: 32
                            buttonRadius: height / 2
                            leftPadding: 14
                            rightPadding: 14
                            toggled: OnlineWallpapers.wallhavenCategories.charAt(modelData.bit) === "1"
                            colBackground: Appearance.colors.colLayer1
                            colBackgroundToggled: Appearance.colors.colPrimary
                            onClicked: {
                                const cats = OnlineWallpapers.wallhavenCategories
                                const flipped = cats.charAt(modelData.bit) === "1" ? "0" : "1"
                                OnlineWallpapers.wallhavenCategories = cats.substring(0, modelData.bit) + flipped + cats.substring(modelData.bit + 1)
                                root.dirty = true
                            }
                            contentItem: StyledText {
                                text: modelData.label
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: parent.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                StyledText {
                    text: Translation.tr("Purity")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: [
                            { label: Translation.tr("SFW"), bit: 0, needsKey: false },
                            { label: Translation.tr("Sketchy"), bit: 1, needsKey: false },
                            { label: Translation.tr("NSFW"), bit: 2, needsKey: true }
                        ]
                        delegate: RippleButton {
                            required property var modelData
                            visible: !modelData.needsKey || OnlineWallpapers.wallhavenApiKey.length > 0
                            implicitHeight: 32
                            buttonRadius: height / 2
                            leftPadding: 14
                            rightPadding: 14
                            toggled: OnlineWallpapers.wallhavenPurity.charAt(modelData.bit) === "1"
                            colBackground: Appearance.colors.colLayer1
                            colBackgroundToggled: modelData.needsKey ? Appearance.m3colors.m3error : Appearance.colors.colPrimary
                            onClicked: {
                                const p = OnlineWallpapers.wallhavenPurity
                                const flipped = p.charAt(modelData.bit) === "1" ? "0" : "1"
                                OnlineWallpapers.wallhavenPurity = p.substring(0, modelData.bit) + flipped + p.substring(modelData.bit + 1)
                                root.dirty = true
                            }
                            contentItem: StyledText {
                                text: modelData.label
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: parent.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                StyledText {
                    text: Translation.tr("API Key")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }

                TextField {
                    id: apiKeyField
                    Layout.fillWidth: true
                    echoMode: TextInput.Password
                    placeholderText: Translation.tr("Optional, needed for NSFW")
                    placeholderTextColor: Appearance.colors.colSubtext
                    color: Appearance.colors.colOnLayer1
                    clip: true
                    text: OnlineWallpapers.wallhavenApiKey
                    font {
                        family: Appearance.font.family.main
                        pixelSize: Appearance.font.pixelSize.small
                        hintingPreference: Font.PreferFullHinting
                    }
                    renderType: Text.NativeRendering
                    background: Rectangle {
                        color: Appearance.colors.colLayer1
                        radius: Appearance.rounding.small
                        border.width: 1
                        border.color: apiKeyField.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                    }
                    onEditingFinished: {
                        // Keep the keyring authoritative so the "/wallhaven <key>" launcher command stays in sync
                        KeyringStorage.setNestedField(["apiKeys", "wallhaven"], text.trim())
                        Config.options.wallpaperSelector.wallhavenApiKey = text.trim()
                    }
                }
            }
        }
    }
}
