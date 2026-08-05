import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Qt5Compat.GraphicalEffects
import qs
import qs.services
import qs.modules.common
import qs.modules.ii.settings.pages
import qs.modules.common.widgets
import qs.modules.common.functions as CF

Item {
    id: root
    property real contentPadding: 8
    property int currentPage: 0
    property bool showingProfile: false
    property string settingsSearchQuery: ""
    property var settingsSearchResults: []
    property int settingsSearchIndex: 0

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

    function updateSettingsSearch() {
        const query = settingsSearchQuery.toLowerCase().trim()
        if (query === "") {
            settingsSearchResults = []
            settingsSearchIndex = 0
            return
        }

        let results = []
        for (let pageIndex = 0; pageIndex < pages.length; pageIndex++) {
            const pageData = pages[pageIndex]
            if (pageData.name.toLowerCase().includes(query)) {
                results.push({ pageIndex: pageIndex, pageName: pageData.name, sectionName: "", icon: pageData.icon })
            }

            const loader = pagesRepeater.itemAt(pageIndex)
            if (!loader || !loader.item) continue
            let sectionNames = []
            collectSearchSections(loader.item, sectionNames)
            for (let sectionIndex = 0; sectionIndex < sectionNames.length; sectionIndex++) {
                const sectionName = sectionNames[sectionIndex]
                if (sectionName.toLowerCase().includes(query)) {
                    results.push({ pageIndex: pageIndex, pageName: pageData.name, sectionName: sectionName, icon: pageData.icon })
                }
            }
        }
        settingsSearchResults = results.slice(0, 12)
        settingsSearchIndex = Math.min(settingsSearchIndex, Math.max(0, settingsSearchResults.length - 1))
    }

    function openSettingsSearchResult(result) {
        if (!result) return
        currentPage = result.pageIndex
        showingProfile = false
        settingsSearchQuery = ""
        if (result.sectionName === "") return

        const loader = pagesRepeater.itemAt(result.pageIndex)
        if (loader && loader.item && typeof loader.item.goTo === "function") {
            Qt.callLater(() => loader.item.goTo(result.sectionName))
        }
    }

    // Not a plain `width > 900` binding: width is 0 for the first frames, so the
    // rail would start collapsed and animate open every time the window opens.
    property bool railExpanded: true
    onWidthChanged: if (width > 0) railExpanded = (width > 900)

    Connections {
        target: GlobalStates
        function onSettingsPageChanged() {
            if (GlobalStates.settingsPage === "") return
            
            let parts = GlobalStates.settingsPage.split(":");
            let pageName = parts[0];
            let searchTerm = parts.length > 1 ? parts[1] : "";

            const idx = root.pages.findIndex(p => p.name.toLowerCase() === pageName.toLowerCase());
            
            if (idx >= 0) {
                root.currentPage = idx;
                root.showingProfile = false;
                
                if (searchTerm !== "") {
                    let loader = pagesRepeater.itemAt(idx);
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

    onCurrentPageChanged: {
        if (currentPage >= 0 && currentPage < pages.length && pages[currentPage].key === "about") {
            if (SystemInfo.cpu === "") SystemInfo.refresh()
            Updates.refresh()
        }
    }
    
    property var pages: [
        { key: "quick",      name: Translation.tr("Quick"),      icon: "instant_mix",    component: Qt.resolvedUrl("pages/QuickConfig.qml") },
        { key: "general",    name: Translation.tr("General"),    icon: "browse",         component: Qt.resolvedUrl("pages/GeneralConfig.qml") },
        { key: "interface",  name: Translation.tr("Interface"),  icon: "bottom_app_bar", component: Qt.resolvedUrl("pages/InterfaceConfig.qml") },
        { key: "desktop",    name: Translation.tr("Desktop"),    icon: "texture",        component: Qt.resolvedUrl("pages/BackgroundConfig.qml") },
        { key: "bar",        name: Translation.tr("Bar"),        icon: "toast",          iconRotation: 180, component: Qt.resolvedUrl("pages/BarConfig.qml") },
        { key: "sound",      name: Translation.tr("Sound"),      icon: "volume_up",      component: Qt.resolvedUrl("pages/SoundConfig.qml") },
        { key: "network",    name: Translation.tr("Network"),    icon: "wifi",           component: Qt.resolvedUrl("pages/NetworkConfig.qml") },
        { key: "apps",       name: Translation.tr("Apps"),       icon: "apps",           component: Qt.resolvedUrl("pages/AppsConfig.qml") },
        { key: "services",   name: Translation.tr("Services"),   icon: "settings",       component: Qt.resolvedUrl("pages/ServicesConfig.qml") },
        NiriData.isNiri
            ? { key: "niri",     name: Translation.tr("Niri"),     icon: "select_window_2", component: Qt.resolvedUrl("pages/NiriConfig.qml") }
            : { key: "hyprland", name: Translation.tr("Hyprland"), icon: "select_window_2", component: Qt.resolvedUrl("pages/HyprlandConfig.qml") },
        { key: "shortcuts",  name: Translation.tr("Shortcuts"),  icon: "keyboard",       component: Qt.resolvedUrl("pages/ShortcutsConfig.qml") },
        { key: "about",      name: Translation.tr("About"),      icon: "info",           component: Qt.resolvedUrl("pages/About.qml") }
    ]

    Component.onCompleted: {
        Config.readWriteDelay = 0
        preloadTimer.start()
    }

    // Preload every page so switching is instant, but one per frame — building all
    // 12 in a single callLater froze the window for the whole startup.
    Timer {
        id: preloadTimer
        interval: 16
        repeat: true
        property int nextPage: 0
        onTriggered: {
            const loader = pagesRepeater.itemAt(nextPage)
            if (loader) loader.active = true
            if (++nextPage >= root.pages.length) {
                if (profileLoader) profileLoader.active = true
                running = false
            }
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
                implicitWidth: navRail.expanded ? 195 : fab.baseSize
                color: Appearance.m3colors.m3surfaceContainerLow
                radius: Appearance.rounding.normal

                Behavior on implicitWidth {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                NavigationRail {
                    id: navRail
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom; leftMargin: 20 }
                    spacing: 10
                    expanded: root.railExpanded

                    RowLayout {
                        visible: navRail.expanded
                        spacing: 10
                        Layout.fillWidth: true
                        Layout.margins: 5
                        Layout.topMargin: 15

                        Rectangle {
                            id: avatarRect
                            width: 48
                            height: 48
                            radius: width / 2
                            color: Appearance.colors.colPrimaryContainer

                            Image {
                                id: avatarImage
                                anchors.fill: parent
                                source: Config.options.profile.avatarPath !== "" 
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

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showingProfile = !root.showingProfile
                        }
                    }

                    Rectangle {
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
                                                    visible: modelData.sectionName !== ""
                                                    Layout.fillWidth: true
                                                    text: modelData.pageName
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
                        Layout.bottomMargin: -25
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

                    NavigationRailTabArray {
                        currentIndex: root.currentPage
                        expanded: navRail.expanded
                        colToggled: root.showingProfile ? "transparent" : Appearance.colors.colSecondaryContainer
                        Repeater {
                            model: root.pages
                            NavigationRailButton {
                                required property var index
                                required property var modelData
                                toggled: root.currentPage === index && !root.showingProfile
                                onPressed: {
                                    root.currentPage = index
                                    root.showingProfile = false
                                }
                                expanded: navRail.expanded
                                buttonIcon: modelData.icon
                                buttonIconRotation: modelData.iconRotation || 0
                                buttonText: modelData.name
                                showToggledHighlight: false
                            }
                        }
                    }

                    // Soaks up leftover vertical space. Without it the ColumnLayout
                    // spreads the slack across every cell and inflates the gaps.
                    Item { Layout.fillHeight: true }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
                radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut

                Item {
                    anchors.fill: parent

                    Repeater {
                        id: pagesRepeater
                        model: root.pages
                        Loader {
                            id: pageLoader
                            required property var modelData
                            required property var index
                            source: modelData.component

                            active: Config.ready && (root.currentPage === index || item !== null)

                            anchors.fill: parent

                            property bool isActive: root.currentPage === index && !root.showingProfile
                            opacity: isActive ? 1 : 0
                            enabled: isActive
                            visible: isActive
                            anchors.topMargin: isActive ? 0 : 12

                            onLoaded: {
                                if (root.currentPage === index) {
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
                        active: false
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
