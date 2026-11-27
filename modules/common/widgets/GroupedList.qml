import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    default property list<Item> items
    property real bigRadius: Appearance.rounding.normal
    property real smallRadius: Appearance.rounding.unsharpenmore
    property color bgcolor: Appearance.colors.colLayer1
    property real itemVerticalPadding: 24
    property bool glass: false
    Layout.fillWidth: true
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        anchors.fill: parent
        spacing: 0

        Repeater {
            model: root.items.length
            delegate: Rectangle {
                id: cardWrapper
                required property int index
                readonly property Item childItem: root?.items?.[index] ?? null
                // Never bind cardWrapper.visible to childItem.visible because
                // childItem is reparented under cardWrapper (circular in QML).
                readonly property bool childVisible: !(root?.visible) || (childItem?.visible ?? true)
                readonly property bool isFirst: {
                    const items = root?.items ?? [];
                    for (let i = 0; i < index; i++) {
                        if (items[i]?.visible ?? true)
                            return false;
                    }
                    return true;
                }
                readonly property bool isLast: {
                    const items = root?.items ?? [];
                    for (let i = index + 1; i < items.length; i++) {
                        if (items[i]?.visible ?? true)
                            return false;
                    }
                    return true;
                }
                Layout.fillWidth: true
                Layout.topMargin: (!childVisible || isFirst) ? 0 : 2
                implicitHeight: childVisible ? Math.max(64, (childItem?.implicitHeight ?? 0) + (root?.itemVerticalPadding ?? 24)) : 0
                opacity: childVisible ? 1 : 0
                clip: true
                color: root?.bgcolor ?? "transparent"

                WindowGlass {
                    anchors.fill: parent
                    glassEnabled: root?.glass ?? false
                    topLeftRadius: parent.topLeftRadius
                    topRightRadius: parent.topRightRadius
                    bottomLeftRadius: parent.bottomLeftRadius
                    bottomRightRadius: parent.bottomRightRadius
                    tint: root?.bgcolor ?? "transparent"
                }
                topLeftRadius:     isFirst ? (root?.bigRadius ?? 0) : (root?.smallRadius ?? 0)
                topRightRadius:    isFirst ? (root?.bigRadius ?? 0) : (root?.smallRadius ?? 0)
                bottomLeftRadius:  isLast  ? (root?.bigRadius ?? 0) : (root?.smallRadius ?? 0)
                bottomRightRadius: isLast  ? (root?.bigRadius ?? 0) : (root?.smallRadius ?? 0)

                Behavior on implicitHeight {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on topLeftRadius {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on topRightRadius {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on bottomLeftRadius {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on bottomRightRadius {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                Component.onCompleted: {
                    if (childItem) {
                        childItem.parent = contentArea
                        childItem.Layout.fillWidth = true
                    }
                }

                ColumnLayout {
                    id: contentArea
                    anchors { fill: parent; margins: 8 }
                    spacing: 0
                }
            }
        }
    }
}