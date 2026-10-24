import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.panels.lock
import qs.modules.ii.bar as Bar
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray

MouseArea {
    id: root
    required property LockContext context

    // Effective wallpaper: lock-specific if set, otherwise fall back to desktop wallpaper
    readonly property string effectiveWallpaperSource: {
        const lockWall = Config.options.background.lockWall;
        const desktopWall = Wallpapers.confirmedPath || Config.options.background.wallpaperPath;
        return "file://" + (lockWall !== "" ? lockWall : desktopWall);
    }

    // Blurred wallpaper background, matching the blur settings from Background.qml
    Image {
        id: lockWallpaper
        anchors.fill: parent
        source: root.effectiveWallpaperSource
        fillMode: Image.PreserveAspectCrop
        cache: true
        smooth: true
        asynchronous: true
        layer.enabled: true
        visible: !blurOverlay.active
    }

    Loader {
        id: blurOverlay
        active: Config.options.lock.blur.enable
        anchors.fill: parent
        scale: Config.options.lock.blur.extraZoom
        sourceComponent: GaussianBlur {
            source: lockWallpaper
            radius: Config.options.lock.blur.radius
            samples: Config.options.lock.blur.size
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.3)
            }
        }
    }
    property bool active: false
    property bool showInputField: active || context.currentText.length > 0
    readonly property bool requirePasswordToPower: Config.options.lock.security.requirePasswordToPower
    readonly property MprisPlayer activePlayer: {
        const preferred = Config.options.bar.media.preferredPlayer.trim().toLowerCase()
        if (preferred.length === 0) return MprisController.activePlayer
        const _ = MprisController.players.count
        for (const p of MprisController.players) {
            if ((p.identity ?? "").toLowerCase().includes(preferred) ||
                (p.desktopEntry ?? "").toLowerCase().includes(preferred))
                return p
        }
        return MprisController.activePlayer
    }

    // Whether a player with a title is currently active and media display is enabled
    readonly property bool mediaPlayerAvailable: Config.options.lock.showMedia && root.activePlayer !== null && (root.activePlayer.trackTitle ?? "").length > 0

    // Gate that keeps the Loader alive during exit animation
    property bool mediaLoaderActive: false
    property MprisPlayer currentLockPlayer: null

    onMediaPlayerAvailableChanged: {
        if (mediaPlayerAvailable) {
            currentLockPlayer = root.activePlayer
            mediaLoaderActive = true
        } else {
            if (lockscreenMediaController.item) {
                entryAnim.stop()
                mediaExitAnim.restart()
            } else {
                mediaLoaderActive = false
                currentLockPlayer = null
            }
        }
    }

    onActivePlayerChanged: {
        if (mediaPlayerAvailable && root.activePlayer !== null) {
            currentLockPlayer = root.activePlayer
        }
    }

    // Visualizer data for lockscreen media controls
    property list<real> visualizerPoints: []

    Process {
        id: cavaProc
        running: root.mediaLoaderActive && root.mediaPlayerAvailable
        onRunningChanged: {
            if (!cavaProc.running)
                root.visualizerPoints = [];
        }
        command: ["cava", "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config.txt`]
        stdout: SplitParser {
            onRead: data => {
                let points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
                root.visualizerPoints = points;
            }
        }
    }

    // Force focus on entry
    function forceFieldFocus() {
        passwordBox.forceActiveFocus();
    }
    Connections {
        target: context
        function onShouldReFocus() {
            forceFieldFocus();
        }
    }
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onPressed: mouse => {
        forceFieldFocus();
    }
    onPositionChanged: mouse => {
        forceFieldFocus();
    }

    // Toolbar appearing animation
    property real toolbarScale: 0.9
    property real toolbarOpacity: 0
    Behavior on toolbarScale {
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
        }
    }
    Behavior on toolbarOpacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    // Init
    Component.onCompleted: {
        forceFieldFocus();
        toolbarScale = 1;
        toolbarOpacity = 1;
        if (root.mediaPlayerAvailable) {
            root.currentLockPlayer = root.activePlayer;
            root.mediaLoaderActive = true;
        }
    }

    // Key presses
    property bool ctrlHeld: false
    Keys.onPressed: event => {
        root.context.resetClearTimer();
        if (event.key === Qt.Key_Control) {
            root.ctrlHeld = true;
        }
        if (event.key === Qt.Key_Escape) { // Esc to clear
            root.context.currentText = "";
        } 
        forceFieldFocus();
    }
    Keys.onReleased: event => {
        if (event.key === Qt.Key_Control) {
            root.ctrlHeld = false;
        }
        forceFieldFocus();
    }

    // RippleButton {
    //     anchors {
    //         top: parent.top
    //         left: parent.left
    //         leftMargin: 10
    //         topMargin: 10
    //     }
    //     implicitHeight: 40
    //     colBackground: Appearance.colors.colLayer2
    //     onClicked: {
    //         context.unlocked(LockContext.ActionEnum.Unlock);
    //         GlobalStates.screenLocked = false;
    //     }
    //     contentItem: StyledText {
    //         text: "[[ DEBUG BYPASS ]]"
    //     }
    // }

    // Clock and date centered at the top
    Column {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: Math.max(36, parent.height * 0.08)
        }
        spacing: -14
        opacity: root.toolbarOpacity
        scale: root.toolbarScale

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: DateTime.time.split(":")[0].padStart(2, "0")
            color: Appearance.colors.colPrimary
            font.pixelSize: Math.min(130, Math.max(72, root.height * 0.13))
            font.weight: Font.Light
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: (DateTime.time.split(":")[1] ?? "00").split(" ")[0].padStart(2, "0")
            color: Appearance.colors.colPrimary
            font.pixelSize: Math.min(130, Math.max(72, root.height * 0.13))
            font.weight: Font.Light
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: 20
            text: DateTime.longDate
            color: Appearance.colors.colPrimary
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.Medium
        }
    }

    Loader {
        id: lockscreenMediaController
        active: root.mediaLoaderActive

        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: mainIsland.top
            bottomMargin: 15
        }

        property real mediaScale: 0.85
        property real mediaOpacity: 0.0

        scale: mediaScale * root.toolbarScale
        opacity: mediaOpacity * root.toolbarOpacity

        onLoaded: {
            mediaScale = 0.85
            mediaOpacity = 0.0
            entryAnim.restart()
        }

        ParallelAnimation {
            id: entryAnim
            NumberAnimation {
                target: lockscreenMediaController
                property: "mediaScale"
                to: 1.0
                duration: Appearance.animation.elementMove.duration * 1.2
                easing.type: Easing.OutBack
                easing.overshoot: 1.2
            }
            NumberAnimation {
                target: lockscreenMediaController
                property: "mediaOpacity"
                to: 1.0
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Easing.OutCubic
            }
        }

        SequentialAnimation {
            id: mediaExitAnim
            ParallelAnimation {
                NumberAnimation {
                    target: lockscreenMediaController
                    property: "mediaScale"
                    to: 0.85
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Easing.InBack
                    easing.overshoot: 1.2
                }
                NumberAnimation {
                    target: lockscreenMediaController
                    property: "mediaOpacity"
                    to: 0.0
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Easing.InCubic
                }
            }
            ScriptAction {
                script: {
                    root.mediaLoaderActive = false;
                    root.currentLockPlayer = null;
                }
            }
        }

        sourceComponent: Player {
            player: root.currentLockPlayer ?? root.activePlayer
            visualizerPoints: root.visualizerPoints
            implicitWidth: Appearance.sizes.mediaControlsWidth
            implicitHeight: Appearance.sizes.mediaControlsHeight
            radius: Appearance.rounding.screenRounding - Appearance.sizes.windowGapsOut + 1
            allowLyrics: false
        }
    }

    // Main toolbar: password box
    Toolbar {
        id: mainIsland
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 24
        }
        Behavior on anchors.bottomMargin {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
        padding: 8
        radius: 12
        colBackground: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainer, 0.12)
        scale: root.toolbarScale
        opacity: root.toolbarOpacity

        // Fingerprint
        Loader {
            Layout.leftMargin: 10
            Layout.rightMargin: 6
            Layout.alignment: Qt.AlignVCenter
            active: root.context.fingerprintsConfigured
            visible: active

            sourceComponent: MaterialSymbol {
                id: fingerprintIcon
                fill: 1
                text: "fingerprint"
                iconSize: Appearance.font.pixelSize.hugeass
                color: Appearance.colors.colOnSurfaceVariant
            }
        }

        ToolbarTextField {
            id: passwordBox
            Layout.rightMargin: -Layout.leftMargin
            placeholderText: GlobalStates.screenUnlockFailed ? Translation.tr("Incorrect password") : Translation.tr("Enter password")

            // Style
            clip: true
            font.pixelSize: Appearance.font.pixelSize.small
            selectedTextColor: materialShapeChars ? "transparent" : Appearance.colors.colOnSecondaryContainer
            selectionColor: materialShapeChars ? "transparent" : Appearance.colors.colSecondaryContainer

            // Password
            enabled: !root.context.unlockInProgress
            echoMode: TextInput.Password
            inputMethodHints: Qt.ImhSensitiveData

            // Synchronizing (across monitors) and unlocking
            onTextChanged: root.context.currentText = this.text
            onAccepted: {
                root.context.tryUnlock(ctrlHeld);
            }
            Connections {
                target: root.context
                function onCurrentTextChanged() {
                    passwordBox.text = root.context.currentText;
                }
            }

            Keys.onPressed: event => {
                root.context.resetClearTimer();
            }
            
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: passwordBox.width - 8
                    height: passwordBox.height
                    radius: height / 2
                }
            }

            // Shake when wrong password
            ErrorShakeAnimation {
                id: wrongPasswordShakeAnim
                target: passwordBox
            }
            Connections {
                target: GlobalStates
                function onScreenUnlockFailedChanged() {
                    if (GlobalStates.screenUnlockFailed) wrongPasswordShakeAnim.restart();
                }
            }

            // We're drawing dots manually
            property bool materialShapeChars: Config.options.lock.materialShapeChars
            color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, materialShapeChars ? 1 : 0)
            Loader {
                active: passwordBox.materialShapeChars
                anchors {
                    fill: parent
                    leftMargin: passwordBox.padding
                    rightMargin: passwordBox.padding
                }
                sourceComponent: PasswordChars {
                    length: root.context.currentText.length
                    selectionStart: passwordBox.selectionStart
                    selectionEnd: passwordBox.selectionEnd
                    cursorPosition: passwordBox.cursorPosition
                }
            }
        }

        ToolbarButton {
            id: confirmButton
            implicitWidth: height
            toggled: true
            enabled: !root.context.unlockInProgress
            colBackgroundToggled: Appearance.colors.colPrimary

            onClicked: root.context.tryUnlock()

            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                iconSize: 24
                text: {
                    if (root.context.targetAction === LockContext.ActionEnum.Unlock) {
                        return root.ctrlHeld ? "coffee" : "arrow_right_alt";
                    } else if (root.context.targetAction === LockContext.ActionEnum.Poweroff) {
                        return "power_settings_new";
                    } else if (root.context.targetAction === LockContext.ActionEnum.Reboot) {
                        return "restart_alt";
                    }
                }
                color: confirmButton.enabled ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
            }
        }
    }

    // Left toolbar
    Toolbar {
        id: leftIsland
        visible: Config.options.lock.showToolbars
        anchors {
            right: mainIsland.left
            top: mainIsland.top
            bottom: mainIsland.bottom
            rightMargin: 10
        }
        padding: 8
        radius: 12
        colBackground: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainer, 0.12)
        scale: root.toolbarScale
        opacity: root.toolbarOpacity

        // Username
        IconAndTextPair {
            Layout.leftMargin: 8
            icon: "account_circle"
            text: SystemInfo.username
        }

        // Keyboard layout (Xkb)
        Loader {
            Layout.rightMargin: 8
            Layout.fillHeight: true

            sourceComponent: Row {
                spacing: 8

                MaterialSymbol {
                    id: keyboardIcon
                    anchors.verticalCenter: parent.verticalCenter
                    fill: 1
                    text: "keyboard_alt"
                    iconSize: Appearance.font.pixelSize.huge
                    color: Appearance.colors.colOnSurfaceVariant
                }
                Loader {
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: StyledText {
                        text: NiriXkb.currentLayoutCode
                        color: Appearance.colors.colOnSurfaceVariant
                        animateChange: true
                    }
                }
            }
        }

        // Keyboard layout (Fcitx)
        Bar.SysTray {
            Layout.rightMargin: 10
            Layout.alignment: Qt.AlignVCenter
            showSeparator: false
            showOverflowMenu: false
            pinnedItems: SystemTray.items.values.filter(i => i.id == "Fcitx")
            visible: pinnedItems.length > 0
        }
    }

    // Right toolbar
    Toolbar {
        id: rightIsland
        visible: Config.options.lock.showToolbars
        anchors {
            left: mainIsland.right
            top: mainIsland.top
            bottom: mainIsland.bottom
            leftMargin: 10
        }
        padding: 8
        radius: 12
        colBackground: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainer, 0.12)

        scale: root.toolbarScale
        opacity: root.toolbarOpacity

        IconAndTextPair {
            visible: Battery.available
            icon: Battery.isCharging ? "bolt" : "battery_android_full"
            text: Math.round(Battery.percentage * 100)
            color: (Battery.isLow && !Battery.isCharging) ? Appearance.colors.colError : Appearance.colors.colOnSurfaceVariant
        }

        IconToolbarButton {
            id: sleepButton
            onClicked: Session.suspend()
            text: "dark_mode"
        }

        PasswordGuardedIconToolbarButton {
            id: powerButton
            text: "power_settings_new"
            targetAction: LockContext.ActionEnum.Poweroff
        }

        PasswordGuardedIconToolbarButton {
            id: rebootButton
            text: "restart_alt"
            targetAction: LockContext.ActionEnum.Reboot
        }
    }

    component PasswordGuardedIconToolbarButton: IconToolbarButton {
        id: guardedBtn
        required property var targetAction

        toggled: root.context.targetAction === guardedBtn.targetAction

        onClicked: {
            if (!root.requirePasswordToPower) {
                root.context.unlocked(guardedBtn.targetAction);
                return;
            }
            if (root.context.targetAction === guardedBtn.targetAction) {
                root.context.resetTargetAction();
            } else {
                root.context.targetAction = guardedBtn.targetAction;
                root.context.shouldReFocus();
            }
        }
    }

    component IconAndTextPair: Row {
        id: pair
        required property string icon
        required property string text
        property color color: Appearance.colors.colOnSurfaceVariant

        spacing: 4
        Layout.fillHeight: true
        Layout.leftMargin: 10
        Layout.rightMargin: 10
        

        MaterialSymbol {
            anchors.verticalCenter: parent.verticalCenter
            fill: 1
            text: pair.icon
            iconSize: Appearance.font.pixelSize.huge
            animateChange: true
            color: pair.color
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: pair.text
            color: pair.color
        }
    }
}
