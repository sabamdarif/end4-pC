import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Quickshell

ContentPage {
    id: page
    forceWidth: true

    ContentSection {
        icon: "monitor"
        shape: MaterialShape.Shape.ClamShell
        title: Translation.tr("Screens")
        ContentSubsection {
            title: Translation.tr("Show bar on")

            ColumnLayout {
                id: monitorsCol
                Layout.fillWidth: true
                spacing: 2

                Rectangle {
                    id: allRow
                    Layout.fillWidth: true
                    implicitHeight: allSwitchItem.implicitHeight + 16 + 8
                    color: Appearance.colors.colLayer1
                    topLeftRadius: Appearance.rounding.normal
                    topRightRadius: Appearance.rounding.normal
                    bottomLeftRadius: Appearance.rounding.unsharpenmore
                    bottomRightRadius: Appearance.rounding.unsharpenmore

                    ConfigSwitch {
                        id: allSwitchItem
                        anchors { fill: parent; margins: 8 }
                        buttonIcon: "tv_displays"
                        text: Translation.tr("All")
                        onCheckedChanged: {
                            if (checked) Config.options.bar.screenList = []
                        }

                        Binding {
                            target: allSwitchItem
                            property: "checked"
                            value: Config.options.bar.screenList.length === 0
                            restoreMode: Binding.RestoreBinding
                        }
                    }
                }

                Repeater {
                    model: Quickshell.screens
                    delegate: Rectangle {
                        id: monitorRow
                        required property var modelData
                        required property int index
                        readonly property bool isLast: index === Quickshell.screens.length - 1

                        Layout.fillWidth: true
                        implicitHeight: switchItem.implicitHeight + 16 + 8
                        color: Appearance.colors.colLayer1
                        topLeftRadius:     Appearance.rounding.unsharpenmore
                        topRightRadius:    Appearance.rounding.unsharpenmore
                        bottomLeftRadius:  isLast ? Appearance.rounding.normal : Appearance.rounding.unsharpenmore
                        bottomRightRadius: isLast ? Appearance.rounding.normal : Appearance.rounding.unsharpenmore

                        ConfigSwitch {
                            id: switchItem
                            anchors { fill: parent; margins: 8 }
                            buttonIcon: "monitor"
                            text: monitorRow.modelData.name
                            onCheckedChanged: {
                                const allNames = Quickshell.screens.map(m => m.name)
                                let list = Config.options.bar.screenList.length === 0 ? allNames.slice() : Config.options.bar.screenList.slice()
                                if (checked) {
                                    if (!list.includes(monitorRow.modelData.name)) list.push(monitorRow.modelData.name)
                                } else {
                                    list = list.filter(s => s !== monitorRow.modelData.name)
                                }
                                Config.options.bar.screenList = list.length === allNames.length ? [] : list
                            }

                            Binding {
                                target: switchItem
                                property: "checked"
                                value: Config.options.bar.screenList.length === 0 || Config.options.bar.screenList.includes(monitorRow.modelData.name)
                                restoreMode: Binding.RestoreBinding
                            }
                        }
                    }
                }
            }
        }
    }
}
