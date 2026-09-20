import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Qt5Compat.GraphicalEffects
import qs
import qs.services
import qs.modules.common
import qs.modules.ii.settings
import qs.modules.common.widgets
import qs.modules.common.functions as CF

Item {
    id: root
    property real contentPadding: 8
    property string currentLeaf: SettingsPages.leaves.length > 0 ? SettingsPages.leaves[0].key : ""
    property bool showingProfile: false
    // Group key -> expanded. Multiple groups may be open at once.
    property var expandedGroups: ({})
    property string settingsSearchQuery: ""
    property var settingsSearchResults: []
    property int settingsSearchIndex: 0

    function isGroupExpanded(key) {
        return root.expandedGroups[key] === true
    }

    function setGroupExpanded(key, value) {
        let next = Object.assign({}, root.expandedGroups)
        next[key] = value
        root.expandedGroups = next
    }

    function selectLeaf(key) {
        if (SettingsPages.leafIndex(key) < 0) return
        root.currentLeaf = key
        root.showingProfile = false
        const group = SettingsPages.groupOf(key)
        if (group !== "") root.setGroupExpanded(group, true)
    }

    Component.onCompleted: {
        Config.readWriteDelay = 0
        DateTime.uptimeSubscribers++
        const group = SettingsPages.groupOf(root.currentLeaf)
        if (group !== "") root.setGroupExpanded(group, true)
    }
    Component.onDestruction: DateTime.uptimeSubscribers--

    onCurrentLeafChanged: {
        if (root.currentLeaf !== "about") return
        if (SystemInfo.cpu === "") SystemInfo.refresh()
        Updates.refresh()
    }

    function collectSearchSections(item, results) {
        if (!item) return
        if (item.settingsSearchSection === true && item.title !== "") {
            results.push(item.title)
        }
        if (!item.children) return
        for (let i = 0; i < item.children.length; i++) {
            collectSearchSections(item.children[i], results)
        }
    }

    // Group and leaf names come from the registry, so results exist before a page
    // has ever been built. Section titles need the page loaded, so they fill in
    // as pages are visited (Loader.onLoaded re-runs this).
    function updateSettingsSearch() {
        const query = settingsSearchQuery.toLowerCase().trim()
        if (query === "") {
            settingsSearchResults = []
            settingsSearchIndex = 0
            return
        }

        let results = []
        for (let i = 0; i < SettingsPages.leaves.length; i++) {
            const leaf = SettingsPages.leaves[i]
            if (leaf.name.toLowerCase().includes(query) || leaf.groupName.toLowerCase().includes(query)) {
                results.push({ leafKey: leaf.key, pageName: leaf.name, groupName: leaf.groupName, sectionName: "", icon: leaf.icon })
            }

            const loader = pagesRepeater.itemAt(i)
            if (!loader || !loader.item) continue
            let sectionNames = []
            collectSearchSections(loader.item, sectionNames)
            for (let s = 0; s < sectionNames.length; s++) {
                const sectionName = sectionNames[s]
                if (!sectionName.toLowerCase().includes(query)) continue
                if (sectionName.toLowerCase() === leaf.name.toLowerCase()) continue
                results.push({ leafKey: leaf.key, pageName: leaf.name, groupName: leaf.groupName, sectionName: sectionName, icon: leaf.icon })
            }
        }
        settingsSearchResults = results.slice(0, 12)
        settingsSearchIndex = Math.min(settingsSearchIndex, Math.max(0, settingsSearchResults.length - 1))
    }

    function openSettingsSearchResult(result) {
        if (!result) return
        root.selectLeaf(result.leafKey)
        settingsSearchQuery = ""
        if (result.sectionName === "") return

        const loader = pagesRepeater.itemAt(SettingsPages.leafIndex(result.leafKey))
        if (loader && loader.item && typeof loader.item.goTo === "function") {
            Qt.callLater(() => loader.item.goTo(result.sectionName))
        }
    }

    // Not a plain `width > 900` binding: width is 0 for the first frames, so the
    // rail would start collapsed and animate open every time the window opens.
    // Clicking a group icon in the collapsed rail also sets this directly.
    property bool railExpanded: true
    onWidthChanged: if (width > 0) railExpanded = (width > 900)

    Connections {
        target: GlobalStates
        function onSettingsPageChanged() {
            if (GlobalStates.settingsPage === "") return

            const parts = GlobalStates.settingsPage.split(":");
            const target = parts[0];
            const searchTerm = parts.length > 1 ? parts[1] : "";

            // Prefer the stable key; fall back to display names so an old-style
            // link ("Desktop") still lands somewhere sensible.
            let leafKey = SettingsPages.leafIndex(target) >= 0 ? target : ""
            if (leafKey === "") {
                const byName = SettingsPages.leaves.find(l => l.name.toLowerCase() === target.toLowerCase())
                    ?? SettingsPages.leaves.find(l => l.groupName.toLowerCase() === target.toLowerCase())
                if (byName) leafKey = byName.key
            }

            if (leafKey !== "") {
                root.selectLeaf(leafKey)
                if (searchTerm !== "") {
                    const loader = pagesRepeater.itemAt(SettingsPages.leafIndex(leafKey));
                    if (loader && loader.item && typeof loader.item.goTo === "function") {
                        loader.item.goTo(searchTerm);
                    } else if (loader) {
                        loader.onLoaded.connect(function() {
                            if (loader.item && typeof loader.item.goTo === "function") {
                                loader.item.goTo(searchTerm);
                            }
                        });
                    }
                }
            }
            GlobalStates.settingsPage = "";
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: contentPadding
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: contentPadding

            Rectangle {
                id: navRailWrapper
                Layout.fillHeight: true
                Layout.margins: 0
                implicitWidth: navRail.expanded ? 250 : 56
                color: Appearance.m3colors.m3surfaceContainerLow
                radius: Appearance.rounding.normal

                Behavior on implicitWidth {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                NavigationRail {
                    id: navRail
                    anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; leftMargin: 14; rightMargin: 10 }
                    spacing: 10
                    expanded: root.railExpanded

                    Item {
                        id: profileHeader
                        visible: navRail.expanded
                        Layout.fillWidth: true
                        Layout.margins: 5
                        Layout.topMargin: 15
                        implicitHeight: profileRow.implicitHeight

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showingProfile = !root.showingProfile
                        }

                        RowLayout {
                            id: profileRow
                            anchors.fill: parent
                            spacing: 10

                            Rectangle {
                                id: avatarRect
                                width: 48
                                height: 48
                                radius: width / 2
                                color: Appearance.colors.colPrimaryContainer

                                Image {
                                    id: avatarImage
                                    anchors.fill: parent
                                    source: Config.options.profile.avatarPicture !== ""
                                        ? "file://" + Config.options.profile.avatarPicture
                                        : "file:///home/" + (Quickshell.env("USER") ?? "user") + "/.face"
                                    sourceSize.width: avatarImage.width * 2
                                    sourceSize.height: avatarImage.height * 2
                                    fillMode: Image.PreserveAspectCrop
                                    layer.enabled: true
                                    layer.effect: OpacityMask {
                                        maskSource: Rectangle {
                                            width: avatarRect.width
                                            height: avatarRect.height
                                            radius: avatarRect.radius
                                        }
                                    }
                                    onStatusChanged: {
                                        if (status === Image.Error)
                                            visible = false
                                    }
                                }

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "account_circle"
                                    iconSize: 32
                                    color: Appearance.colors.colOnPrimaryContainer
                                    visible: avatarImage.status === Image.Error
                                }
                            }

                            ColumnLayout {
                                spacing: 2
                                Layout.fillWidth: true

                                StyledText {
                                    text: Config.options.profile.displayName === "" ? SystemInfo.username : Config.options.profile.displayName
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnLayer1
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: 100
                                }

                                StyledText {
                                    id: distroText
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: 100

                                    text: {
                                        const d = Config.options.profile.descriptionText
                                        if (d === "::uptime::") return Translation.tr("Up • %1").arg(DateTime.uptime)
                                        return SystemInfo.distroName
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: navRail.expanded
                        width: 160
                        Layout.topMargin: -5
                        height: 2
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.2; color: Appearance.colors.colOutline }
                            GradientStop { position: 0.8; color: Appearance.colors.colOutline }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                        opacity: 0.15
                    }

                    Item {
                        visible: navRail.expanded
                        Layout.fillWidth: true
                        Layout.preferredHeight: settingsSearchField.implicitHeight
                        z: 10

                        MaterialTextField {
                            id: settingsSearchField
                            anchors { left: parent.left; right: parent.right }
                            placeholderText: Translation.tr("Search settings")
                            leftPadding: 36
                            rightPadding: 12
                            selectByMouse: true
                            text: root.settingsSearchQuery
                            onTextEdited: {
                                root.settingsSearchQuery = text
                                root.settingsSearchIndex = 0
                                root.updateSettingsSearch()
                            }
                            onActiveFocusChanged: if (activeFocus) root.updateSettingsSearch()
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Down && root.settingsSearchResults.length > 0) {
                                    root.settingsSearchIndex = Math.min(root.settingsSearchIndex + 1, root.settingsSearchResults.length - 1)
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Up && root.settingsSearchResults.length > 0) {
                                    root.settingsSearchIndex = Math.max(root.settingsSearchIndex - 1, 0)
                                    event.accepted = true
                                } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && root.settingsSearchResults.length > 0) {
                                    root.openSettingsSearchResult(root.settingsSearchResults[root.settingsSearchIndex])
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Escape) {
                                    root.settingsSearchQuery = ""
                                    root.settingsSearchResults = []
                                    focus = false
                                    event.accepted = true
                                }
                            }

                            MaterialSymbol {
                                anchors { left: parent.left; leftMargin: 11; verticalCenter: parent.verticalCenter }
                                text: "search"
                                iconSize: 18
                                color: Appearance.colors.colSubtext
                            }
                        }

                        Rectangle {
                            visible: settingsSearchField.activeFocus && root.settingsSearchQuery.trim() !== ""
                            anchors { top: settingsSearchField.bottom; left: parent.left; right: parent.right; topMargin: 4 }
                            implicitHeight: Math.min(searchResultsColumn.implicitHeight + 8, 300)
                            color: Appearance.m3colors.m3surfaceContainerHigh
                            radius: Appearance.rounding.small
                            border.width: 1
                            border.color: Appearance.m3colors.m3outlineVariant
                            clip: true

                            Column {
                                id: searchResultsColumn
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 4 }

                                Repeater {
                                    model: root.settingsSearchResults
                                    RippleButton {
                                        required property var index
                                        required property var modelData
                                        width: searchResultsColumn.width
                                        height: 44
                                        colBackground: index === root.settingsSearchIndex
                                            ? Appearance.colors.colSecondaryContainer
                                            : "transparent"
                                        colBackgroundHover: Appearance.colors.colLayer1Hover
                                        onClicked: root.openSettingsSearchResult(modelData)

                                        contentItem: RowLayout {
                                            spacing: 8
                                            MaterialSymbol {
                                                text: modelData.icon
                                                iconSize: 18
                                                color: Appearance.colors.colOnLayer1
                                            }
                                            ColumnLayout {
                                                spacing: 0
                                                Layout.fillWidth: true
                                                StyledText {
                                                    Layout.fillWidth: true
                                                    text: modelData.sectionName === "" ? modelData.pageName : modelData.sectionName
                                                    color: Appearance.colors.colOnLayer1
                                                    font.pixelSize: Appearance.font.pixelSize.small
                                                    elide: Text.ElideRight
                                                }
                                                StyledText {
                                                    Layout.fillWidth: true
                                                    text: modelData.sectionName === ""
                                                        ? modelData.groupName
                                                        : `${modelData.groupName} • ${modelData.pageName}`
                                                    color: Appearance.colors.colSubtext
                                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                                    elide: Text.ElideRight
                                                }
                                            }
                                        }
                                    }
                                }

                                StyledText {
                                    visible: root.settingsSearchResults.length === 0
                                    width: searchResultsColumn.width
                                    height: 40
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    text: Translation.tr("No settings found")
                                    color: Appearance.colors.colSubtext
                                    font.pixelSize: Appearance.font.pixelSize.small
                                }
                            }
                        }
                    }

                    FloatingActionButton {
                        id: fab
                        baseSize: 42
                        property bool justCopied: false
                        iconText: justCopied ? "check" : "edit"
                        buttonText: justCopied ? Translation.tr("Path copied") : Translation.tr("Config file")
                        expanded: navRail.expanded
                        downAction: () => {
                            Qt.openUrlExternally(`${Directories.config}/illogical-impulse/config.json`);
                        }
                        altAction: () => {
                            Quickshell.clipboardText = CF.FileUtils.trimFileProtocol(`${Directories.config}/illogical-impulse/config.json`);
                            fab.justCopied = true;
                            revertTextTimer.restart()
                        }
                        Timer {
                            id: revertTextTimer
                            interval: 1500
                            onTriggered: fab.justCopied = false
                        }
                        StyledToolTip {
                            text: Translation.tr("Open the shell config file\nAlternatively right-click to copy path")
                        }
                    }

                    // The tree is taller than the window's 400 px minimum once a
                    // couple of groups are open, so it scrolls on its own.
                    StyledFlickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.topMargin: 6
                        contentHeight: navTree.implicitHeight
                        clip: true

                        ColumnLayout {
                            id: navTree
                            width: parent.width
                            spacing: 2

                            Repeater {
                                model: SettingsPages.groups

                                ColumnLayout {
                                    id: groupColumn
                                    required property var modelData
                                    readonly property bool isLeafGroup: groupColumn.modelData.children.length === 0
                                    Layout.fillWidth: true
                                    spacing: 2

                                    SettingsNavGroup {
                                        groupIcon: groupColumn.modelData.icon
                                        groupIconRotation: groupColumn.modelData.iconRotation ?? 0
                                        groupName: groupColumn.modelData.name
                                        hasChildren: !groupColumn.isLeafGroup
                                        showLabel: navRail.expanded
                                        expanded: root.isGroupExpanded(groupColumn.modelData.key)
                                        toggled: root.showingProfile ? false
                                            : groupColumn.isLeafGroup
                                                ? root.currentLeaf === groupColumn.modelData.key
                                                : (!navRail.expanded && SettingsPages.groupOf(root.currentLeaf) === groupColumn.modelData.key)
                                        onPressed: {
                                            // Collapsed rail shows group icons only; a click opens the rail onto the group.
                                            if (!navRail.expanded) {
                                                root.railExpanded = true
                                                if (groupColumn.isLeafGroup) root.selectLeaf(groupColumn.modelData.key)
                                                else root.setGroupExpanded(groupColumn.modelData.key, true)
                                                return
                                            }
                                            if (groupColumn.isLeafGroup) root.selectLeaf(groupColumn.modelData.key)
                                            else root.setGroupExpanded(groupColumn.modelData.key, !root.isGroupExpanded(groupColumn.modelData.key))
                                        }
                                    }

                                    Revealer {
                                        vertical: true
                                        reveal: navRail.expanded && !groupColumn.isLeafGroup
                                            && root.isGroupExpanded(groupColumn.modelData.key)
                                        Layout.fillWidth: true

                                        ColumnLayout {
                                            width: parent.width
                                            spacing: 2

                                            Repeater {
                                                model: groupColumn.modelData.children

                                                NavigationRailButton {
                                                    required property var modelData
                                                    Layout.leftMargin: 12
                                                    baseSize: 44
                                                    expanded: true
                                                    toggled: root.currentLeaf === modelData.key && !root.showingProfile
                                                    buttonIcon: modelData.icon
                                                    buttonIconRotation: modelData.iconRotation ?? 0
                                                    buttonText: modelData.name
                                                    onPressed: root.selectLeaf(modelData.key)
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

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
                radius: Appearance.rounding.screenRounding - Appearance.sizes.windowGapsOut

                Item {
                    anchors.fill: parent

                    Repeater {
                        id: pagesRepeater
                        model: SettingsPages.leaves
                        Loader {
                            id: pageLoader
                            required property var modelData
                            required property var index
                            source: modelData.component

                            // Built on first visit, then kept alive so switching back is instant.
                            active: Config.ready && (root.currentLeaf === modelData.key || item !== null)

                            anchors.fill: parent

                            property bool isActive: root.currentLeaf === modelData.key && !root.showingProfile
                            opacity: isActive ? 1 : 0
                            enabled: isActive
                            visible: isActive
                            anchors.topMargin: isActive ? 0 : 12

                            onLoaded: {
                                if (root.currentLeaf === modelData.key) {
                                    GlobalStates.currentPageInstance = item;
                                }
                                if (root.settingsSearchQuery !== "") {
                                    root.updateSettingsSearch()
                                }
                            }

                            onIsActiveChanged: {
                                if (isActive && item) {
                                    GlobalStates.currentPageInstance = item;
                                } else if (!isActive && GlobalStates.currentPageInstance === item) {
                                    GlobalStates.currentPageInstance = null;
                                }
                            }

                            Behavior on opacity {
                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }
                            Behavior on anchors.topMargin {
                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }
                        }
                    }

                    Loader {
                        id: profileLoader
                        active: root.showingProfile || item !== null
                        anchors.fill: parent
                        source: Qt.resolvedUrl("pages/Profile.qml")

                        property bool isActive: root.showingProfile
                        opacity: isActive ? 1 : 0
                        enabled: isActive
                        visible: isActive
                        anchors.topMargin: isActive ? 0 : 12

                        onIsActiveChanged: {
                            if (isActive && item) {
                                GlobalStates.currentPageInstance = item;
                            } else if (!isActive && GlobalStates.currentPageInstance === item) {
                                GlobalStates.currentPageInstance = null;
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                        Behavior on anchors.topMargin {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }
        }
    }
}
