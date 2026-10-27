pragma Singleton

import Quickshell
import QtQml.Models
import QtQuick

// From https://github.com/pctrade/end4-pC/pull/147 by @SDcold
Singleton {
    id: root

    // Bundled in assets/fonts/handwriting, used by the desktop text widget
    readonly property list<string> handwritingFamilies: ["Caveat", "Dancing Script", "Pacifico", "Indie Flower", "Great Vibes", "Permanent Marker", "Patrick Hand", "Kalam"]

    Instantiator {
        model: ["Caveat", "DancingScript", "Pacifico", "IndieFlower", "GreatVibes", "PermanentMarker", "PatrickHand", "Kalam"]
        delegate: FontLoader {
            required property string modelData
            source: Qt.resolvedUrl(`${Quickshell.shellPath("assets/fonts/handwriting")}/${modelData}.ttf`)
        }
    }

    property var installedFamilies: {
        const families = Qt.fontFamilies();
        const set = new Set(families);
        return Array.from(set).sort((a, b) => a.localeCompare(b));
    }

    property var installedFontModel: {
        return (installedFamilies ?? []).map(f => ({ displayName: f, value: f }));
    }

    function refreshFamilies() {
        const families = Qt.fontFamilies();
        const set = new Set(families);
        installedFamilies = Array.from(set).sort((a, b) => a.localeCompare(b));
        installedFontModel = installedFamilies.map(f => ({ displayName: f, value: f }));
    }

    function fontModelFor(currentFont) {
        if (!currentFont || currentFont.length === 0 || (installedFamilies && installedFamilies.includes(currentFont))) {
            return installedFontModel;
        }
        return [{ displayName: currentFont, value: currentFont }].concat(installedFontModel);
    }
}
