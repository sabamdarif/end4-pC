import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    Process {
        id: translationProc
        property string locale: ""
        command: [Directories.aiTranslationScriptPath, translationProc.locale]
    }

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

            ColumnLayout {
                id: translationCol
                anchors { fill: parent; margins: 0 }
                spacing: 8

                ConfigTextArea {
                    id: localeField
                    Layout.fillWidth: true
                    buttonIcon: "translate"
                    text: Translation.tr("Locale code")
                    placeholderText: Translation.tr("e.g. fr_FR, de_DE, zh_CN...")
                    value: Config.options.language.ui === "auto" ? Qt.locale().name : Config.options.language.ui
                }

                RippleButtonWithIcon {
                    id: generateTranslationBtn
                    Layout.fillWidth: false
                    Layout.alignment: Qt.AlignRight
                    Layout.preferredHeight: 50
                    Layout.rightMargin: 8
                    nerdIcon: ""
                    enabled: !translationProc.running || (translationProc.locale !== localeField.value.trim())
                    mainText: enabled ? Translation.tr("Generate\nTypically takes 2 minutes") : Translation.tr("Generating...\nDon't close this window!")
                    onClicked: {
                        translationProc.locale = localeField.value.trim();
                        translationProc.running = false;
                        translationProc.running = true;
                    }
                }
            }
        }
    }
}
