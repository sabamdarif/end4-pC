import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true
    bottomContentPadding: 15

    ContentSection {
        icon: "search"
        shape: MaterialShape.Shape.Cookie6Sided
        title: Translation.tr("Search")

        GroupedList {
            ConfigSwitch {
                text: Translation.tr("Use Levenshtein distance-based algorithm instead of fuzzy")
                checked: Config.options.search.sloppy
                onCheckedChanged: {
                    Config.options.search.sloppy = checked;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Prefixes")

            GroupedList {
                ConfigRow {
                    uniform: true
                    ConfigTextArea {
                        Layout.fillWidth: true
                        buttonIcon: "bolt"
                        fieldWidth: 100
                        text: Translation.tr("Action")
                        value: Config.options.search.prefix.action
                        onValueChanged: {
                            Config.options.search.prefix.action = value;
                        }
                    }
                    ConfigTextArea {
                        Layout.fillWidth: true
                        buttonIcon: "mood"
                        fieldWidth: 100
                        text: Translation.tr("Emojis")
                        value: Config.options.search.prefix.emojis
                        onValueChanged: {
                            Config.options.search.prefix.emojis = value;
                        }
                    }
                    ConfigTextArea {
                        Layout.fillWidth: true
                        buttonIcon: "emoji_symbols"
                        fieldWidth: 100
                        text: Translation.tr("Icons")
                        value: Config.options.search.prefix.symbols
                        onValueChanged: {
                            Config.options.search.prefix.symbols = value;
                        }
                    }
                }

                ConfigRow {
                    uniform: true
                    ConfigTextArea {
                        Layout.fillWidth: true
                        buttonIcon: "terminal"
                        fieldWidth: 100
                        text: Translation.tr("Shell command")
                        value: Config.options.search.prefix.shellCommand
                        onValueChanged: {
                            Config.options.search.prefix.shellCommand = value;
                        }
                    }
                    ConfigTextArea {
                        Layout.fillWidth: true
                        fieldWidth: 100
                        buttonIcon: "travel_explore"
                        text: Translation.tr("Web search")
                        value: Config.options.search.prefix.webSearch
                        onValueChanged: {
                            Config.options.search.prefix.webSearch = value;
                        }
                    }
                }

                ConfigRow {
                    uniform: true
                    ConfigTextArea {
                        Layout.fillWidth: true
                        buttonIcon: "apps"
                        fieldWidth: 100
                        text: Translation.tr("Apps")
                        value: Config.options.search.prefix.app
                        onValueChanged: {
                            Config.options.search.prefix.app = value;
                        }
                    }
                    ConfigTextArea {
                        Layout.fillWidth: true
                        buttonIcon: "keyboard_command_key"
                        fieldWidth: 100
                        text: Translation.tr("Keybinds")
                        value: Config.options.search.prefix.keybinds
                        onValueChanged: {
                            Config.options.search.prefix.keybinds = value;
                        }
                    }
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Web search")

            GroupedList {
                ConfigTextArea {
                    id: baseUrlField
                    Layout.fillWidth: true
                    fieldWidth: 320
                    buttonIcon: "travel_explore"
                    text: Translation.tr("Base URL")
                    value: Config.options.search.engineBaseUrl
                    onValueChanged: {
                        baseUrlDebounceTimer.restart();
                    }

                    Timer {
                        id: baseUrlDebounceTimer
                        interval: 600
                        repeat: false
                        onTriggered: {
                            Config.options.search.engineBaseUrl = baseUrlField.value;
                        }
                    }
                }
            }
        }
    }
}
