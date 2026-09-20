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
}
