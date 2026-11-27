pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root
    required property var bindData
    property string categoryLabel: ""
    property bool firstInGroup: false
    property bool lastInGroup: false
    readonly property bool compact: width < 540
    signal editRequested(int keyIndex)
    signal removeRequested(string key)

    implicitHeight: (compact ? description.implicitHeight + keysColumn.implicitHeight + 12
        : Math.max(description.implicitHeight, keysColumn.implicitHeight)) + 28
    color: Appearance.colors.colLayer1
    topLeftRadius: firstInGroup ? Appearance.rounding.normal : Appearance.rounding.unsharpen
    topRightRadius: topLeftRadius
    bottomLeftRadius: lastInGroup ? Appearance.rounding.normal : Appearance.rounding.unsharpen
    bottomRightRadius: bottomLeftRadius

    ColumnLayout {
        id: description
        x: 16
        y: root.compact ? 14 : (root.height - height) / 2
        width: root.compact ? root.width - 32 : Math.max(80, root.width - keysColumn.width - 48)
        spacing: 4
        StyledText {
            Layout.fillWidth: true
            text: root.bindData.title || root.bindData.action
            font.weight: Font.Medium
            elide: Text.ElideRight
        }
        StyledText {
            Layout.fillWidth: true
            text: [root.categoryLabel,
                root.bindData.keys.some(k => k.overriddenByConfig) ? Translation.tr("Overridden by config")
                : root.bindData.keys.some(k => k.isOverride) ? Translation.tr("Override") : ""].filter(Boolean).join(" · ")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            elide: Text.ElideRight
        }
    }

    Column {
        id: keysColumn
        x: root.width - width - 16
        y: root.compact ? description.y + description.height + 12 : (root.height - height) / 2
        spacing: 6
        Repeater {
            model: root.bindData.keys
            delegate: RowLayout {
                id: keyLine
                required property var modelData
                required property int index
                anchors.right: parent?.right
                spacing: 8
                KeyboardKey {
                    key: keyLine.modelData.key
                    Layout.maximumWidth: Math.max(80, root.width - 144)
                }
                RippleButton {
                    implicitWidth: 32
                    implicitHeight: 32
                    buttonRadius: height / 2
                    colBackground: "transparent"
                    Accessible.name: Translation.tr("Edit shortcut")
                    Accessible.description: root.bindData.title + ", " + keyLine.modelData.key
                    contentItem: MaterialSymbol { text: "edit"; iconSize: 20; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    onClicked: root.editRequested(keyLine.index)
                    StyledToolTip { text: keyLine.modelData.source }
                }
                Item {
                    implicitWidth: 32
                    implicitHeight: 32
                    RippleButton {
                        anchors.fill: parent
                        visible: keyLine.modelData.isOverride
                        enabled: !NiriConfig.savingBind
                        buttonRadius: height / 2
                        colBackground: "transparent"
                        Accessible.name: Translation.tr("Remove shortcut")
                        Accessible.description: root.bindData.title + ", " + keyLine.modelData.key
                        contentItem: MaterialSymbol { text: "delete"; color: Appearance.m3colors.m3error; iconSize: 20; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        onClicked: root.removeRequested(keyLine.modelData.key)
                    }
                }
            }
        }
    }
}
