import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

SettingRow {
    id: root

    property string value: ""
    property string pickerType: "file" // "file", "folder", "font", "app"
    property string placeholder: Translation.tr("Choose...")
    signal picked(string val)
    signal requestPicker()

    currentValue: root.value

    onResetRequested: {
        if (defaultValue !== undefined) {
            root.value = String(defaultValue)
            root.picked(root.value)
        }
    }

    RippleButton {
        Layout.preferredHeight: 36
        Layout.preferredWidth: Math.min(220, Math.max(100, pickerRow.implicitWidth + 24))
        Layout.alignment: Qt.AlignVCenter
        buttonRadius: Appearance.rounding.small
        colBackground: Appearance.colors.colLayer2
        colBackgroundHover: Appearance.colors.colLayer2Hover

        onClicked: root.requestPicker()

        contentItem: RowLayout {
            id: pickerRow
            anchors.centerIn: parent
            spacing: 6

            MaterialSymbol {
                text: root.pickerType === "folder" ? "folder_open"
                    : root.pickerType === "font" ? "font_download"
                    : root.pickerType === "app" ? "apps"
                    : "attach_file"
                iconSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer2
            }

            StyledText {
                text: root.value !== "" ? root.value.split("/").pop() : root.placeholder
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: root.value !== "" ? Appearance.colors.colOnLayer2 : Appearance.colors.colSubtext
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }
        }
    }
}
