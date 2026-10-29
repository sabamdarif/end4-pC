import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root

    property string appId: ""
    property alias isOpen: menuLoader.active
    // Button geometry in dock-window coordinates, captured on open. Anchoring to
    // the button item itself would close the menu whenever the dock rebuilds its
    // app list (any window opening/closing destroys the unpinned buttons).
    property rect anchorRect

    // Looked up live so the menu follows windows opening/closing while open.
    // TaskbarApps keys entries by lowercased appId.
    readonly property var appToplevel: root.appId !== ""
        ? (TaskbarApps.apps.find(a => a.appId === root.appId.toLowerCase()) ?? null)
        : null
    readonly property var toplevels: appToplevel?.toplevels ?? []
    readonly property bool hasWindows: toplevels.length > 0

    property var desktopEntry: null
    readonly property bool hasDesktopActions: (desktopEntry?.actions.length ?? 0) > 0

    Connections {
        target: DesktopEntries
        enabled: root.isOpen
        function onApplicationsChanged() {
            root.desktopEntry = DesktopEntries.heuristicLookup(root.appId);
        }
    }

    function open(button, appId) {
        menuLoader.active = false;
        const topLeft = root.QsWindow.mapFromItem(button, 0, 0);
        root.anchorRect = Qt.rect(topLeft.x, topLeft.y, button.width, button.height);
        root.appId = appId;
        root.desktopEntry = DesktopEntries.heuristicLookup(appId);
        menuLoader.active = true;
    }

    function close() {
        menuLoader.active = false;
        // Drop the live lookups so closed menus don't track TaskbarApps.
        root.appId = "";
        root.desktopEntry = null;
    }

    // niri toplevels carry no window id, so look it up in NiriData by title.
    function niriWindowId(toplevel) {
        const win = NiriData.windows.find(w => w.title === toplevel.title);
        return win?.id ?? -1;
    }

    // niri has no focus-grab protocol and overlay popups never change NiriData's
    // focused window, so outside clicks are caught by a fullscreen surface one
    // layer below the popup, same pattern as the sidebars.
    PanelWindow {
        id: dismissCatcher
        visible: root.isOpen
        color: "transparent"

        WlrLayershell.namespace: "quickshell:dock:contextMenuDismiss"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: GlobalFocusGrab.dismiss()
        }
    }

    function moveToWorkspace(workspaceId) {
        for (const toplevel of root.toplevels) {
            const windowId = niriWindowId(toplevel);
            if (windowId > 0)
                Quickshell.execDetached(["niri", "msg", "action", "move-window-to-workspace",
                    "--window-id", String(windowId), "--focus", "false", String(workspaceId)]);
        }
    }

    Loader {
        id: menuLoader
        active: false
        onActiveChanged: {
            if (active && menuLoader.item)
                GlobalFocusGrab.addDismissable(menuLoader.item);
            else if (!active && menuLoader.item)
                GlobalFocusGrab.removeDismissable(menuLoader.item);
        }

        sourceComponent: PopupWindow {
            id: contextPopup
            visible: true

            // niri's workspaces are dynamic, so mirror the ones niri reports for
            // the focused output instead of the bar's fixed shown count.
            readonly property var workspacesOnOutput: {
                const output = NiriData.currentOutput;
                return NiriData.workspaces
                    .filter(ws => ws.output === output)
                    .sort((a, b) => a.idx - b.idx);
            }

            anchor {
                window: root.QsWindow.window
                rect: root.anchorRect
                gravity: Edges.Top
                edges: Edges.Top
                adjustment: PopupAdjustment.SlideX
            }

            Connections {
                target: GlobalFocusGrab
                function onDismissed() { root.close(); }
            }

            color: "transparent"
            // Clicks on the transparent shadow margin should count as outside.
            mask: Region {
                item: menuBackground
            }
            implicitWidth: menuBackground.implicitWidth + Appearance.sizes.elevationMargin * 2
            implicitHeight: menuBackground.implicitHeight + Appearance.sizes.elevationMargin * 2

            StyledRectangularShadow {
                target: menuBackground
            }

            Rectangle {
                id: menuBackground
                WindowGlass {
                    anchors.fill: parent
                    glassEnabled: (parent?.color.a ?? 0) > 0
                    cardRadius: parent?.radius ?? 0
                    tint: parent?.color ?? 'transparent'
                }
                property real padding: 4

                anchors.centerIn: parent
                color: Appearance.m3colors.m3surfaceContainer
                radius: Appearance.rounding.normal
                implicitWidth: menuColumn.implicitWidth + padding * 2
                implicitHeight: menuColumn.implicitHeight + padding * 2
                focus: true
                Keys.onEscapePressed: root.close()

                ColumnLayout {
                    id: menuColumn
                    anchors {
                        fill: parent
                        margins: parent.padding
                    }
                    spacing: 0

                    // Desktop entry actions
                    Repeater {
                        model: root.desktopEntry?.actions ?? []
                        delegate: ContextMenuItem {
                            required property var modelData
                            iconSource: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
                            iconName: "chevron_right"
                            label: modelData.name
                            onClicked: {
                                modelData.execute();
                                root.close();
                            }
                        }
                    }

                    ContextMenuSeparator {
                        visible: root.hasDesktopActions
                    }

                    ContextMenuItem {
                        iconName: "open_in_new"
                        label: Translation.tr("Open new instance")
                        enabled: root.desktopEntry !== null
                        onClicked: {
                            root.desktopEntry?.execute();
                            root.close();
                        }
                    }

                    ContextMenuSeparator {
                        visible: root.hasWindows
                    }

                    ContextMenuItem {
                        visible: root.hasWindows
                        iconName: "move_item"
                        label: Translation.tr("Move to workspace")
                        enabled: false
                        pointingHandCursor: false
                    }

                    RowLayout {
                        visible: root.hasWindows
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        Layout.bottomMargin: 4
                        spacing: 2

                        Repeater {
                            model: contextPopup.workspacesOnOutput
                            delegate: RippleButton {
                                id: wsButton
                                required property var modelData
                                implicitWidth: 28
                                implicitHeight: 28
                                buttonRadius: Appearance.rounding.small
                                contentItem: StyledText {
                                    anchors.centerIn: parent
                                    text: String(wsButton.modelData.idx)
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    horizontalAlignment: Text.AlignHCenter
                                    color: Appearance.m3colors.m3onSurface
                                }
                                onClicked: {
                                    root.moveToWorkspace(wsButton.modelData.id);
                                    root.close();
                                }
                            }
                        }
                    }

                    ContextMenuItem {
                        readonly property bool pinned: TaskbarApps.isPinned(root.appId)
                        iconName: pinned ? "keep_off" : "keep"
                        label: pinned ? Translation.tr("Unpin") : Translation.tr("Pin to dock")
                        enabled: root.appId !== ""
                        onClicked: {
                            TaskbarApps.togglePin(root.appId);
                            root.close();
                        }
                    }

                    ContextMenuSeparator {
                        visible: root.hasWindows
                    }

                    ContextMenuItem {
                        visible: root.hasWindows
                        iconName: "close"
                        label: root.toplevels.length > 1
                            ? Translation.tr("Close all windows") : Translation.tr("Close window")
                        onClicked: {
                            for (const toplevel of root.toplevels) {
                                toplevel.close();
                            }
                            root.close();
                        }
                    }
                }
            }
        }
    }

    component ContextMenuItem: RippleButton {
        id: menuItemRoot
        property string iconName
        // Themed icon; falls back to iconName (a Material Symbol) when empty.
        property string iconSource
        property string label
        readonly property color contentColor: enabled ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3outline
        Layout.fillWidth: true
        implicitHeight: 36
        implicitWidth: Math.max(itemRow.implicitWidth + itemRow.anchors.leftMargin + itemRow.anchors.rightMargin, 180)
        buttonRadius: Appearance.rounding.small

        contentItem: RowLayout {
            id: itemRow
            anchors {
                fill: parent
                leftMargin: 10
                rightMargin: 14
            }
            spacing: 8

            IconImage {
                visible: menuItemRoot.iconSource !== ""
                source: menuItemRoot.iconSource
                implicitSize: Appearance.font.pixelSize.normal
                Layout.alignment: Qt.AlignVCenter
            }

            MaterialSymbol {
                text: menuItemRoot.iconName
                iconSize: Appearance.font.pixelSize.normal
                color: menuItemRoot.contentColor
                visible: menuItemRoot.iconSource === "" && menuItemRoot.iconName !== ""
                Layout.alignment: Qt.AlignVCenter
            }

            StyledText {
                Layout.fillWidth: true
                text: menuItemRoot.label
                horizontalAlignment: Text.AlignLeft
                font.pixelSize: Appearance.font.pixelSize.small
                color: menuItemRoot.contentColor
                elide: Text.ElideRight
            }
        }
    }

    component ContextMenuSeparator: Item {
        Layout.fillWidth: true
        implicitHeight: 9

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: 10
                rightMargin: 10
            }
            implicitHeight: 1
            color: ColorUtils.transparentize(Appearance.m3colors.m3outline, 0.7)
        }
    }
}
