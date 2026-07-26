pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    property string searchText: ""
    property int selectedIndex: 0
    property int pinnedCount: 0

    // Blur image previews when a work-unsafe link sits next to them in the history
    // and the machine is on a network the user marked as sensitive.
    readonly property bool workSafetyActive: {
        const enabled = Config.options.workSafety.enable.clipboard;
        const sensitiveNetwork = StringUtils.stringListContainsSubstring(Network.networkName.toLowerCase(), Config.options.workSafety.triggerCondition.networkNameKeywords);
        return enabled && sensitiveNetwork;
    }

    function containsUnsafeLink(entry) {
        if (entry === undefined || entry === null)
            return false;
        return StringUtils.stringListContainsSubstring(String(entry).toLowerCase(), Config.options.workSafety.triggerCondition.linkKeywords);
    }

    /**
     * Flat row list: pinned entries first, then the rest of the cliphist history.
     * A pin whose cliphist entry has been evicted still shows up, backed by its own
     * decoded copy on disk.
     */
    property var rows: {
        const query = root.searchText.trim();
        const entries = query === "" ? Cliphist.entries : Cliphist.fuzzyQuery(query);
        const pinnedRows = [];
        const recentRows = [];
        const seenPins = ({});

        for (let i = 0; i < entries.length; i++) {
            const entry = entries[i];
            const pin = ClipboardPins.pinFor(entry);
            const isImage = Cliphist.entryIsImage(entry);
            const row = {
                entry: entry,
                pin: pin,
                pinned: pin !== null,
                label: StringUtils.cleanCliphistEntry(entry),
                isImage: isImage,
                blur: isImage && root.workSafetyActive && (root.containsUnsafeLink(entries[i - 1]) || root.containsUnsafeLink(entries[i + 1])),
                id: ClipboardPins.entryId(entry)
            };
            if (pin) {
                seenPins[pin.key] = true;
                pinnedRows.push(row);
            } else {
                recentRows.push(row);
            }
        }

        const lowerQuery = query.toLowerCase();
        const pins = ClipboardPins.pins;
        for (let i = 0; i < pins.length; i++) {
            const pin = pins[i];
            if (seenPins[pin.key])
                continue;
            if (query !== "" && !String(pin.label).toLowerCase().includes(lowerQuery))
                continue;
            pinnedRows.push({
                entry: "",
                pin: pin,
                pinned: true,
                label: pin.label,
                isImage: pin.isImage,
                blur: pin.isImage && root.workSafetyActive,
                id: pin.id
            });
        }

        root.pinnedCount = pinnedRows.length;
        return pinnedRows.concat(recentRows);
    }

    onRowsChanged: {
        if (root.selectedIndex >= root.rows.length)
            root.selectedIndex = Math.max(0, root.rows.length - 1);
    }

    function reset() {
        searchField.text = "";
        root.searchText = "";
        root.selectedIndex = 0;
        listView.positionViewAtBeginning();
        searchField.forceActiveFocus();
    }

    function moveSelection(delta) {
        if (root.rows.length === 0)
            return;
        root.selectedIndex = Math.max(0, Math.min(root.rows.length - 1, root.selectedIndex + delta));
        listView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
    }

    function copyRow(row) {
        if (!row)
            return;
        if (row.entry !== "")
            Cliphist.copy(row.entry);
        else
            ClipboardPins.copy(row.pin);
        if (Config.options.clipboard.closeOnCopy)
            GlobalStates.clipboardOpen = false;
    }

    function deleteRow(row) {
        if (!row)
            return;
        if (row.pin)
            ClipboardPins.remove(row.pin.key);
        if (row.entry !== "")
            Cliphist.deleteEntry(row.entry);
    }

    function togglePinRow(row) {
        if (!row)
            return;
        if (row.pin)
            ClipboardPins.remove(row.pin.key);
        else
            ClipboardPins.pin(row.entry);
    }

    function activateSelected() {
        root.copyRow(root.rows[root.selectedIndex]);
    }

    StyledRectangularShadow {
        target: card
    }

    Rectangle {
        id: card
        anchors {
            fill: parent
            margins: Appearance.sizes.elevationMargin
        }
        color: Appearance.colors.colLayer0
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        radius: Appearance.rounding.screenRounding + 5

        ColumnLayout {
            anchors {
                fill: parent
                margins: 14
            }
            spacing: 10

            RowLayout { // Header
                Layout.fillWidth: true
                spacing: 8

                MaterialShapeWrappedMaterialSymbol {
                    iconSize: 22
                    padding: 7
                    shape: MaterialShape.Shape.Cookie4Sided
                    color: Appearance.colors.colSecondaryContainer
                    colSymbol: Appearance.colors.colOnSecondaryContainer
                    text: "content_paste"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        text: Translation.tr("Clipboard")
                        font {
                            family: Appearance.font.family.title
                            pixelSize: Appearance.font.pixelSize.large
                            variableAxes: Appearance.font.variableAxes.title
                        }
                        color: Appearance.colors.colOnLayer0
                    }
                    StyledText {
                        text: root.pinnedCount > 0 ? Translation.tr("%1 entries · %2 pinned").arg(root.rows.length).arg(root.pinnedCount) : Translation.tr("%1 entries").arg(root.rows.length)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }

                RippleButton { // Clear all
                    id: clearButton
                    property bool confirming: false
                    implicitWidth: 40
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.full
                    visible: !clearButton.confirming

                    onClicked: clearButton.confirming = true

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "delete_sweep"
                        iconSize: 20
                        color: Appearance.colors.colOnLayer0
                    }

                    StyledToolTip {
                        text: Translation.tr("Clear history")
                    }
                }

                DialogButton {
                    visible: clearButton.confirming
                    buttonText: Translation.tr("Clear it all?")
                    colText: Appearance.m3colors.m3error
                    onClicked: {
                        clearButton.confirming = false;
                        Cliphist.wipe();
                    }
                }

                DialogButton {
                    visible: clearButton.confirming
                    buttonText: Translation.tr("Cancel")
                    onClicked: clearButton.confirming = false
                }

                RippleButton { // Close
                    implicitWidth: 40
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.full
                    onClicked: GlobalStates.clipboardOpen = false

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "close"
                        iconSize: 20
                        color: Appearance.colors.colOnLayer0
                    }
                }
            }

            Rectangle { // Search
                Layout.fillWidth: true
                implicitHeight: 46
                radius: Appearance.rounding.full
                color: Appearance.colors.colLayer1
                border.width: searchField.activeFocus ? 2 : 1
                border.color: searchField.activeFocus ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colOutline, 0.4)

                Behavior on border.color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 14
                        rightMargin: 8
                    }
                    spacing: 6

                    MaterialSymbol {
                        text: "search"
                        iconSize: 20
                        color: Appearance.colors.colSubtext
                    }

                    ToolbarTextField {
                        id: searchField
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        colBackground: "transparent"
                        focus: true
                        font.pixelSize: Appearance.font.pixelSize.normal
                        placeholderText: Translation.tr("Search clipboard...")

                        onTextChanged: {
                            root.searchText = text;
                            root.selectedIndex = 0;
                            listView.positionViewAtBeginning();
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                GlobalStates.clipboardOpen = false;
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down) {
                                root.moveSelection(1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up) {
                                root.moveSelection(-1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_PageDown) {
                                root.moveSelection(6);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_PageUp) {
                                root.moveSelection(-6);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.activateSelected();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Delete && (event.modifiers & Qt.ShiftModifier)) {
                                root.deleteRow(root.rows[root.selectedIndex]);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_P && (event.modifiers & Qt.ControlModifier)) {
                                root.togglePinRow(root.rows[root.selectedIndex]);
                                event.accepted = true;
                            }
                        }
                    }

                    RippleButton {
                        visible: searchField.text !== ""
                        implicitWidth: 32
                        implicitHeight: 32
                        buttonRadius: Appearance.rounding.full
                        onClicked: {
                            searchField.text = "";
                            searchField.forceActiveFocus();
                        }

                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "close"
                            iconSize: 18
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }

            Item { // List
                Layout.fillWidth: true
                Layout.fillHeight: true

                StyledListView {
                    id: listView
                    anchors.fill: parent
                    clip: true
                    spacing: 4
                    visible: root.rows.length > 0
                    model: root.rows

                    delegate: ClipboardEntryItem {
                        required property var modelData
                        required property int index

                        width: listView.width
                        row: modelData
                        itemIndex: index
                        selected: index === root.selectedIndex
                        sectionLabel: {
                            if (root.pinnedCount === 0)
                                return "";
                            if (index === 0)
                                return Translation.tr("Pinned");
                            if (index === root.pinnedCount)
                                return Translation.tr("Recent");
                            return "";
                        }

                        onSelectRequested: root.selectedIndex = index
                        onCopyRequested: root.copyRow(modelData)
                        onDeleteRequested: root.deleteRow(modelData)
                        onPinRequested: root.togglePinRow(modelData)
                    }
                }

                PagePlaceholder {
                    shown: root.rows.length === 0
                    icon: root.searchText === "" ? "content_paste_off" : "search_off"
                    title: root.searchText === "" ? Translation.tr("Nothing copied yet") : Translation.tr("No matches")
                    description: root.searchText === "" ? Translation.tr("Copy something and it'll show up here") : Translation.tr("Try a different search")
                    descriptionHorizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
