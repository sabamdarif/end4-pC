pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models
import qs.modules.common.functions

Item {
    id: root

    readonly property int searchBarHeight: 62
    readonly property int maxExpandedHeight: Math.min(680, Math.round(Screen.height * 0.78))
    readonly property int panelWidth: Math.min(840, Math.round(Screen.width * 0.65))

    property string query: LauncherSearch.query
    readonly property bool showResults: root.query.length > 0
    readonly property bool isSpaceOnly: root.query === " "
    readonly property var displayedApps: root.isSpaceOnly ? LauncherSearch.appResults : LauncherSearch.appResults.slice(0, 6)

    property string selectedSection: ""
    property int sectionIndex: -1

    FileSearch {
        id: fileSearch
        query: (Config.options.search.providers?.files ?? true) ? root.query : ""
    }

    function getActiveSections() {
        const list = [];
        if (LauncherSearch.mathResult) list.push("math");
        if (root.displayedApps.length > 0) list.push("apps");
        if (fileSearch.results.length > 0 && !root.isSpaceOnly) list.push("files");
        if (LauncherSearch.settingsResults.length > 0 && !root.isSpaceOnly) list.push("settings");
        return list;
    }

    function getSectionCount(section) {
        switch (section) {
            case "math": return LauncherSearch.mathResult ? 1 : 0;
            case "apps": return root.displayedApps.length;
            case "files": return fileSearch.results.length;
            case "settings": return LauncherSearch.settingsResults.length;
            default: return 0;
        }
    }

    function selectFirstAvailable() {
        if (!root.showResults) {
            root.selectedSection = "";
            root.sectionIndex = -1;
            return;
        }
        const sections = getActiveSections();
        if (sections.length > 0) {
            root.selectedSection = sections[0];
            root.sectionIndex = 0;
            ensureSelectionVisible();
        } else {
            root.selectedSection = "";
            root.sectionIndex = -1;
        }
    }

    onQueryChanged: {
        if (flickable) flickable.contentY = 0;
        root.selectFirstAvailable();
    }

    Connections {
        target: LauncherSearch
        function onMathResultChanged() {
            if (root.selectedSection === "" || root.selectedSection === "math")
                root.selectFirstAvailable();
        }
        function onAppResultsChanged() {
            if (root.selectedSection === "" || (root.selectedSection === "apps" && root.sectionIndex >= root.displayedApps.length))
                root.selectFirstAvailable();
        }
        function onSettingsResultsChanged() {
            if (root.selectedSection === "" || (root.selectedSection === "settings" && root.sectionIndex >= LauncherSearch.settingsResults.length))
                root.selectFirstAvailable();
        }
    }

    Connections {
        target: fileSearch
        function onResultsChanged() {
            if (root.selectedSection === "" || (root.selectedSection === "files" && root.sectionIndex >= fileSearch.results.length))
                root.selectFirstAvailable();
        }
    }

    Connections {
        target: GlobalStates
        function onOverviewOpenChanged() {
            if (GlobalStates.overviewOpen) {
                searchInput.forceActiveFocus();
                root.selectFirstAvailable();
            } else {
                root.selectedSection = "";
                root.sectionIndex = -1;
            }
        }
    }

    function ensureSelectionVisible() {
        if (!flickable || root.selectedSection === "" || root.sectionIndex < 0) return;
        let targetY = 0;
        let targetH = 60;

        if (root.selectedSection === "math" && mathCard && mathCard.visible) {
            targetY = mathCard.y;
            targetH = mathCard.height;
        } else if (root.selectedSection === "apps" && appsSection && appsSection.visible) {
            const row = Math.floor(root.sectionIndex / 6);
            targetY = appsSection.y + 24 + row * 114;
            targetH = 104;
        } else if (root.selectedSection === "files" && filesSection && filesSection.visible) {
            targetY = filesSection.y + 24 + root.sectionIndex * 60;
            targetH = 58;
        } else if (root.selectedSection === "settings" && settingsSection && settingsSection.visible) {
            targetY = settingsSection.y + 24 + root.sectionIndex * 54;
            targetH = 52;
        } else {
            return;
        }

        if (targetY < flickable.contentY) {
            flickable.contentY = Math.max(0, targetY - 10);
        } else if (targetY + targetH > flickable.contentY + flickable.height) {
            flickable.contentY = Math.min(Math.max(0, flickable.contentHeight - flickable.height), targetY + targetH + 16 - flickable.height);
        }
    }

    function navDown() {
        const sections = getActiveSections();
        if (sections.length === 0) return;

        if (root.selectedSection === "" || !sections.includes(root.selectedSection)) {
            root.selectedSection = sections[0];
            root.sectionIndex = 0;
            ensureSelectionVisible();
            return;
        }

        const sec = root.selectedSection;
        const count = getSectionCount(sec);
        const secIdx = sections.indexOf(sec);

        if (sec === "apps") {
            const cols = 6;
            const nextIdx = root.sectionIndex + cols;
            if (nextIdx < count) {
                root.sectionIndex = nextIdx;
            } else {
                const curRow = Math.floor(root.sectionIndex / cols);
                const totalRows = Math.ceil(count / cols);
                if (curRow < totalRows - 1) {
                    root.sectionIndex = count - 1;
                } else {
                    if (secIdx + 1 < sections.length) {
                        root.selectedSection = sections[secIdx + 1];
                        root.sectionIndex = 0;
                    }
                }
            }
        } else {
            if (root.sectionIndex + 1 < count) {
                root.sectionIndex++;
            } else {
                if (secIdx + 1 < sections.length) {
                    root.selectedSection = sections[secIdx + 1];
                    root.sectionIndex = 0;
                }
            }
        }
        ensureSelectionVisible();
    }

    function navUp() {
        const sections = getActiveSections();
        if (sections.length === 0) return;

        if (root.selectedSection === "" || !sections.includes(root.selectedSection)) {
            root.selectedSection = sections[0];
            root.sectionIndex = 0;
            ensureSelectionVisible();
            return;
        }

        const sec = root.selectedSection;
        const secIdx = sections.indexOf(sec);

        if (sec === "apps") {
            const cols = 6;
            if (root.sectionIndex >= cols) {
                root.sectionIndex -= cols;
            } else {
                if (secIdx > 0) {
                    const prevSec = sections[secIdx - 1];
                    const prevCount = getSectionCount(prevSec);
                    root.selectedSection = prevSec;
                    if (prevSec === "apps") {
                        const col = root.sectionIndex % 6;
                        const prevRows = Math.ceil(prevCount / 6);
                        const targetIdx = (prevRows - 1) * 6 + col;
                        root.sectionIndex = Math.min(prevCount - 1, targetIdx);
                    } else {
                        root.sectionIndex = prevCount - 1;
                    }
                }
            }
        } else {
            if (root.sectionIndex > 0) {
                root.sectionIndex--;
            } else {
                if (secIdx > 0) {
                    const prevSec = sections[secIdx - 1];
                    const prevCount = getSectionCount(prevSec);
                    root.selectedSection = prevSec;
                    if (prevSec === "apps") {
                        root.sectionIndex = prevCount - 1;
                    } else {
                        root.sectionIndex = prevCount - 1;
                    }
                }
            }
        }
        ensureSelectionVisible();
    }

    function navRight() {
        const sec = root.selectedSection;
        if (sec !== "apps") {
            return false;
        }
        const count = getSectionCount(sec);
        if (root.sectionIndex + 1 < count) {
            root.sectionIndex++;
            ensureSelectionVisible();
        }
        return true;
    }

    function navLeft() {
        const sec = root.selectedSection;
        if (sec !== "apps") {
            return false;
        }
        if (root.sectionIndex > 0) {
            root.sectionIndex--;
            ensureSelectionVisible();
        }
        return true;
    }

    implicitWidth: root.panelWidth
    implicitHeight: card.height

    function focusSearchInput() {
        searchInput.forceActiveFocus();
    }

    function setSearchingText(text) {
        searchInput.text = text;
        LauncherSearch.query = text;
    }

    function launchSelected() {
        const sec = root.selectedSection;
        const idx = root.sectionIndex;
        GlobalStates.overviewOpen = false;

        if (sec === "math" && LauncherSearch.mathResult) {
            Quickshell.clipboardText = LauncherSearch.mathResult.result;
        } else if (sec === "apps" && idx >= 0 && idx < root.displayedApps.length) {
            const item = root.displayedApps[idx];
            if (item?.execute) item.execute();
        } else if (sec === "files" && idx >= 0 && idx < fileSearch.results.length) {
            const item = fileSearch.results[idx];
            if (item?.execute) item.execute();
        } else if (sec === "settings" && idx >= 0 && idx < LauncherSearch.settingsResults.length) {
            const item = LauncherSearch.settingsResults[idx];
            if (item?.execute) item.execute();
        } else {
            if (LauncherSearch.mathResult) {
                Quickshell.clipboardText = LauncherSearch.mathResult.result;
            } else if (root.displayedApps.length > 0) {
                root.displayedApps[0].execute();
            } else if (fileSearch.results.length > 0) {
                fileSearch.results[0].execute();
            }
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            if (root.query.length > 0) {
                searchInput.text = "";
                LauncherSearch.query = "";
                event.accepted = true;
            } else {
                GlobalStates.overviewOpen = false;
                event.accepted = true;
            }
            return;
        }

        if (event.key === Qt.Key_Down) {
            root.navDown();
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Up) {
            root.navUp();
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Right) {
            if (root.navRight()) {
                event.accepted = true;
                return;
            }
        }

        if (event.key === Qt.Key_Left) {
            if (root.navLeft()) {
                event.accepted = true;
                return;
            }
        }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.launchSelected();
            event.accepted = true;
            return;
        }
    }

    StyledRectangularShadow {
        target: card
    }

    Rectangle {
        id: card
        width: root.panelWidth
        height: root.showResults ? Math.min(root.maxExpandedHeight, Math.max(root.searchBarHeight, contentColumn.implicitHeight + root.searchBarHeight + 38)) : root.searchBarHeight
        radius: 28
        color: Appearance.colors.colLayer0
        border.width: 1
        border.color: searchInput.activeFocus ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colOutline, 0.7)
        clip: true

        Behavior on height {
            NumberAnimation {
                duration: 240
                easing.type: Easing.OutCubic
            }
        }

        Behavior on border.color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        // Catch clicks on the card so backdrop doesn't close it
        MouseArea {
            anchors.fill: parent
        }

        Column {
            anchors.fill: parent
            spacing: 0

            // Top Search Bar (56px)
            Item {
                width: parent.width
                height: root.searchBarHeight

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 14
                    spacing: 12

                    MaterialSymbol {
                        iconSize: 24
                        text: "search"
                        color: searchInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                    }

                    ToolbarTextField {
                        id: searchInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        colBackground: "transparent"
                        font.pixelSize: Appearance.font.pixelSize.large

                        onTextChanged: {
                            LauncherSearch.query = text;
                        }

                        onAccepted: root.launchSelected()

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Down) {
                                root.navDown();
                                event.accepted = true;
                                return;
                            }
                            if (event.key === Qt.Key_Up) {
                                root.navUp();
                                event.accepted = true;
                                return;
                            }
                            if (event.key === Qt.Key_Right) {
                                if (root.selectedSection === "apps") {
                                    if (root.navRight()) {
                                        event.accepted = true;
                                        return;
                                    }
                                }
                            }
                            if (event.key === Qt.Key_Left) {
                                if (root.selectedSection === "apps") {
                                    if (root.navLeft()) {
                                        event.accepted = true;
                                        return;
                                    }
                                }
                            }
                        }

                        Component.onCompleted: {
                            forceActiveFocus();
                        }
                    }

                    RippleButton {
                        visible: root.query.length > 0
                        implicitWidth: 36
                        implicitHeight: 36
                        buttonRadius: 18
                        colBackground: "transparent"
                        colBackgroundHover: Appearance.colors.colLayer1Hover
                        onClicked: {
                            searchInput.text = "";
                            LauncherSearch.query = "";
                            searchInput.forceActiveFocus();
                        }

                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            iconSize: 20
                            text: "close"
                            color: Appearance.colors.colSubtext
                        }
                    }

                    RippleButton {
                        id: lensBtn
                        implicitWidth: 38
                        implicitHeight: 38
                        buttonRadius: 19
                        colBackground: lensBtn.hovered ? Appearance.colors.colLayer1Hover : "transparent"
                        colBackgroundHover: Appearance.colors.colLayer1Hover
                        colRipple: Appearance.colors.colPrimaryContainer

                        scale: lensBtn.down ? 0.9 : 1.0
                        Behavior on scale {
                            NumberAnimation { duration: 100 }
                        }

                        onClicked: {
                            GlobalStates.overviewOpen = false;
                            Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "search"]);
                        }

                        contentItem: Item {
                            anchors.centerIn: parent
                            implicitWidth: 22
                            implicitHeight: 22

                            Shape {
                                anchors.centerIn: parent
                                width: 24
                                height: 24
                                scale: 22 / 24
                                layer.enabled: true
                                layer.samples: 4

                                ShapePath {
                                    fillColor: lensBtn.hovered ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimary
                                    strokeColor: "transparent"

                                    Behavior on fillColor {
                                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                    }

                                    PathSvg {
                                        path: "M12 17.333q-1.667 0-2.833-1.166Q8 15 8 13.333q0-1.666 1.167-2.833Q10.333 9.333 12 9.333q1.667 0 2.833 1.167Q16 11.667 16 13.333q0 1.667-1.167 2.834-1.166 1.166-2.833 1.166Zm8 5.334q-1.1 0-1.883-.784-.784-.783-.784-1.883t.784-1.883q.783-.784 1.883-.784t1.883.784q.784.783.784 1.883t-.784 1.883q-.783.784-1.883.784ZM5.333 24q-2.2 0-3.766-1.567Q0 20.867 0 18.667V16h2.667v2.667q0 1.1.783 1.883.783.783 1.883.783H12V24Zm16-10.667V8q0-1.1-.783-1.883-.783-.784-1.883-.784H5.333q-1.1 0-1.883.784Q2.667 6.9 2.667 8v4H0V8q0-2.2 1.567-3.767 1.566-1.566 3.766-1.566H8L9.333 0h5.334L16 2.667h2.667q2.2 0 3.766 1.566Q24 5.8 24 8v5.333z"
                                    }
                                }
                            }
                        }

                        StyledToolTip {
                            text: Translation.tr("Google Lens / Region Search")
                        }
                    }
                }
            }

            // Divider line
            Rectangle {
                width: parent.width
                height: 1
                color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.8)
                visible: root.showResults
            }

            // Results Container
            Item {
                width: parent.width
                height: Math.max(0, card.height - root.searchBarHeight - 1)
                clip: true
                visible: root.showResults
                opacity: root.showResults ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutQuad
                    }
                }

                Flickable {
                    id: flickable
                    anchors {
                        fill: parent
                        topMargin: 12
                        bottomMargin: 16
                        leftMargin: 16
                        rightMargin: 16
                    }
                    contentWidth: width
                    contentHeight: contentColumn.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    Behavior on contentY {
                        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                    }

                    Column {
                        id: contentColumn
                        width: flickable.width
                        spacing: 14

                        // --- 1. APPS SECTION (Horizontal row / grid) ---
                        Column {
                            id: appsSection
                            width: parent.width
                            spacing: 8
                            visible: root.displayedApps.length > 0

                            RowLayout {
                                width: parent.width
                                visible: root.isSpaceOnly

                                StyledText {
                                    text: Translation.tr("All Applications (%1)").arg(LauncherSearch.appResults.length)
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    font.weight: Font.DemiBold
                                    color: Appearance.colors.colSubtext
                                }
                            }

                            Flow {
                                width: parent.width
                                spacing: 10

                                Repeater {
                                    model: root.displayedApps

                                    delegate: RippleButton {
                                        id: appTile
                                        required property var modelData
                                        required property int index

                                        readonly property bool isSelected: root.selectedSection === "apps" && root.sectionIndex === index
                                        width: Math.floor((contentColumn.width - 50) / 6)
                                        implicitHeight: 104
                                        buttonRadius: 16
                                        colBackground: isSelected ? Appearance.colors.colPrimaryContainer : (appTile.hovered ? Appearance.colors.colLayer1Hover : "transparent")
                                        colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                                        colRipple: Appearance.colors.colPrimaryContainerActive

                                        onHoveredChanged: {
                                            if (hovered) {
                                                root.selectedSection = "apps";
                                                root.sectionIndex = index;
                                            }
                                        }

                                        onClicked: {
                                            GlobalStates.overviewOpen = false;
                                            appTile.modelData.execute();
                                        }

                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            spacing: 4

                                            IconImage {
                                                Layout.alignment: Qt.AlignHCenter
                                                implicitWidth: 54
                                                implicitHeight: 54
                                                source: Quickshell.iconPath(appTile.modelData.iconName, "application-x-executable")
                                            }

                                            StyledText {
                                                Layout.preferredWidth: appTile.width - 12
                                                horizontalAlignment: Text.AlignHCenter
                                                elide: Text.ElideRight
                                                text: appTile.modelData.name
                                                font.pixelSize: Appearance.font.pixelSize.normal
                                                font.weight: appTile.isSelected ? Font.Medium : Font.Normal
                                                color: appTile.isSelected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer0
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // --- 2. CALCULATOR SECTION ---
                        Rectangle {
                            id: mathCard
                            width: parent.width
                            height: 72
                            radius: 18
                            readonly property bool isSelected: root.selectedSection === "math" && root.sectionIndex === 0
                            color: isSelected ? ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 0.5) : Appearance.colors.colLayer1
                            border.width: isSelected ? 2 : 1
                            border.color: isSelected ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colOutline, 0.8)
                            visible: LauncherSearch.mathResult !== null

                            Behavior on color {
                                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: {
                                    root.selectedSection = "math";
                                    root.sectionIndex = 0;
                                }
                                onClicked: {
                                    if (LauncherSearch.mathResult) {
                                        Quickshell.clipboardText = LauncherSearch.mathResult.result;
                                        GlobalStates.overviewOpen = false;
                                    }
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 18
                                anchors.rightMargin: 18
                                spacing: 16

                                MaterialShapeWrappedMaterialSymbol {
                                    iconSize: 26
                                    padding: 10
                                    shape: MaterialShape.Shape.Cookie4Sided
                                    color: Appearance.colors.colPrimaryContainer
                                    colSymbol: Appearance.colors.colOnPrimaryContainer
                                    text: "calculate"
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    StyledText {
                                        text: LauncherSearch.mathResult?.result ?? ""
                                        font.pixelSize: Appearance.font.pixelSize.huge
                                        font.weight: Font.Bold
                                        color: Appearance.colors.colPrimary
                                    }

                                    StyledText {
                                        text: `= ${LauncherSearch.mathResult?.expression ?? ""}`
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colSubtext
                                    }
                                }

                                RippleButton {
                                    implicitWidth: 36
                                    implicitHeight: 36
                                    buttonRadius: 18
                                    colBackground: Appearance.colors.colLayer2
                                    onClicked: {
                                        if (LauncherSearch.mathResult) {
                                            Quickshell.clipboardText = LauncherSearch.mathResult.result;
                                            GlobalStates.overviewOpen = false;
                                        }
                                    }

                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "content_copy"
                                        iconSize: 18
                                        color: Appearance.colors.colOnLayer0
                                    }

                                    StyledToolTip {
                                        text: Translation.tr("Copy result")
                                    }
                                }
                            }
                        }

                        // --- 3. FILES / DOCUMENTS SECTION ---
                        Column {
                            id: filesSection
                            width: parent.width
                            spacing: 6
                            visible: fileSearch.results.length > 0 && !root.isSpaceOnly

                            RowLayout {
                                width: parent.width

                                StyledText {
                                    text: Translation.tr("Documents (%1)").arg(fileSearch.results.length)
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    font.weight: Font.DemiBold
                                    color: Appearance.colors.colSubtext
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: fileColumn.implicitHeight + 8
                                radius: 18
                                color: Appearance.colors.colLayer1
                                border.width: 1
                                border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.8)

                                Column {
                                    id: fileColumn
                                    anchors {
                                        top: parent.top
                                        left: parent.left
                                        right: parent.right
                                        margins: 4
                                    }
                                    spacing: 2

                                    Repeater {
                                        model: fileSearch.results

                                        delegate: Rectangle {
                                            id: fileRow
                                            required property var modelData
                                            required property int index

                                            readonly property bool isSelected: root.selectedSection === "files" && root.sectionIndex === index

                                            width: fileColumn.width
                                            height: 58
                                            radius: 12
                                            color: isSelected ? Appearance.colors.colPrimaryContainer : (fileHoverArea.containsMouse ? Appearance.colors.colLayer1Hover : "transparent")

                                            MouseArea {
                                                id: fileHoverArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onEntered: {
                                                    root.selectedSection = "files";
                                                    root.sectionIndex = fileRow.index;
                                                }
                                                onClicked: {
                                                    GlobalStates.overviewOpen = false;
                                                    fileRow.modelData.execute();
                                                }
                                            }

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 12
                                                anchors.rightMargin: 10
                                                spacing: 12

                                                Rectangle {
                                                    Layout.preferredWidth: 40
                                                    Layout.preferredHeight: 40
                                                    radius: 10
                                                    color: fileRow.isSelected ? Appearance.colors.colPrimary : Appearance.colors.colLayer2

                                                    MaterialSymbol {
                                                        anchors.centerIn: parent
                                                        iconSize: 22
                                                        text: fileRow.modelData.icon
                                                        color: fileRow.isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colPrimary
                                                    }
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 0

                                                    StyledText {
                                                        Layout.fillWidth: true
                                                        elide: Text.ElideRight
                                                        text: fileRow.modelData.name
                                                        font.pixelSize: Appearance.font.pixelSize.normal
                                                        font.weight: fileRow.isSelected ? Font.Medium : Font.Normal
                                                        color: fileRow.isSelected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer0
                                                    }

                                                    StyledText {
                                                        Layout.fillWidth: true
                                                        elide: Text.ElideMiddle
                                                        text: fileRow.modelData.dir
                                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                                        color: fileRow.isSelected ? ColorUtils.transparentize(Appearance.colors.colOnPrimaryContainer, 0.25) : Appearance.colors.colSubtext
                                                    }
                                                }

                                                RippleButton {
                                                    implicitWidth: 32
                                                    implicitHeight: 32
                                                    buttonRadius: 16
                                                    colBackground: "transparent"
                                                    colBackgroundHover: fileRow.isSelected ? Appearance.colors.colPrimaryContainerHover : Appearance.colors.colLayer1Hover
                                                    onClicked: fileRow.modelData.openFolder()

                                                    contentItem: MaterialSymbol {
                                                        anchors.centerIn: parent
                                                        iconSize: 18
                                                        text: "folder_open"
                                                        color: fileRow.isSelected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                                                    }

                                                    StyledToolTip {
                                                        text: Translation.tr("Open folder")
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // --- 4. SETTINGS SECTION ---
                        Column {
                            id: settingsSection
                            width: parent.width
                            spacing: 6
                            visible: LauncherSearch.settingsResults.length > 0 && !root.isSpaceOnly

                            StyledText {
                                text: Translation.tr("Settings")
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colSubtext
                            }

                            Rectangle {
                                width: parent.width
                                height: settingsColumn.implicitHeight + 8
                                radius: 18
                                color: Appearance.colors.colLayer1
                                border.width: 1
                                border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.8)

                                Column {
                                    id: settingsColumn
                                    anchors {
                                        top: parent.top
                                        left: parent.left
                                        right: parent.right
                                        margins: 4
                                    }
                                    spacing: 2

                                    Repeater {
                                        model: LauncherSearch.settingsResults

                                        delegate: Rectangle {
                                            id: settingsRow
                                            required property var modelData
                                            required property int index

                                            readonly property bool isSelected: root.selectedSection === "settings" && root.sectionIndex === index
                                            width: settingsColumn.width
                                            height: 52
                                            radius: 12
                                            color: isSelected ? Appearance.colors.colPrimaryContainer : (setHover.containsMouse ? Appearance.colors.colLayer1Hover : "transparent")

                                            MouseArea {
                                                id: setHover
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onEntered: {
                                                    root.selectedSection = "settings";
                                                    root.sectionIndex = settingsRow.index;
                                                }
                                                onClicked: {
                                                    settingsRow.modelData.execute();
                                                }
                                            }

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 12
                                                anchors.rightMargin: 12
                                                spacing: 12

                                                MaterialSymbol {
                                                    iconSize: 22
                                                    text: "settings"
                                                    color: settingsRow.isSelected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colPrimary
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 0

                                                    StyledText {
                                                        text: settingsRow.modelData.name
                                                        font.pixelSize: Appearance.font.pixelSize.normal
                                                        font.weight: settingsRow.isSelected ? Font.Medium : Font.Normal
                                                        color: settingsRow.isSelected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer0
                                                    }

                                                    StyledText {
                                                        text: settingsRow.modelData.comment
                                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                                        color: settingsRow.isSelected ? ColorUtils.transparentize(Appearance.colors.colOnPrimaryContainer, 0.25) : Appearance.colors.colSubtext
                                                    }
                                                }

                                                MaterialSymbol {
                                                    iconSize: 18
                                                    text: "arrow_forward"
                                                    color: settingsRow.isSelected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
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
        }
    }
}
