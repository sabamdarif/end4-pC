import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ColumnLayout {
    id: root

    property string rowId: ""
    property string pageKey: ""
    property string sectionTitle: ""
    property string label: ""
    property string subtitle: ""
    property string icon: ""
    property string unit: ""
    property var keywords: []
    property bool requiresRestart: false
    property bool requiresRelogin: false
    property var defaultValue: undefined
    property string wipFeature: ""

    property real value: 0
    property real offValue: 0
    property real defaultOnValue: 10
    property real from: 1
    property real to: 100
    property real stepSize: 1
    property string revealerType: "slider" // "slider" or "spin"

    readonly property bool isOn: value !== offValue

    signal valueModified(real val)

    Layout.fillWidth: true
    spacing: 0

    SettingSwitchRow {
        id: switchRow
        rowId: root.rowId
        pageKey: root.pageKey
        sectionTitle: root.sectionTitle
        label: root.label
        subtitle: root.subtitle
        icon: root.icon
        keywords: root.keywords
        requiresRestart: root.requiresRestart
        requiresRelogin: root.requiresRelogin
        wipFeature: root.wipFeature
        checked: root.isOn

        onToggled: (checked) => {
            if (checked) {
                root.value = root.defaultOnValue
            } else {
                root.value = root.offValue
            }
            root.valueModified(root.value)
        }
    }

    // Revealer container for value control
    Item {
        id: revealerArea
        Layout.fillWidth: true
        Layout.leftMargin: 36
        Layout.rightMargin: 12
        implicitHeight: root.isOn ? 44 : 0
        visible: height > 0
        clip: true

        Behavior on implicitHeight {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 12

            StyledText {
                text: Translation.tr("Value")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }

            StyledSlider {
                visible: root.revealerType === "slider"
                Layout.fillWidth: true
                from: root.from
                to: root.to
                stepSize: root.stepSize
                value: root.isOn ? root.value : root.defaultOnValue
                onMoved: {
                    root.value = value
                    root.valueModified(value)
                }
            }

            StyledSpinBox {
                visible: root.revealerType === "spin"
                from: root.from
                to: root.to
                stepSize: root.stepSize
                value: root.isOn ? root.value : root.defaultOnValue
                onValueModified: {
                    root.value = value
                    root.valueModified(value)
                }
            }

            StyledText {
                text: `${Math.round(root.value)}${root.unit !== "" ? " " + root.unit : ""}`
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.family: Appearance.font.family.numbers
                color: Appearance.colors.colOnLayer1
            }
        }
    }
}
