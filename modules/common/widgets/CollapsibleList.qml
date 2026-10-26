import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ColumnLayout {
    id: root

    property var items: []
    property Component delegate: null
    property int initialVisibleCount: 5
    property bool expanded: false
    property string filterText: ""
    property string filterProperty: "title"

    Layout.fillWidth: true
    spacing: 4

    readonly property var filteredItems: {
        let list = Array.isArray(root.items) ? root.items : []
        const query = root.filterText.toLowerCase().trim()
        if (query === "") return list
        return list.filter(item => {
            if (typeof item === "string") return item.toLowerCase().includes(query)
            if (item && typeof item === "object") {
                let val = item[root.filterProperty] ?? item.name ?? item.title ?? ""
                return String(val).toLowerCase().includes(query)
            }
            return false
        })
    }

    readonly property int visibleCount: root.expanded ? filteredItems.length : Math.min(filteredItems.length, root.initialVisibleCount)
    readonly property int remainingCount: Math.max(0, filteredItems.length - root.initialVisibleCount)

    // Filter box, shown only if total list exceeds 10 items
    Rectangle {
        visible: (root.items ? root.items.length : 0) > 10
        Layout.fillWidth: true
        Layout.preferredHeight: 38
        radius: Appearance.rounding.small
        color: Appearance.colors.colLayer2

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            MaterialSymbol {
                text: "search"
                iconSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
            }

            StyledTextInput {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Filter list...")
                color: Appearance.colors.colOnLayer2
                font.pixelSize: Appearance.font.pixelSize.smaller
                onTextChanged: root.filterText = text
            }

            RippleButton {
                visible: root.filterText !== ""
                implicitWidth: 24
                implicitHeight: 24
                buttonRadius: Appearance.rounding.full
                colBackground: "transparent"
                onClicked: root.filterText = ""
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "close"
                    iconSize: 14
                    color: Appearance.colors.colSubtext
                }
            }
        }
    }

    // List items
    Repeater {
        model: root.visibleCount
        delegate: Loader {
            required property int index
            Layout.fillWidth: true
            sourceComponent: root.delegate
            property var modelData: root.filteredItems[index]
            property int itemIndex: index
        }
    }

    // "Show N more" button
    RippleButton {
        visible: !root.expanded && root.remainingCount > 0
        Layout.fillWidth: true
        implicitHeight: 36
        buttonRadius: Appearance.rounding.small
        colBackground: Appearance.colors.colLayer2
        colBackgroundHover: Appearance.colors.colLayer2Hover

        onClicked: root.expanded = true

        contentItem: RowLayout {
            anchors.centerIn: parent
            spacing: 6

            StyledText {
                text: Translation.tr("Show %1 more").arg(root.remainingCount)
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.Medium
                color: Appearance.colors.colPrimary
            }

            MaterialSymbol {
                text: "expand_more"
                iconSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colPrimary
            }
        }
    }

    // "Show fewer" button
    RippleButton {
        visible: root.expanded && (root.filteredItems.length > root.initialVisibleCount)
        Layout.fillWidth: true
        implicitHeight: 36
        buttonRadius: Appearance.rounding.small
        colBackground: Appearance.colors.colLayer2
        colBackgroundHover: Appearance.colors.colLayer2Hover

        onClicked: root.expanded = false

        contentItem: RowLayout {
            anchors.centerIn: parent
            spacing: 6

            StyledText {
                text: Translation.tr("Show fewer")
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.Medium
                color: Appearance.colors.colPrimary
            }

            MaterialSymbol {
                text: "expand_less"
                iconSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colPrimary
            }
        }
    }
}
