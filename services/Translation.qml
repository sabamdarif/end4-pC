pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property list<string> availableLanguages: ["en_US"]
    readonly property list<string> allAvailableLanguages: ["en_US"]

    function tr(text) {
        return text ?? "";
    }
}
