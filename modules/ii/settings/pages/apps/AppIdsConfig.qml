import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ContentPage {
    id: page
    forceWidth: true

    function substitutionList() {
        return (Config.options.apps.idSubstitutions ?? []).map(e => ({
            from: e?.from ?? "",
            to: e?.to ?? ""
        }))
    }

    function addSubstitution() {
        const list = page.substitutionList()
        list.push({ from: "", to: "" })
        Config.options.apps.idSubstitutions = list
    }

    function removeSubstitution(index) {
        const list = page.substitutionList()
        list.splice(index, 1)
        Config.options.apps.idSubstitutions = list
    }

    function updateSubstitution(index, key, value) {
        const list = page.substitutionList()
        if (index < 0 || index >= list.length) return
        list[index][key] = value
        Config.options.apps.idSubstitutions = list
    }

    ContentSection {
        icon: "token"
        shape: MaterialShape.Shape.Pill
        title: Translation.tr("App ID substitutions")

        StyledText {
            Layout.leftMargin: 8
            Layout.fillWidth: true
            text: Translation.tr("Remap window app IDs for icon lookup in the bar and dock — useful when a window's app ID doesn't match its .desktop file or icon name (e.g. equibop → vesktop).")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: substitutionsCol.implicitHeight + 20
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1

            ColumnLayout {
                id: substitutionsCol
                anchors { fill: parent; margins: 10 }
                spacing: 4

                StyledText {
                    visible: (Config.options.apps.idSubstitutions ?? []).length === 0
                    Layout.leftMargin: 8
                    text: Translation.tr("No substitutions")
                    color: Appearance.colors.colSubtext
                }

                Repeater {
                    model: Config.options.apps.idSubstitutions
                    delegate: RowLayout {
                        id: subRow
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        spacing: 10

                        MaterialTextArea {
                            id: subFromArea
                            Layout.fillWidth: true
                            placeholderText: Translation.tr("App ID (e.g. equibop)")
                            text: subRow.modelData.from ?? ""
                            wrapMode: TextEdit.Wrap
                            font.pixelSize: Appearance.font.pixelSize.small

                            property bool ready: false
                            Component.onCompleted: ready = true
                            onTextChanged: {
                                if (!ready) return
                                subFromDebounce.restart()
                            }
                            Timer {
                                id: subFromDebounce
                                interval: 2000
                                onTriggered: {
                                    if (subFromArea.text !== (subRow.modelData.from ?? ""))
                                        page.updateSubstitution(subRow.index, "from", subFromArea.text)
                                }
                            }
                        }

                        MaterialSymbol {
                            text: "arrow_forward"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.colors.colSubtext
                        }

                        MaterialTextArea {
                            id: subToArea
                            Layout.fillWidth: true
                            placeholderText: Translation.tr("Icon or app ID (e.g. vesktop)")
                            text: subRow.modelData.to ?? ""
                            wrapMode: TextEdit.Wrap
                            font.pixelSize: Appearance.font.pixelSize.small

                            property bool ready: false
                            Component.onCompleted: ready = true
                            onTextChanged: {
                                if (!ready) return
                                subToDebounce.restart()
                            }
                            Timer {
                                id: subToDebounce
                                interval: 2000
                                onTriggered: {
                                    if (subToArea.text !== (subRow.modelData.to ?? ""))
                                        page.updateSubstitution(subRow.index, "to", subToArea.text)
                                }
                            }
                        }

                        RippleButton {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            buttonRadius: width / 2
                            colBackground: ColorUtils.transparentize(Appearance.colors.colError, 0.85)
                            colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colError, 0.6)
                            colRipple: ColorUtils.transparentize(Appearance.colors.colError, 0.5)
                            onClicked: page.removeSubstitution(subRow.index)
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                text: "delete"
                                iconSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colError
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }
            ToolbarPairedFab {
                iconText: "add"
                onClicked: page.addSubstitution()
            }
        }
    }
}
