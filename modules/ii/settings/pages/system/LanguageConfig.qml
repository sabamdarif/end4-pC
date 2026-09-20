import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    ContentSection {
        icon: "language_japanese_kana"
        shape: MaterialShape.Shape.Gem
        title: Translation.tr("Language")

        GroupedList {
            ConfigComboBox {
                Layout.fillWidth: true
                buttonIcon: "language"
                text: Translation.tr("Interface Language")
                fieldWidth: 240
                model: [
                    { displayName: Translation.tr("Auto (System)"), value: "auto" },
                    ...Translation.allAvailableLanguages.map(lang => ({ displayName: lang, value: lang }))
                ]
                currentValue: Config.options.language.ui
                onSelected: newValue => {
                    Config.options.language.ui = newValue;
                }
            }
        }
    }
}
