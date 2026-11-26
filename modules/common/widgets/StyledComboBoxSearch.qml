pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ComboBox {
    id: root

    property string buttonIcon: ""
    property real buttonRadius: height / 2
    property color colBackground: Appearance.colors.colSecondaryContainer
    property color colBackgroundHover: Appearance.colors.colSecondaryContainerHover
    property color colBackgroundActive: Appearance.colors.colSecondaryContainerActive
    property string searchText: ""
    property bool previewFont: false

    property int visibleCount: (root.model ?? []).filter(item => root.matchesSearch(item)).length

    function matchesSearch(item) {
        const display = typeof item === "object" && item !== null ? (item[root.textRole] ?? "") : String(item)
        return String(display).toLowerCase().includes(root.searchText.toLowerCase())
    }

    function moveSelection(step) {
        const items = root.model ?? []
        let index = listView.currentIndex
        if (index < 0 && step < 0) index = items.length
        for (index += step; index >= 0 && index < items.length; index += step) {
            if (!root.matchesSearch(items[index])) continue
            listView.currentIndex = index
            listView.positionViewAtIndex(index, ListView.Contain)
            return
        }
    }

    function acceptSelection() {
        const index = listView.currentIndex
        if (index < 0 || index >= (root.model?.length ?? 0) || !root.matchesSearch(root.model[index])) return
        root.currentIndex = index
        root.activated(index)
        root.popup.close()
    }

    implicitHeight: 40
    Layout.fillWidth: true

    background: Rectangle {
        radius: root.buttonRadius
        color: (root.down && !root.popup.visible) ? root.colBackgroundActive : root.hovered ? root.colBackgroundHover : root.colBackground

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            cursorShape: Qt.PointingHandCursor
        }
    }

    indicator: MaterialSymbol {
        x: root.width - width - 16
        y: root.height / 2 - height / 2
        text: "keyboard_arrow_down"
        iconSize: Appearance.font.pixelSize.larger
        color: Appearance.colors.colOnSecondaryContainer

        rotation: root.popup.visible ? 180 : 0
        Behavior on rotation {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }

    contentItem: Item {
        implicitWidth: buttonLayout.implicitWidth
        implicitHeight: buttonLayout.implicitHeight

        RowLayout {
            id: buttonLayout
            anchors.fill: parent
            spacing: 8
            anchors.leftMargin: 16
            anchors.rightMargin: 16

            Loader {
                Layout.alignment: Qt.AlignVCenter
                active: root.buttonIcon.length > 0 || (root.currentIndex >= 0 && typeof root.model[root.currentIndex] === 'object' && root.model[root.currentIndex]?.icon)
                visible: active
                sourceComponent: MaterialSymbol {
                    text: {
                        if (root.currentIndex >= 0 && typeof root.model[root.currentIndex] === 'object' && root.model[root.currentIndex]?.icon) {
                            return root.model[root.currentIndex].icon;
                        }
                        return root.buttonIcon;
                    }
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnSecondaryContainer
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                color: Appearance.colors.colOnSecondaryContainer
                text: root.displayText
                font.family: {
                    if (root.previewFont && root.currentIndex >= 0 && root.model && root.model[root.currentIndex]) {
                        const item = root.model[root.currentIndex];
                        return (typeof item === 'object') ? (item.value ?? item[root.textRole] ?? "") : String(item);
                    }
                    return Appearance.font.family.main;
                }
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    delegate: ItemDelegate {
        id: itemDelegate
        width: ListView.view ? ListView.view.width : root.width
        implicitHeight: visible ? 40 : 0
        visible: root.matchesSearch(itemDelegate.model)

        required property var model
        required property int index

        onClicked: {
            root.currentIndex = itemDelegate.index
            root.activated(itemDelegate.index)
            root.popup.close()
        }

        property color color: {
            if (listView.currentIndex === itemDelegate.index) {
                if (itemDelegate.down) return Appearance.colors.colSecondaryContainerActive;
                if (itemDelegate.hovered) return Appearance.colors.colSecondaryContainerHover;
                return Appearance.colors.colSecondaryContainer;
            } else {
                if (itemDelegate.down) return Appearance.colors.colLayer3Active;
                if (itemDelegate.hovered) return Appearance.colors.colLayer3Hover;
                return ColorUtils.transparentize(Appearance.colors.colLayer3);
            }
        }
        property color colText: (listView.currentIndex === itemDelegate.index) ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer3

        background: Rectangle {
            anchors.fill: parent
            radius: Appearance.rounding.small
            color: itemDelegate.color
            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                cursorShape: Qt.PointingHandCursor
            }
        }

        contentItem: RowLayout {
            spacing: 8
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            Loader {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: Appearance.font.pixelSize.larger
                active: typeof itemDelegate.model === 'object' && itemDelegate.model?.icon?.length > 0
                visible: active
                sourceComponent: Item {
                    implicitWidth: icon.implicitWidth
                    implicitHeight: Appearance.font.pixelSize.larger
                    MaterialSymbol {
                        id: icon
                        anchors.centerIn: parent
                        text: itemDelegate.model?.icon ?? ""
                        iconSize: Appearance.font.pixelSize.larger
                        color: itemDelegate.colText
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.preferredHeight: Appearance.font.pixelSize.larger
                color: itemDelegate.colText
                text: itemDelegate.model[root.textRole]
                font.family: {
                    if (root.previewFont) {
                        return itemDelegate.model?.value ?? itemDelegate.model[root.textRole] ?? Appearance.font.family.main;
                    }
                    return Appearance.font.family.main;
                }
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    popup: Popup {
        y: root.height + 4
        x: root.width - width
        width: Math.max(root.width, 300)
        clip: true
        height: Math.min(
            searchField.implicitHeight + 8 + 4 + (Math.max(visibleCount, 1) * 42) + topPadding + bottomPadding,
            340
        )
        padding: 8

        onVisibleChanged: {
            if (visible) {
                searchField.forceActiveFocus();
                listView.currentIndex = root.currentIndex;
                if (root.currentIndex >= 0) {
                    listView.positionViewAtIndex(root.currentIndex, ListView.Center);
                }
            } else {
                root.searchText = "";
                searchField.text = "";
            }
        }

        enter: Transition {
            PropertyAnimation {
                properties: "opacity"; to: 1
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
            }
        }
        exit: Transition {
            PropertyAnimation {
                properties: "opacity"; to: 0
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
            }
        }

        background: Item {
            StyledRectangularShadow { target: popupBackground }
            Rectangle {
                id: popupBackground
                anchors.fill: parent
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1Blurred
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                WindowGlass {
                    anchors.fill: parent
                    glassEnabled: (parent?.color.a ?? 0) > 0
                    cardRadius: parent?.radius ?? 0
                    tint: parent?.color ?? 'transparent'
                }
            }
        }

        contentItem: ColumnLayout {
            spacing: 4

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: searchField.implicitHeight + 8
                radius: Appearance.rounding.small
                color: Appearance.colors.colLayer2

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 6

                    MaterialSymbol {
                        Layout.leftMargin: 6
                        text: "search"
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colSubtext
                    }

                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: Translation.tr("Search...")
                        color: Appearance.colors.colOnLayer1
                        background: null
                        font.family: Appearance.font.family.main
                        font.pixelSize: Appearance.font.pixelSize.normal
                        onTextChanged: {
                            root.searchText = text
                            listView.currentIndex = (root.model ?? []).findIndex(item => root.matchesSearch(item))
                            if (listView.currentIndex >= 0)
                                listView.positionViewAtIndex(listView.currentIndex, ListView.Contain)
                        }
                        Keys.onDownPressed: root.moveSelection(1)
                        Keys.onUpPressed: root.moveSelection(-1)
                        Keys.onReturnPressed: root.acceptSelection()
                        Keys.onEnterPressed: root.acceptSelection()
                    }

                    MaterialSymbol {
                        visible: searchField.text.length > 0
                        text: "close"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colSubtext
                        Layout.rightMargin: 6
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchField.text = ""
                                searchField.forceActiveFocus()
                            }
                        }
                    }
                }
            }

            StyledText {
                visible: root.visibleCount === 0
                Layout.fillWidth: true
                Layout.margins: 12
                horizontalAlignment: Text.AlignHCenter
                color: Appearance.colors.colSubtext
                text: Translation.tr("No results")
            }

            StyledListView {
                id: listView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2
                model: root.popup.visible ? root.delegateModel : null
                currentIndex: root.highlightedIndex
            }
        }
    }
}
