import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

/**
 * The sidebar's sheet layout: title, optional subtitle, a body that fills the rest,
 * and a footer ending in a Done button. Every sheet keeps the same height so they all
 * open in the same spot, and WindowDialog freezes that height when it opens, so the
 * body has to fit it.
 */
WindowDialog {
    id: root

    property string title: ""
    property string subtitle: ""
    // Replaces the rule under the title with a progress bar, for scans and discovery
    property bool busy: false
    // Lists and rows look right only when they reach the sheet edges; forms keep the padding
    property bool edgeToEdge: false
    // Settings page to deep link to from a Details button, e.g. "wifi"
    property string settingsPage: ""
    property bool showDoneButton: true

    default property alias content: bodyColumn.data
    property alias leadingActions: leadingRow.data
    property alias trailingActions: trailingRow.data

    backgroundHeight: 600

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        WindowDialogTitle {
            Layout.fillWidth: true
            text: root.title
        }

        WindowDialogParagraph {
            visible: root.subtitle !== ""
            Layout.fillWidth: true
            text: root.subtitle
        }
    }

    WindowDialogSeparator {
        visible: !root.busy
    }

    StyledIndeterminateProgressBar {
        visible: root.busy
        Layout.fillWidth: true
        Layout.topMargin: -8
        Layout.bottomMargin: -8
        Layout.leftMargin: -Appearance.rounding.large
        Layout.rightMargin: -Appearance.rounding.large
    }

    ColumnLayout {
        id: bodyColumn
        Layout.fillWidth: true
        Layout.fillHeight: true
        // A nested layout inherits its children's maximum height, which would stop the
        // body from taking the sheet's spare space and leave it spread between rows
        Layout.maximumHeight: Number.POSITIVE_INFINITY
        Layout.topMargin: root.edgeToEdge ? -15 : 0
        Layout.bottomMargin: root.edgeToEdge ? -16 : 0
        Layout.leftMargin: root.edgeToEdge ? -Appearance.rounding.large : 0
        Layout.rightMargin: root.edgeToEdge ? -Appearance.rounding.large : 0
        spacing: 16
    }

    WindowDialogSeparator {}

    WindowDialogButtonRow {
        Layout.fillWidth: true

        DialogButton {
            visible: root.settingsPage !== ""
            buttonText: Translation.tr("Details")
            onClicked: {
                root.dismiss();
                GlobalStates.sidebarRightOpen = false;
                GlobalStates.settingsOpen = true;
                Qt.callLater(() => GlobalStates.settingsPage = root.settingsPage);
            }
        }

        RowLayout {
            id: leadingRow
            spacing: 4
        }

        Item {
            Layout.fillWidth: true
        }

        RowLayout {
            id: trailingRow
            spacing: 4
        }

        DialogButton {
            visible: root.showDoneButton
            buttonText: Translation.tr("Done")
            onClicked: root.dismiss()
        }
    }
}
