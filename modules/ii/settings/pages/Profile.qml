import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.models
import Quickshell.Hyprland

ContentPage {
    id: page
    property string descriptionMode: {
        if (Config.options.profile.descriptionText === "::uptime::") return "uptime"
        return "distro"
    }
    property string hostnameInput: SystemInfo.hostname

    FolderListModel {
        id: avatarFolderModel
        folder: Config.options.profile.avatarPath !== "" ? Qt.resolvedUrl(Config.options.profile.avatarPath) : ""
        showDirs: false
        nameFilters: ["*.png", "*.svg", "*.jpg", "*.jpeg", "*.webp"]
    }

    Process {
        id: hostnameSetProc
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                SystemInfo.refreshHostname()
            }
        }
    }

    function applyHostname() {
        const newName = page.hostnameInput.trim()
        if (newName.length === 0 || newName === SystemInfo.hostname) return
        hostnameSetProc.command = ["hostnamectl", "set-hostname", newName]
        hostnameSetProc.running = true
    }

    Connections {
        target: SystemInfo
        function onHostnameChanged() {
            hostnameField.value = Qt.binding(() => SystemInfo.hostname)
        }
    }

    Component.onCompleted: Users.refresh()

    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        ContentSection {
            icon: "person"
            shape: MaterialShape.Shape.Circle
            title: Translation.tr("Avatar")

            GroupedList {
                ConfigTextArea {
                    id: avatarField
                    Layout.fillWidth: true
                    buttonIcon: "folder_open"
                    text: Translation.tr("Avatar path")
                    placeholderText: Translation.tr("Leave empty to use ~/.face, e.g. /home/youruser/Pictures/avatar")
                    value: Config.options.profile.avatarPath
                    onValueChanged: {
                        avatarDebounceTimer.restart()
                    }

                    Timer {
                        id: avatarDebounceTimer
                        interval: 1000
                        repeat: false
                        onTriggered: {
                            Config.options.profile.avatarPath = avatarField.value
                        }
                    }

                    confirmButtonVisible: Config.options.profile.avatarPath !== ""
                    confirmButtonIcon: "add"
                    onConfirmClicked: {
                        GlobalStates.settingsOpen = false
                        if (Config.options.profile.avatarPath !== "") {
                            Quickshell.execDetached(["dolphin", Config.options.profile.avatarPath])
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: Config.options.profile.avatarPath === "" ? placeholderCol.implicitHeight : avatarFlow.implicitHeight

                    Flow {
                        id: avatarFlow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Repeater {
                            model: avatarFolderModel
                            delegate: Rectangle {
                                required property string fileName
                                required property string filePath
                                width: 64
                                height: 64
                                radius: width / 2
                                color: Appearance.colors.colLayer2

                                property bool isSelected: FileUtils.trimFileProtocol(filePath.toString()) === Config.options.profile.avatarPicture

                                Image {
                                    id: avatarImage
                                    anchors.fill: parent
                                    source: filePath
                                    fillMode: Image.PreserveAspectCrop
                                    sourceSize.width: avatarImage.width * 2
                                    sourceSize.height: avatarImage.height * 2
                                    layer.enabled: true
                                    layer.effect: OpacityMask {
                                        maskSource: Rectangle {
                                            width: 64; height: width; radius: width / 2 
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: parent.isSelected
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.rightMargin: 2
                                    anchors.bottomMargin: 2
                                    width: 20
                                    height: width
                                    radius: width / 2
                                    color: Appearance.colors.colPrimary

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "check"
                                        iconSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colOnPrimary
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Config.options.profile.avatarPicture = FileUtils.trimFileProtocol(filePath.toString())
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        id: placeholderCol
                        visible: Config.options.profile.avatarPath === ""
                        anchors.centerIn: parent
                        z: 1
                        spacing: 4

                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: "image"
                            iconSize: 32
                            color: Appearance.colors.colSubtext
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: Translation.tr("Pick a folder above to see avatars here")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Identity")

                GroupedList {
                    ConfigTextArea {
                        id: displayNameField
                        buttonIcon: "badge"
                        placeholderText: SystemInfo.username
                        text: Translation.tr("Display name")
                        value: Config.options.profile.displayName

                        Timer {
                            id: displayNameDebounceTimer
                            interval: 800
                            running: false
                            onTriggered: {
                                Config.options.profile.displayName = displayNameField.value
                            }
                        }
                        onValueChanged: displayNameDebounceTimer.restart()
                    }

                    ConfigTextArea {
                        id: hostnameField
                        Layout.fillWidth: true
                        buttonIcon: "dns"
                        placeholderText: SystemInfo.hostname
                        text: Translation.tr("Hostname")
                        description: Translation.tr("Requires authentication to change")
                        value: page.hostnameInput
                        onValueChanged: page.hostnameInput = value

                        confirmButtonVisible: page.hostnameInput.trim() !== "" && page.hostnameInput.trim() !== SystemInfo.hostname
                        onConfirmClicked: {
                            page.applyHostname();
                        }
                    }

                    ConfigSelectionArray {
                        text: Translation.tr("Description text")
                        icon: "subtitles"
                        currentValue: page.descriptionMode
                        onSelected: newValue => {
                            page.descriptionMode = newValue
                            if (newValue === "distro") Config.options.profile.descriptionText = "::distro::"
                            if (newValue === "uptime") Config.options.profile.descriptionText = "::uptime::"
                        }
                        options: [
                            { displayName: Translation.tr("Distro"), icon: "deployed_code", value: "distro" },
                            { displayName: Translation.tr("Uptime"), icon: "timelapse",     value: "uptime" },
                        ]
                    }
                }
            }
        }

        // ── Users ────────────────────────────────────────────────────────
        ContentSection {
            icon: "group"
            shape: MaterialShape.Shape.Clover4Leaf
            title: Translation.tr("Users")

            // Dynamic list: NOT inside GroupedList (it reparents static
            // children only) — card + ColumnLayout + Repeater instead
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: usersCol.implicitHeight + 20
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1

                ColumnLayout {
                    id: usersCol
                    anchors { fill: parent; margins: 10 }
                    spacing: 2

                    StyledText {
                        visible: Users.users.length === 0
                        Layout.leftMargin: 8
                        text: Translation.tr("No users found")
                        color: Appearance.colors.colSubtext
                    }

                    Repeater {
                        model: Users.users
                        delegate: ColumnLayout {
                            id: userRow
                            required property var modelData
                            property bool confirmingAdmin: false
                            property bool confirmingDelete: false
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                MaterialSymbol {
                                    Layout.leftMargin: 8
                                    text: userRow.modelData.isAdmin ? "shield_person" : "person"
                                    iconSize: Appearance.font.pixelSize.huge
                                    color: userRow.modelData.isCurrent ? Appearance.colors.colPrimary : Appearance.colors.colOnSecondaryContainer
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        StyledText {
                                            text: userRow.modelData.username
                                            font.weight: Font.Medium
                                            color: Appearance.colors.colOnSecondaryContainer
                                        }
                                        Rectangle {
                                            visible: userRow.modelData.isCurrent
                                            color: Appearance.colors.colPrimaryContainer
                                            radius: Appearance.rounding.full
                                            implicitWidth: youBadgeText.implicitWidth + 12
                                            implicitHeight: youBadgeText.implicitHeight + 4
                                            StyledText {
                                                id: youBadgeText
                                                anchors.centerIn: parent
                                                text: Translation.tr("you")
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                color: Appearance.colors.colOnPrimaryContainer
                                            }
                                        }
                                        Rectangle {
                                            visible: userRow.modelData.isAdmin
                                            color: Appearance.colors.colSecondaryContainer
                                            radius: Appearance.rounding.full
                                            implicitWidth: adminBadgeText.implicitWidth + 12
                                            implicitHeight: adminBadgeText.implicitHeight + 4
                                            StyledText {
                                                id: adminBadgeText
                                                anchors.centerIn: parent
                                                text: Translation.tr("admin")
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                color: Appearance.colors.colOnSecondaryContainer
                                            }
                                        }
                                        Item { Layout.fillWidth: true }
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colSubtext
                                        elide: Text.ElideRight
                                        text: {
                                            let parts = [Translation.tr("UID %1").arg(userRow.modelData.uid)]
                                            if (userRow.modelData.fullName !== "") parts.push(userRow.modelData.fullName)
                                            parts.push(userRow.modelData.home)
                                            return parts.join(" • ")
                                        }
                                    }
                                }

                                // Admin toggle, two-step confirm. De-admining
                                // yourself is refused (service guard) — hide it.
                                RippleButtonWithIcon {
                                    visible: !userRow.confirmingAdmin && !userRow.confirmingDelete
                                        && !(userRow.modelData.isCurrent && userRow.modelData.isAdmin)
                                    materialIcon: userRow.modelData.isAdmin ? "remove_moderator" : "add_moderator"
                                    mainText: ""
                                    enabled: !Users.actionRunning
                                    onClicked: userRow.confirmingAdmin = true
                                    StyledToolTip {
                                        text: userRow.modelData.isAdmin
                                            ? Translation.tr("Remove admin rights (wheel group)")
                                            : Translation.tr("Make administrator (wheel group)")
                                    }
                                }
                                DialogButton {
                                    visible: userRow.confirmingAdmin
                                    buttonText: userRow.modelData.isAdmin
                                        ? Translation.tr("Remove admin from %1?").arg(userRow.modelData.username)
                                        : Translation.tr("Make %1 admin?").arg(userRow.modelData.username)
                                    colText: userRow.modelData.isAdmin ? Appearance.m3colors.m3error : Appearance.colors.colPrimary
                                    onClicked: {
                                        userRow.confirmingAdmin = false
                                        Users.setAdmin(userRow.modelData.username, !userRow.modelData.isAdmin)
                                    }
                                }
                                DialogButton {
                                    visible: userRow.confirmingAdmin
                                    buttonText: Translation.tr("Cancel")
                                    onClicked: userRow.confirmingAdmin = false
                                }

                                // Delete (never for the current user)
                                RippleButtonWithIcon {
                                    visible: !userRow.modelData.isCurrent && !userRow.confirmingAdmin && !userRow.confirmingDelete
                                    materialIcon: "delete"
                                    mainText: ""
                                    enabled: !Users.actionRunning
                                    onClicked: userRow.confirmingDelete = true
                                    StyledToolTip {
                                        text: Translation.tr("Delete this user")
                                    }
                                }
                            }

                            // Delete confirm area — destructive, so it spells
                            // out the username and what will happen
                            ColumnLayout {
                                visible: userRow.confirmingDelete
                                Layout.fillWidth: true
                                Layout.leftMargin: 40
                                Layout.rightMargin: 8
                                Layout.bottomMargin: 6
                                spacing: 4

                                StyledText {
                                    Layout.fillWidth: true
                                    wrapMode: Text.Wrap
                                    color: Appearance.m3colors.m3error
                                    text: Translation.tr("This permanently deletes the user account \"%1\". This cannot be undone.").arg(userRow.modelData.username)
                                }
                                ConfigSwitch {
                                    id: removeHomeSwitch
                                    buttonIcon: "folder_delete"
                                    text: Translation.tr("Also delete the home directory (%1)").arg(userRow.modelData.home)
                                    checked: false
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    Item { Layout.fillWidth: true }
                                    DialogButton {
                                        buttonText: Translation.tr("Cancel")
                                        onClicked: userRow.confirmingDelete = false
                                    }
                                    DialogButton {
                                        buttonText: Translation.tr("Delete %1").arg(userRow.modelData.username)
                                        colText: Appearance.m3colors.m3error
                                        onClicked: {
                                            userRow.confirmingDelete = false
                                            Users.deleteUser(userRow.modelData.username, removeHomeSwitch.checked)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            GroupedList {
                // Change password (current user) — reuses the existing
                // Config.options.apps.changePassword terminal flow
                RowLayout {
                    spacing: 10
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8

                    MaterialSymbol {
                        text: "password"
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnSecondaryContainer
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        StyledText {
                            Layout.fillWidth: true
                            text: Translation.tr("Change password")
                            color: Appearance.colors.colOnSecondaryContainer
                        }
                        StyledText {
                            Layout.fillWidth: true
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            text: Translation.tr("Opens a terminal running passwd for %1").arg(Users.currentUsername !== "" ? Users.currentUsername : SystemInfo.username)
                        }
                    }
                    RippleButtonWithIcon {
                        materialIcon: "terminal"
                        mainText: Translation.tr("Change")
                        onClicked: Session.changePassword()
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Create user")

                GroupedList {
                    ConfigTextArea {
                        id: newUserField
                        Layout.fillWidth: true
                        buttonIcon: "person_add"
                        text: Translation.tr("Username")
                        placeholderText: Translation.tr("lowercase letters, digits, - and _")
                        onValueChanged: createUserRow.confirming = false
                    }
                    ConfigSwitch {
                        id: newUserAdminSwitch
                        buttonIcon: "shield_person"
                        text: Translation.tr("Administrator (wheel group)")
                        checked: false
                    }
                    StyledText {
                        visible: newUserField.value.trim() !== "" && !Users.isValidUsername(newUserField.value.trim())
                        Layout.leftMargin: 8
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: Appearance.m3colors.m3error
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        text: Translation.tr("Invalid username: must start with a lowercase letter or _, followed by lowercase letters, digits, - or _")
                    }
                    StyledText {
                        visible: Users.userExists(newUserField.value.trim())
                        Layout.leftMargin: 8
                        Layout.fillWidth: true
                        color: Appearance.m3colors.m3error
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        text: Translation.tr("A user with this name already exists")
                    }
                    RowLayout {
                        id: createUserRow
                        property bool confirming: false
                        readonly property string newUsername: newUserField.value.trim()
                        spacing: 10
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8

                        RippleButtonWithIcon {
                            visible: !createUserRow.confirming
                            materialIcon: "person_add"
                            mainText: Translation.tr("Create user")
                            enabled: !Users.actionRunning
                                && Users.isValidUsername(createUserRow.newUsername)
                                && !Users.userExists(createUserRow.newUsername)
                            onClicked: createUserRow.confirming = true
                        }
                        DialogButton {
                            visible: createUserRow.confirming
                            buttonText: newUserAdminSwitch.checked
                                ? Translation.tr("Create admin user \"%1\"?").arg(createUserRow.newUsername)
                                : Translation.tr("Create user \"%1\"?").arg(createUserRow.newUsername)
                            onClicked: {
                                createUserRow.confirming = false
                                if (Users.createUser(createUserRow.newUsername, newUserAdminSwitch.checked)) {
                                    newUserField.value = ""
                                    newUserAdminSwitch.checked = false
                                }
                            }
                        }
                        DialogButton {
                            visible: createUserRow.confirming
                            buttonText: Translation.tr("Cancel")
                            onClicked: createUserRow.confirming = false
                        }
                        Item { Layout.fillWidth: true }
                    }
                }
            }

            StyledText {
                visible: Users.lastActionOutput !== ""
                Layout.leftMargin: 8
                Layout.fillWidth: true
                text: Users.lastActionOutput
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }

            StyledText {
                Layout.leftMargin: 8
                Layout.fillWidth: true
                text: Translation.tr("User changes use pkexec — a system authentication prompt will appear")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }
        }

        ContentSection {
            icon: "wall_art"
            shape: MaterialShape.Shape.Pentagon
            title: Translation.tr("Presets")

            GroupedList {
                ConfigTextArea {
                    id: presetNameField
                    Layout.fillWidth: true
                    fieldWidth: 300
                    buttonIcon: "newsmode"
                    text: Translation.tr("New")
                    placeholderText: Translation.tr("Name, description (optional)")

                    confirmButtonVisible: presetNameField.value.trim() !== ""
                    confirmButtonIcon: "save"
                    onConfirmClicked: {
                        Presets.save(presetNameField.value)
                        presetNameField.value = ""
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.topMargin: 40
                visible: Presets.folderModel.count === 0
                horizontalAlignment: Text.AlignHCenter
                text: Translation.tr("No presets yet")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.normal
            }

            Flow {
                Layout.topMargin: 10
                Layout.fillWidth: true
                width: parent.width
                spacing: 12
                visible: Presets.folderModel.count > 0

                Repeater {
                    model: Presets.folderModel
                    delegate: PresetsCard {
                        id: presetDelegate
                        required property string fileName
                        required property string filePath

                        property string presetName: fileName.replace(".json", "")
                        property string presetWallpaper: ""
                        property string presetDescription: ""

                        FileView {
                            path: presetDelegate.filePath
                            onLoaded: {
                                try {
                                    const data = JSON.parse(text())
                                    const rawWallpaper = data?.background?.wallpaperPath ?? ""
                                    const isVideo = /\.(mp4|webm|mkv|avi|mov)$/i.test(rawWallpaper)
                                    presetDelegate.presetWallpaper = isVideo
                                        ? (data?.background?.thumbnailPath ?? "")
                                        : rawWallpaper
                                    presetDelegate.presetDescription = data?._presetMeta?.description ?? ""
                                } catch (e) {
                                    console.log("Failed to parse preset:", e)
                                }
                            }
                        }

                        imageSource: presetDelegate.presetWallpaper
                        title: presetDelegate.presetName
                        description: presetDelegate.presetDescription !== "" ? presetDelegate.presetDescription : Translation.tr("Saved preset")
                        onApply: () => Presets.apply(presetDelegate.presetName)
                        onRemove: () => Presets.remove(presetDelegate.presetName)
                    }
                }
            }
        }
    }
}