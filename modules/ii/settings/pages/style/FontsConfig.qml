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
        icon: "text_format"
        shape: MaterialShape.Shape.Arrow
        title: Translation.tr("Fonts")

        GroupedList {
            ConfigTextArea {
                id: mainFontField
                Layout.fillWidth: true
                buttonIcon: "font_download"
                text: Translation.tr("Font family name (e.g., Google Sans Flex)")
                value: Config.options.appearance.fonts.main
                onValueChanged: {
                    mainFontDebounceTimer.restart();
                }

                Timer {
                    id: mainFontDebounceTimer
                    interval: 1000
                    running: false
                    onTriggered: {
                        Config.options.appearance.fonts.main = mainFontField.value;
                    }
                }
            }

            ConfigTextArea {
                id: numbersFontField
                Layout.fillWidth: true
                buttonIcon: "123"
                text: Translation.tr("Numbers family name")
                value: Config.options.appearance.fonts.numbers
                onValueChanged: {
                    numbersFontDebounceTimer.restart();
                }

                Timer {
                    id: numbersFontDebounceTimer
                    interval: 1000
                    running: false
                    onTriggered: {
                        Config.options.appearance.fonts.numbers = numbersFontField.value;
                    }
                }
            }

            ConfigTextArea {
                id: titleFontField
                Layout.fillWidth: true
                buttonIcon: "title"
                text: Translation.tr("Title family name")
                value: Config.options.appearance.fonts.title
                onValueChanged: {
                    titleFontDebounceTimer.restart();
                }

                Timer {
                    id: titleFontDebounceTimer
                    interval: 1000
                    running: false
                    onTriggered: {
                        Config.options.appearance.fonts.title = titleFontField.value;
                    }
                }
            }

            ConfigTextArea {
                id: monospaceFontField
                Layout.fillWidth: true
                buttonIcon: "space_bar"
                text: Translation.tr("Monospace font name (e.g., JetBrains Mono NF)")
                value: Config.options.appearance.fonts.monospace
                onValueChanged: {
                    monospaceFontDebounceTimer.restart();
                }

                Timer {
                    id: monospaceFontDebounceTimer
                    interval: 1000
                    running: false
                    onTriggered: {
                        Config.options.appearance.fonts.monospace = monospaceFontField.value;
                    }
                }
            }

            ConfigTextArea {
                id: iconNerdFontField
                Layout.fillWidth: true
                buttonIcon: "emoticon"
                text: Translation.tr("Nerd Fonts Icons (e.g., JetBrains Mono NF)")
                value: Config.options.appearance.fonts.iconNerd
                onValueChanged: {
                    iconNerdFontDebounceTimer.restart();
                }

                Timer {
                    id: iconNerdFontDebounceTimer
                    interval: 1000
                    running: false
                    onTriggered: {
                        Config.options.appearance.fonts.iconNerd = iconNerdFontField.value;
                    }
                }
            }

            ConfigTextArea {
                id: readingFontField
                Layout.fillWidth: true
                buttonIcon: "book_ribbon"
                text: Translation.tr("Reading font name (e.g., Readex Pro)")
                value: Config.options.appearance.fonts.reading
                onValueChanged: {
                    readingFontDebounceTimer.restart();
                }

                Timer {
                    id: readingFontDebounceTimer
                    interval: 1000
                    running: false
                    onTriggered: {
                        Config.options.appearance.fonts.reading = readingFontField.value;
                    }
                }
            }

            ConfigTextArea {
                id: expressiveFontField
                Layout.fillWidth: true
                buttonIcon: "mood_heart"
                text: Translation.tr("Expressive font name (e.g., Space Grotesk)")
                value: Config.options.appearance.fonts.expressive
                onValueChanged: {
                    expressiveFontDebounceTimer.restart();
                }

                Timer {
                    id: expressiveFontDebounceTimer
                    interval: 1000
                    running: false
                    onTriggered: {
                        Config.options.appearance.fonts.expressive = expressiveFontField.value;
                    }
                }
            }
        }
    }
}
