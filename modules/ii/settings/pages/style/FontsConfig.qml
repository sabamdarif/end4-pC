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
            ConfigComboBox {
                buttonIcon: "font_download"
                text: Translation.tr("Font family name")
                searchable: true
                previewFont: true
                model: Fonts.fontModelFor(Config.options.appearance.fonts.main)
                currentValue: Config.options.appearance.fonts.main
                onSelected: newValue => {
                    Config.options.appearance.fonts.main = newValue;
                }
            }

            ConfigComboBox {
                buttonIcon: "123"
                text: Translation.tr("Numbers family name")
                searchable: true
                previewFont: true
                model: Fonts.fontModelFor(Config.options.appearance.fonts.numbers)
                currentValue: Config.options.appearance.fonts.numbers
                onSelected: newValue => {
                    Config.options.appearance.fonts.numbers = newValue;
                }
            }

            ConfigComboBox {
                buttonIcon: "title"
                text: Translation.tr("Title family name")
                searchable: true
                previewFont: true
                model: Fonts.fontModelFor(Config.options.appearance.fonts.title)
                currentValue: Config.options.appearance.fonts.title
                onSelected: newValue => {
                    Config.options.appearance.fonts.title = newValue;
                }
            }

            ConfigComboBox {
                buttonIcon: "space_bar"
                text: Translation.tr("Monospace font name")
                searchable: true
                previewFont: true
                model: Fonts.fontModelFor(Config.options.appearance.fonts.monospace)
                currentValue: Config.options.appearance.fonts.monospace
                onSelected: newValue => {
                    Config.options.appearance.fonts.monospace = newValue;
                }
            }

            ConfigComboBox {
                buttonIcon: "emoticon"
                text: Translation.tr("Nerd Fonts Icons")
                searchable: true
                previewFont: true
                model: Fonts.fontModelFor(Config.options.appearance.fonts.iconNerd)
                currentValue: Config.options.appearance.fonts.iconNerd
                onSelected: newValue => {
                    Config.options.appearance.fonts.iconNerd = newValue;
                }
            }

            ConfigComboBox {
                buttonIcon: "book_ribbon"
                text: Translation.tr("Reading font name")
                searchable: true
                previewFont: true
                model: Fonts.fontModelFor(Config.options.appearance.fonts.reading)
                currentValue: Config.options.appearance.fonts.reading
                onSelected: newValue => {
                    Config.options.appearance.fonts.reading = newValue;
                }
            }

            ConfigComboBox {
                buttonIcon: "mood_heart"
                text: Translation.tr("Expressive font name")
                searchable: true
                previewFont: true
                model: Fonts.fontModelFor(Config.options.appearance.fonts.expressive)
                currentValue: Config.options.appearance.fonts.expressive
                onSelected: newValue => {
                    Config.options.appearance.fonts.expressive = newValue;
                }
            }
        }
    }
}
