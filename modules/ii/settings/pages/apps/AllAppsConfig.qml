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

    property string appSearchQuery: ""
    readonly property var filteredApps: {
        const query = appSearchQuery.toLowerCase().trim()
        const list = query === "" ? AppInventory.apps : AppInventory.apps.filter(app =>
            `${app.name} ${app.id} ${app.comment} ${app.source}`.toLowerCase().includes(query))
        return list.slice(0, 100)
    }

    ContentSection {
        icon: "apps"
        shape: MaterialShape.Shape.Cookie6Sided
        title: Translation.tr("All Apps")

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Search installed apps")
                text: page.appSearchQuery
                onTextChanged: page.appSearchQuery = text
            }
            RippleButtonWithIcon {
                materialIcon: "refresh"
                mainText: Translation.tr("Refresh")
                onClicked: AppInventory.refresh()
            }
        }

        StyledText {
            Layout.leftMargin: 8
            text: Translation.tr("%1 apps shown").arg(page.filteredApps.length)
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.smaller
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: allAppsColumn.implicitHeight + 20
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1

            ColumnLayout {
                id: allAppsColumn
                anchors { fill: parent; margins: 10 }
                spacing: 4

                Repeater {
                    model: page.filteredApps
                    delegate: Rectangle {
                        id: appRow
                        required property var modelData
                        required property int index
                        property bool confirmingUninstall: false
                        property bool confirmingClear: false
                        property bool permissionsExpanded: false

                        Layout.fillWidth: true
                        implicitHeight: appContent.implicitHeight + 16
                        radius: Appearance.rounding.small
                        color: index % 2 === 0 ? Appearance.colors.colLayer2 : "transparent"

                        ColumnLayout {
                            id: appContent
                            anchors { fill: parent; margins: 8 }
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                IconImage {
                                source: Quickshell.iconPath(appRow.modelData.icon, "image-missing")
                                implicitWidth: 36
                                implicitHeight: 36
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                StyledText {
                                    Layout.fillWidth: true
                                    text: appRow.modelData.name
                                    color: Appearance.colors.colOnLayer1
                                    elide: Text.ElideRight
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: `${appRow.modelData.source === "flatpak" ? "Flatpak" : Translation.tr("System")} · ${appRow.modelData.size || appRow.modelData.id}`
                                    color: Appearance.colors.colSubtext
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    elide: Text.ElideRight
                                }
                            }

                            RippleButtonWithIcon {
                                materialIcon: "open_in_new"
                                mainText: Translation.tr("Open")
                                onClicked: AppInventory.open(appRow.modelData)
                            }

                            RippleButtonWithIcon {
                                visible: appRow.modelData.source === "flatpak"
                                materialIcon: "admin_panel_settings"
                                mainText: Translation.tr("Permissions")
                                onClicked: appRow.permissionsExpanded = !appRow.permissionsExpanded
                            }

                            RippleButtonWithIcon {
                                visible: appRow.modelData.source === "flatpak" && !appRow.confirmingClear
                                materialIcon: "delete_sweep"
                                mainText: Translation.tr("Clear data")
                                onClicked: appRow.confirmingClear = true
                            }
                            DialogButton {
                                visible: appRow.confirmingClear
                                buttonText: Translation.tr("Clear?")
                                colText: Appearance.m3colors.m3error
                                onClicked: {
                                    Quickshell.execDetached(["gio", "trash", `${FileUtils.trimFileProtocol(Directories.home)}/.var/app/${appRow.modelData.id}`])
                                    appRow.confirmingClear = false
                                }
                            }

                            RippleButtonWithIcon {
                                visible: !appRow.confirmingUninstall
                                materialIcon: "delete"
                                mainText: Translation.tr("Uninstall")
                                onClicked: appRow.confirmingUninstall = true
                            }
                            DialogButton {
                                visible: appRow.confirmingUninstall
                                buttonText: Translation.tr("Uninstall?")
                                colText: Appearance.m3colors.m3error
                                onClicked: {
                                    AppInventory.uninstall(appRow.modelData)
                                    appRow.confirmingUninstall = false
                                }
                            }
                            DialogButton {
                                visible: appRow.confirmingUninstall || appRow.confirmingClear
                                buttonText: Translation.tr("Cancel")
                                onClicked: {
                                    appRow.confirmingUninstall = false
                                    appRow.confirmingClear = false
                                }
                            }
                            }

                            RowLayout {
                                visible: appRow.modelData.source === "flatpak" && appRow.permissionsExpanded
                                Layout.fillWidth: true
                                Layout.leftMargin: 46
                                spacing: 10

                                MaterialSymbol {
                                    text: "notifications"
                                    iconSize: Appearance.font.pixelSize.larger
                                    color: Appearance.colors.colOnLayer1
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: Translation.tr("Notifications")
                                    color: Appearance.colors.colOnLayer1
                                }
                                StyledSwitch {
                                    checked: AppInventory.notificationPermission(appRow.modelData.id)
                                    onClicked: AppInventory.setNotificationPermission(appRow.modelData.id, checked)
                                    StyledToolTip {
                                        text: Translation.tr("Allow this app to send notifications")
                                    }
                                }
                                RippleButtonWithIcon {
                                    visible: AppInventory.flatsealInstalled
                                    materialIcon: "tune"
                                    mainText: Translation.tr("More")
                                    onClicked: AppInventory.openPermissions(appRow.modelData.id)
                                    StyledToolTip {
                                        text: Translation.tr("Open microphone, camera, filesystem, and other permissions in Flatseal")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
