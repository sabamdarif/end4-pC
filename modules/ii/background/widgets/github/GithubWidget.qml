import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root
    configEntryName: "github"
    hoverEnabled: true

    property string contributionCount: "0"
    property var contributions: []
    property bool loading: false
    property bool editingUsername: false

    property string hoveredDate: ""
    property string hoveredInfo: ""
    property int hoveredLevel: -1

    readonly property bool hasUsername: (root.configEntry && root.configEntry.username && root.configEntry.username.trim() !== "")
    readonly property bool editing: !hasUsername || editingUsername
    draggable: placementStrategy === "free" && !Config.options.background.widgetsLocked && !root.editing

    onEditingChanged: {
        GlobalStates.desktopWidgetKeyboardFocus = root.editing;
        if (root.editing) {
            Qt.callLater(() => usernameInput.forceActiveFocus());
        }
    }

    Component.onDestruction: {
        if (root.editing) {
            GlobalStates.desktopWidgetKeyboardFocus = false;
        }
    }

    Connections {
        target: GlobalStates
        function onScreenLockedChanged() {
            if (GlobalStates.screenLocked && root.hasUsername) {
                root.editingUsername = false;
            }
        }
    }

    implicitWidth: 612
    implicitHeight: 148

    function getHoveredTitle() {
        if (root.hoveredInfo === "") return "";
        const parts = root.hoveredInfo.split(" on ");
        return parts[0];
    }

    function getHoveredSubtitle() {
        if (root.hoveredInfo === "") return "";
        const parts = root.hoveredInfo.split(" on ");
        let sub = parts[1] || "";
        if (sub.endsWith(".")) {
            sub = sub.slice(0, -1);
        }
        return sub;
    }

    function getColorForLevel(level) {
        switch (level) {
            case 1:
                return "#0e4429";
            case 2:
                return "#006d32";
            case 3:
                return "#26a641";
            case 4:
                return "#39d353";
            default:
                return ColorUtils.mix(Appearance.colors.colOnPrimaryContainer, Appearance.colors.colPrimaryContainer, 0.08);
        }
    }

    function saveUsername(newUsername) {
        const trimmed = (newUsername || "").trim();
        if (trimmed.length > 0) {
            root.configEntry.username = trimmed;
            root.editingUsername = false;
            root.fetchContributions();
        }
    }

    function fetchContributions() {
        if (!root.configEntry || !root.configEntry.username || root.configEntry.username.trim() === "") {
            root.loading = false;
            root.contributionCount = "0";
            root.contributions = [];
            return;
        }
        root.loading = true;

        const xhr = new XMLHttpRequest();
        const url = "https://github.com/users/" + root.configEntry.username.trim() + "/contributions";
        xhr.open("GET", url, true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    const html = xhr.responseText;

                    const countMatch = html.match(/js-contribution-activity-description"[^>]*>\s*([\d,]+)\s*contributions/);
                    if (countMatch) {
                        root.contributionCount = countMatch[1];
                    } else {
                        const countMatchAlt = html.match(/(\d+)\s+contributions\s+in\s+the\s+last\s+year/i);
                        if (countMatchAlt) {
                            root.contributionCount = countMatchAlt[1];
                        }
                    }

                    const tooltipMap = {};
                    const tooltipMatches = html.match(/<tool-tip[^>]*for="([^"]*)"[^>]*>([^<]*)<\/tool-tip>/g);
                    if (tooltipMatches) {
                        const tooltipRegex = /<tool-tip[^>]*for="([^"]*)"[^>]*>([^<]*)<\/tool-tip>/;
                        for (let j = 0; j < tooltipMatches.length; j++) {
                            const tm = tooltipMatches[j].match(tooltipRegex);
                            if (tm) {
                                tooltipMap[tm[1]] = tm[2].trim();
                            }
                        }
                    }

                    const tdMatches = html.match(/<td[^>]*class="[^"]*ContributionCalendar-day[^"]*"[^>]*>/g);
                    if (tdMatches) {
                        const parsedData = [];
                        for (let i = 0; i < tdMatches.length; i++) {
                            const td = tdMatches[i];
                            const dateMatch = td.match(/data-date="([^"]*)"/);
                            const levelMatch = td.match(/data-level="([0-9])"/);
                            const idMatch = td.match(/id="([^"]*)"/);

                            if (dateMatch && levelMatch) {
                                const date = dateMatch[1];
                                const level = parseInt(levelMatch[1]);
                                const id = idMatch ? idMatch[1] : "";
                                const info = tooltipMap[id] || (level + " contributions on " + date);

                                parsedData.push({
                                    date: date,
                                    level: level,
                                    info: info
                                });
                            }
                        }
                        root.contributions = parsedData;
                        root.loading = false;
                    }
                } else {
                    root.loading = false;
                }
            }
        };
        xhr.send();
    }

    property string currentUsername: (root.configEntry && root.configEntry.username) ? root.configEntry.username : ""
    onCurrentUsernameChanged: {
        if (currentUsername !== "") {
            fetchContributions();
        } else {
            root.contributions = [];
            root.contributionCount = "0";
            root.loading = false;
        }
    }

    Component.onCompleted: {
        if (root.editing) {
            GlobalStates.desktopWidgetKeyboardFocus = true;
            Qt.callLater(() => usernameInput.forceActiveFocus());
        }
        fetchContributions();
    }

    Timer {
        id: refreshTimer
        interval: 3600000
        running: true
        repeat: true
        onTriggered: fetchContributions()
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Appearance.rounding ? Appearance.rounding.verylarge : 30
        color: Appearance.colors.colPrimaryContainer

        WindowGlass {
            anchors.fill: parent
            cardRadius: parent ? parent.radius : 0
            tint: parent ? parent.color : "transparent"
        }

        StyledRectangularShadow {
            target: card
            z: -2
        }

        ColumnLayout {
            anchors {
                fill: parent
                margins: 14
            }
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                MaterialShape {
                    id: avatarShape
                    implicitWidth: 32
                    implicitHeight: 32
                    color: Appearance.colors.colPrimary
                    shape: MaterialShape.Shape.Cookie4Sided

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: MaterialShape {
                            width: avatarShape.width
                            height: avatarShape.height
                            shape: MaterialShape.Shape.Cookie4Sided
                        }
                    }

                    Image {
                        id: avatarImg
                        anchors.fill: parent
                        source: root.hasUsername ? `https://github.com/${root.configEntry.username.trim()}.png?size=64` : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        visible: root.hasUsername && status === Image.Ready
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "code"
                        iconSize: 20
                        color: Appearance.colors.colOnPrimary
                        visible: !avatarImg.visible
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: root.hasUsername ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (root.hasUsername) {
                                Quickshell.execDetached(["xdg-open", `https://github.com/${root.configEntry.username.trim()}`]);
                            }
                        }
                    }
                }

                ColumnLayout {
                    spacing: -2
                    Layout.fillWidth: true

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        StyledText {
                            text: root.hoveredDate !== ""
                                ? root.getHoveredTitle()
                                : (root.hasUsername ? "@" + root.configEntry.username : Translation.tr("GitHub Heatmap"))
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnPrimaryContainer
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            id: editBtn
                            visible: root.hasUsername && !root.editing && root.hoveredDate === ""
                            implicitWidth: 20
                            implicitHeight: 20
                            radius: 10
                            color: editBtnMouse.containsMouse
                                ? ColorUtils.mix(Appearance.colors.colOnPrimaryContainer, Appearance.colors.colPrimaryContainer, 0.15)
                                : "transparent"

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "edit"
                                iconSize: 13
                                color: Appearance.colors.colOnPrimaryContainer
                            }

                            MouseArea {
                                id: editBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.editingUsername = true;
                                    usernameInput.text = root.configEntry.username;
                                    usernameInput.forceActiveFocus();
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    StyledText {
                        text: root.hoveredDate !== ""
                            ? root.getHoveredSubtitle()
                            : (!root.hasUsername
                                ? Translation.tr("Set your username to view contributions")
                                : (root.loading
                                    ? Translation.tr("Fetching latest data...")
                                    : Translation.tr("%1 contributions this year").arg(root.contributionCount)))
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colOnPrimaryContainer
                        opacity: 0.6
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                RowLayout {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 40, 360)
                    visible: root.editing
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 38
                        radius: Appearance.rounding ? Appearance.rounding.small : 10
                        color: Appearance.colors.colLayer0
                        border.width: 1
                        border.color: usernameInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: 12
                                rightMargin: 8
                            }
                            spacing: 8

                            MaterialSymbol {
                                text: "alternate_email"
                                iconSize: 18
                                color: Appearance.colors.colSubtext
                            }

                            TextField {
                                id: usernameInput
                                Layout.fillWidth: true
                                placeholderText: Translation.tr("GitHub username...")
                                text: (root.configEntry && root.configEntry.username) ? root.configEntry.username : ""
                                color: Appearance.colors.colOnLayer0
                                placeholderTextColor: Appearance.colors.colSubtext
                                background: null
                                selectByMouse: true
                                font.family: Appearance.font.family.main
                                font.pixelSize: Appearance.font.pixelSize.normal
                                onAccepted: root.saveUsername(text)
                                Keys.onEscapePressed: {
                                    if (root.hasUsername) {
                                        root.editingUsername = false;
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: saveBtn
                        implicitWidth: 38
                        implicitHeight: 38
                        radius: Appearance.rounding ? Appearance.rounding.small : 10
                        color: saveBtnMouse.containsPress
                            ? Appearance.colors.colPrimaryActive
                            : (saveBtnMouse.containsMouse ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimary)

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "arrow_forward"
                            iconSize: 18
                            color: Appearance.colors.colOnPrimary
                        }

                        MouseArea {
                            id: saveBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.saveUsername(usernameInput.text)
                        }
                    }

                    Rectangle {
                        id: cancelBtn
                        visible: root.hasUsername && root.editingUsername
                        implicitWidth: 38
                        implicitHeight: 38
                        radius: Appearance.rounding ? Appearance.rounding.small : 10
                        color: cancelBtnMouse.containsPress
                            ? Appearance.colors.colLayer1Active
                            : (cancelBtnMouse.containsMouse ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer0)

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "close"
                            iconSize: 18
                            color: Appearance.colors.colOnLayer0
                        }

                        MouseArea {
                            id: cancelBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.editingUsername = false
                        }
                    }
                }

                Item {
                    anchors.fill: parent
                    visible: !root.editing

                    MaterialLoadingIndicator {
                        anchors.centerIn: parent
                        visible: root.loading
                        loading: root.loading
                    }

                    Grid {
                        id: grid
                        anchors.centerIn: parent
                        columns: 53
                        rows: 7
                        rowSpacing: 3
                        columnSpacing: 3
                        visible: !root.loading

                        Repeater {
                            model: root.contributions
                            delegate: Rectangle {
                                required property var modelData
                                width: 8
                                height: 8
                                radius: 2
                                color: root.getColorForLevel(modelData.level)

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: {
                                        root.hoveredDate = modelData.date;
                                        root.hoveredInfo = modelData.info;
                                        root.hoveredLevel = modelData.level;
                                    }
                                    onExited: {
                                        root.hoveredDate = "";
                                        root.hoveredInfo = "";
                                        root.hoveredLevel = -1;
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
