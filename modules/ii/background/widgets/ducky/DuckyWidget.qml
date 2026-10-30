import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root
    configEntryName: "ducky"
    hoverEnabled: true

    property string sizeMode: (root.configEntry && root.configEntry.sizeMode) ? root.configEntry.sizeMode : "2x2"

    implicitWidth: sizeMode === "1x4" ? 380 : 260
    implicitHeight: sizeMode === "1x4" ? 130 : 255

    Behavior on implicitWidth {
        NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
    }
    Behavior on implicitHeight {
        NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
    }

    property int petCount: 0

    readonly property string speechText: {
        const level = Math.round(ResourceUsage.memoryUsedPercentage * 100);
        return Translation.tr("Headache level: %1% 🧠").arg(level);
    }

    Component.onCompleted: {
        ResourceUsage.subscribers++;
        if (Persistent.states.ducky) {
            root.petCount = Persistent.states.ducky.petCount || 0;
        }
    }
    Component.onDestruction: ResourceUsage.subscribers--

    function triggerPet() {
        petCount++;
        if (Persistent.states.ducky) {
            Persistent.states.ducky.petCount = petCount;
        }

        petInactivityTimer.restart();

        if (petCount > 0 && petCount % 100 === 0) {
            flashOverlayTimer.restart();
        }

        avatarScaleAnim.restart();
        avatarWobbleAnim.restart();

        spawnHeartParticle();
    }

    function spawnHeartParticle() {
        const emojis = ["💖", "✨", "⭐", "🐤", "💛", "🧠"];
        const emoji = emojis[Math.floor(Math.random() * emojis.length)];
        const rx = (Math.random() - 0.5) * 60;
        particleModel.append({
            id: Date.now() + Math.random(),
            emojiText: emoji,
            startX: rx
        });
    }

    Timer {
        id: petInactivityTimer
        interval: 180000
        repeat: false
        running: false
        onTriggered: {
            root.petCount = 0;
            if (Persistent.states.ducky) {
                Persistent.states.ducky.petCount = 0;
            }
        }
    }

    ListModel {
        id: particleModel
    }

    PanelWindow {
        id: flashWindow
        visible: flashOverlayTimer.running
        color: "#e6000000"
        WlrLayershell.layer: WlrLayer.Overlay
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: flashOverlayTimer.stop()
        }

        Item {
            anchors.centerIn: parent

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 20

                StyledText {
                    text: Translation.tr("u are the duck")
                    font.pixelSize: 68
                    font.weight: Font.Black
                    color: Appearance.colors.colPrimary
                    horizontalAlignment: Text.AlignHCenter
                }

                StyledText {
                    text: "~ :)"
                    font.pixelSize: 44
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    Timer {
        id: flashOverlayTimer
        interval: 3200
        repeat: false
    }

    Item {
        id: idleBobbing
        property real bobY: 0
        SequentialAnimation on bobY {
            running: true
            loops: Animation.Infinite
            NumberAnimation { from: -3; to: 3; duration: 1400; easing.type: Easing.InOutSine }
            NumberAnimation { from: 3; to: -3; duration: 1400; easing.type: Easing.InOutSine }
        }
    }

    Item {
        id: cloudBobbing
        property real bobY: 0
        SequentialAnimation on bobY {
            running: true
            loops: Animation.Infinite
            NumberAnimation { from: -3; to: 3; duration: 2200; easing.type: Easing.InOutSine }
            NumberAnimation { from: 3; to: -3; duration: 2200; easing.type: Easing.InOutSine }
        }
    }

    Item {
        id: transformItem
        property real customScale: 1.0
        property real customRotation: 0
    }

    NumberAnimation {
        id: avatarScaleAnim
        target: transformItem
        property: "customScale"
        from: 1.25
        to: 1.0
        duration: 350
        easing.type: Easing.OutBack
    }

    SequentialAnimation {
        id: avatarWobbleAnim
        NumberAnimation { target: transformItem; property: "customRotation"; from: -10; to: 10; duration: 80 }
        NumberAnimation { target: transformItem; property: "customRotation"; from: 10; to: -5; duration: 80 }
        NumberAnimation { target: transformItem; property: "customRotation"; from: -5; to: 0; duration: 80 }
    }

    component ThoughtCloud: Item {
        id: tc
        property string trailingDirection: "down"
        property color cloudColor: Appearance.colors.colPrimaryContainer
        property color textColor: Appearance.colors.colOnPrimaryContainer
        property string text: root.speechText
        property int petCount: root.petCount
        property bool showPetCount: root.petCount > 0 && petInactivityTimer.running

        StyledDropShadow {
            target: cloudShape
        }

        Item {
            id: cloudShape
            anchors.fill: parent

            Item {
                id: cloudBody
                x: tc.trailingDirection === "left" ? 44 : (parent.width - width) / 2
                y: 8
                width: 210
                height: 58

                Rectangle {
                    x: 18
                    y: 10
                    width: 174
                    height: 38
                    radius: 19
                    color: tc.cloudColor
                }

                Rectangle { x: 26; y: 2; width: 34; height: 34; radius: 17; color: tc.cloudColor }
                Rectangle { x: 62; y: -4; width: 44; height: 44; radius: 22; color: tc.cloudColor }
                Rectangle { x: 110; y: -2; width: 42; height: 42; radius: 21; color: tc.cloudColor }
                Rectangle { x: 152; y: 3; width: 32; height: 32; radius: 16; color: tc.cloudColor }

                Rectangle { x: 28; y: 22; width: 34; height: 34; radius: 17; color: tc.cloudColor }
                Rectangle { x: 68; y: 26; width: 38; height: 38; radius: 19; color: tc.cloudColor }
                Rectangle { x: 112; y: 24; width: 36; height: 36; radius: 18; color: tc.cloudColor }
                Rectangle { x: 150; y: 21; width: 32; height: 32; radius: 16; color: tc.cloudColor }

                Rectangle { x: 2; y: 12; width: 34; height: 34; radius: 17; color: tc.cloudColor }
                Rectangle { x: 174; y: 12; width: 34; height: 34; radius: 17; color: tc.cloudColor }
            }

            Rectangle {
                x: cloudBody.x + 76
                y: cloudBody.y + 56
                width: 14
                height: 14
                radius: 7
                color: tc.cloudColor
                visible: tc.trailingDirection === "down"
            }
            Rectangle {
                x: cloudBody.x + 88
                y: cloudBody.y + 70
                width: 10
                height: 10
                radius: 5
                color: tc.cloudColor
                visible: tc.trailingDirection === "down"
            }
            Rectangle {
                x: cloudBody.x + 98
                y: cloudBody.y + 82
                width: 6
                height: 6
                radius: 3
                color: tc.cloudColor
                visible: tc.trailingDirection === "down"
            }

            Rectangle {
                x: cloudBody.x - 12
                y: cloudBody.y + 28
                width: 14
                height: 14
                radius: 7
                color: tc.cloudColor
                visible: tc.trailingDirection === "left"
            }
            Rectangle {
                x: cloudBody.x - 24
                y: cloudBody.y + 36
                width: 10
                height: 10
                radius: 5
                color: tc.cloudColor
                visible: tc.trailingDirection === "left"
            }
            Rectangle {
                x: cloudBody.x - 34
                y: cloudBody.y + 43
                width: 6
                height: 6
                radius: 3
                color: tc.cloudColor
                visible: tc.trailingDirection === "left"
            }
        }

        Item {
            id: cloudContent
            x: cloudBody.x
            y: cloudBody.y
            width: cloudBody.width
            height: cloudBody.height

            RowLayout {
                anchors.centerIn: parent
                spacing: 6

                StyledText {
                    text: tc.text
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: tc.textColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    radius: 10
                    color: Appearance.colors.colPrimary
                    implicitWidth: petRow.implicitWidth + 8
                    implicitHeight: 18
                    visible: tc.showPetCount

                    RowLayout {
                        id: petRow
                        anchors.centerIn: parent
                        spacing: 2

                        MaterialSymbol {
                            text: "favorite"
                            iconSize: 10
                            color: Appearance.colors.colOnPrimary
                        }

                        StyledText {
                            text: tc.petCount.toString()
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnPrimary
                        }
                    }
                }
            }
        }
    }

    Item {
        id: card
        anchors.fill: parent

        Item {
            id: particleContainer
            anchors.fill: parent
            z: 20

            Repeater {
                model: particleModel
                delegate: Item {
                    id: pItem
                    required property int index
                    required property string emojiText
                    required property real startX

                    x: (root.sizeMode === "1x4" ? 60 : parent.width / 2) + startX
                    y: root.sizeMode === "1x4" ? parent.height / 2 : 140

                    StyledText {
                        text: emojiText
                        font.pixelSize: 18
                        anchors.centerIn: parent
                    }

                    ParallelAnimation {
                        running: true
                        NumberAnimation {
                            target: pItem
                            property: "y"
                            from: root.sizeMode === "1x4" ? parent.height / 2 : 140
                            to: (root.sizeMode === "1x4" ? parent.height / 2 : 140) - 80
                            duration: 800
                            easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            target: pItem
                            property: "opacity"
                            from: 1.0
                            to: 0.0
                            duration: 800
                            easing.type: Easing.InQuad
                        }
                        onFinished: {
                            if (index >= 0 && index < particleModel.count) {
                                particleModel.remove(index);
                            }
                        }
                    }
                }
            }
        }

        ThoughtCloud {
            id: thoughtCloud
            trailingDirection: root.sizeMode === "1x4" ? "left" : "down"
            width: 260
            height: root.sizeMode === "1x4" ? 75 : 100
            x: root.sizeMode === "1x4" ? 110 : (card.width - width) / 2
            y: (root.sizeMode === "1x4" ? (card.height - height) / 2 : 4) + cloudBobbing.bobY

            Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
            Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
        }

        Item {
            id: duckyArea
            width: root.sizeMode === "1x4" ? 95 : 175
            height: root.sizeMode === "1x4" ? 95 : 175
            x: root.sizeMode === "1x4" ? 12 : (card.width - width) / 2
            y: (root.sizeMode === "1x4" ? (card.height - height) / 2 : 80) + idleBobbing.bobY

            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
            Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
            Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
            Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.triggerPet()
            }

            AnimatedImage {
                id: duckyImage
                anchors.fill: parent
                source: "assets/psyduck.gif"
                playing: true
                fillMode: Image.PreserveAspectFit
                smooth: true

                scale: transformItem.customScale
                rotation: transformItem.customRotation
            }
        }
    }
}
