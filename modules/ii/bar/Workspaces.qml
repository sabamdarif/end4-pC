pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell

ButtonMouseArea {
    id: root

    WorkspaceModel {
        id: wsModel
    }

    property bool vertical: Config.options.bar.vertical
    property bool superPressAndHeld: false // Relevant modifications at bottom of file

    readonly property string indicatorStyle: {
        const s = Config.options.bar.workspaces.indicatorStyle;
        return ["dot", "number", "han", "roman"].includes(s) ? s : "dot";
    }
    readonly property bool isNumberStyle: ["number", "han", "roman"].includes(indicatorStyle)

    function getWorkspaceText(wsId) {
        if (wsId < 1) return "";
        const idx = wsId - 1;
        const style = root.indicatorStyle;
        if (style === "han") {
            const hanChars = ["一","二","三","四","五","六","七","八","九","十","十一","十二","十三","十四","十五","十六","十七","十八","十九","二十"];
            return hanChars[idx] || String(wsId);
        }
        if (style === "roman") {
            const romanChars = ["I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII","XIII","XIV","XV","XVI","XVII","XVIII","XIX","XX"];
            return romanChars[idx] || String(wsId);
        }
        return String(wsId);
    }

    property real workspaceButtonWidth: [3, 4].includes(Config.options.bar.cornerStyle) ? 30 : 26
    property real activeWorkspaceMargin: 2
    property real activeWorkspaceSize: workspaceButtonWidth - activeWorkspaceMargin * 2
    property int workspaceIndexInGroup: (wsModel.activeWorkspace - 1) % wsModel.shownCount

    Layout.alignment: vertical ? Qt.AlignHCenter : Qt.AlignVCenter
    Layout.fillWidth: vertical
    Layout.fillHeight: !vertical
    readonly property real barThickness: vertical ? Appearance.sizes.verticalBarWidth : Appearance.sizes.barHeight
    implicitWidth: vertical ? barThickness : occupiedIndicators.implicitWidth
    implicitHeight: vertical ? occupiedIndicators.implicitHeight : barThickness

    // Interactions
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true
    property int hoverIndex: {
        const position = root.vertical ? mouseY : mouseX;
        return Math.floor(position / root.workspaceButtonWidth);
    }

    function switchWorkspaceToHovered() {
        NiriData.focusWorkspace(wsModel.getWorkspaceIdAt(hoverIndex));
    }
    onPressed: mouse => {
        if (mouse.button == Qt.LeftButton)
            switchWorkspaceToHovered();
        else if (mouse.button == Qt.RightButton)
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
    }
    onWheel: event => {
        if (event.angleDelta.y < 0)
            NiriData.focusWorkspaceDown();
        else if (event.angleDelta.y > 0)
            NiriData.focusWorkspaceUp();
    }

    // Indications
    Item {
        id: regularWorkspaces
        anchors.fill: parent

        /////////////////// Occupied indicators ///////////////////
        StyledRectangle {
            id: occupiedIndicatorsBg
            anchors.fill: parent
            contentLayer: StyledRectangle.ContentLayer.Group
            color: ColorUtils.transparentize(Appearance.m3colors.m3secondaryContainer, 0.4)
            visible: false
        }

        WorkspaceLayout {
            id: occupiedIndicators
            anchors.centerIn: parent

            layer.enabled: true
            visible: false

            Repeater {
                model: wsModel.shownCount
                delegate: Item {
                    id: wsBg
                    required property int index
                    readonly property int wsId: wsModel.getWorkspaceIdAt(index)
                    property bool currentOccupied: (wsModel.occupied[index] ?? false) && wsId != wsModel.fakeWorkspace
                    property bool previousOccupied: index > 0 && (wsModel.occupied[index - 1] ?? false) && (wsId - 1) != wsModel.fakeWorkspace
                    property bool nextOccupied: index < wsModel.shownCount - 1 && (wsModel.occupied[index + 1] ?? false) && (wsId + 1) != wsModel.fakeWorkspace
                    implicitWidth: root.workspaceButtonWidth
                    implicitHeight: root.workspaceButtonWidth

                    // The idea: over-stretch to occupied sides, animate this for a smooth transition.
                    //           masking already prevents weird overlaps
                    Pill {
                        property real undirectionalWidth: root.workspaceButtonWidth * wsBg.currentOccupied
                        property real undirectionalLength: root.workspaceButtonWidth * (1 + 0.5 * wsBg.previousOccupied + 0.5 * wsBg.nextOccupied) * currentOccupied
                        property real undirectionalOffset: (!wsBg.currentOccupied ? 0.5 : -0.5 * wsBg.previousOccupied) * root.workspaceButtonWidth
                        anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
                        anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
                        x: root.vertical ? 0 : undirectionalOffset
                        y: root.vertical ? undirectionalOffset : 0
                        implicitWidth: root.vertical ? undirectionalWidth : undirectionalLength
                        implicitHeight: root.vertical ? undirectionalLength : undirectionalWidth

                        Behavior on undirectionalWidth {
                            animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
                        }
                        Behavior on undirectionalLength {
                            animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
                        }
                        Behavior on undirectionalOffset {
                            animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
                        }
                    }
                }
            }
        }

        MaskMultiEffect {
            id: occupiedIndicatorsMultiEffect
            z: 1
            anchors.centerIn: parent
            implicitWidth: occupiedIndicators.implicitWidth
            implicitHeight: occupiedIndicators.implicitHeight
            source: occupiedIndicatorsBg
            maskSource: occupiedIndicators
        }

        /////////////////// Active indicator ///////////////////
        TrailingIndicator {
            id: activeIndicator
            anchors.fill: parent
            z: 2

            index: root.workspaceIndexInGroup
        }

        /////////////////// Hover ///////////////////
        TrailingIndicator {
            id: interactionIndicator
            z: 3
            index: root.containsMouse ? root.hoverIndex : root.workspaceIndexInGroup
            color: "transparent"
            StateOverlay {
                id: hoverOverlay
                anchors.fill: interactionIndicator.indicatorRectangle
                radius: root.activeWorkspaceSize / 2
                hover: root.containsMouse
                press: root.containsPress
                drag: true // There are too many layers so we need to force this to be a lil more opaque
                contentColor: Appearance.colors.colPrimary
            }
        }

        /////////////////// Numbers ///////////////////
        WorkspaceLayout {
            id: numbersGrid
            z: 4
            layer.enabled: true // For the masking

            Repeater {
                model: wsModel.shownCount
                delegate: NumberWorkspaceItem {}
            }
        }
        Colorizer {
            z: 5
            anchors.fill: numbersGrid
            colorizationColor: Appearance.colors.colOnPrimary
            sourceColor: Appearance.colors.colOnSecondaryContainer

            source: activeIndicator
            maskEnabled: true
            maskSource: numbersGrid

            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }
    }

    /////////////////// Super key press handling ///////////////////
    Timer {
        id: superPressAndHeldTimer
        interval: (Config?.options.bar.autoHide.showWhenPressingSuper.delay ?? 100)
        repeat: false
        onTriggered: {
            root.superPressAndHeld = true;
        }
    }
    Connections {
        target: GlobalStates
        function onSuperDownChanged() {
            if (!Config?.options.bar.autoHide.showWhenPressingSuper.enable)
                return;
            if (GlobalStates.superDown)
                superPressAndHeldTimer.restart();
            else {
                superPressAndHeldTimer.stop();
                root.superPressAndHeld = false;
            }
        }
        function onSuperReleaseMightTriggerChanged() {
            superPressAndHeldTimer.stop();
        }
    }

    component WorkspaceLayout: Box {
        anchors {
            top: !root.vertical ? parent.top : undefined
            bottom: !root.vertical ? parent.bottom : undefined
            left: root.vertical ? parent.left : undefined
            right: root.vertical ? parent.right : undefined
        }

        rowSpacing: 0
        columnSpacing: 0
        vertical: root.vertical
    }

    component WorkspaceItem: Item {
        required property int index
        readonly property int wsId: wsModel.getWorkspaceIdAt(index)
        implicitWidth: root.vertical ? root.barThickness : root.workspaceButtonWidth
        implicitHeight: root.vertical ? root.workspaceButtonWidth : root.barThickness
    }

    component NumberWorkspaceItem: WorkspaceItem {
        id: wsNum
        property int wsId: wsModel.getWorkspaceIdAt(index)
        property color contentColor: (wsModel.occupied[wsNum.index] && wsId !== wsModel.fakeWorkspace) ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1Inactive
        property bool showingNumbers: {
            if (root.superPressAndHeld)
                return true;
            if (GlobalStates.screenLocked)
                return false;
            return root.isNumberStyle;
        }

        FadeLoader {
            shown: !wsNum.showingNumbers
            anchors.centerIn: parent
            Circle {
                anchors.centerIn: parent
                diameter: root.workspaceButtonWidth * 0.18
                color: wsNum.contentColor
            }
        }
        FadeLoader {
            shown: wsNum.showingNumbers
            anchors.centerIn: parent
            StyledText {
                anchors.centerIn: parent
                font {
                    pixelSize: Appearance.font.pixelSize.small - ((text.length - 1) * (text !== "10") * 2)
                    family: Config.options?.bar.workspaces.useNerdFont ? Appearance.font.family.iconNerd : defaultFont
                }
                color: wsNum.contentColor
                text: root.getWorkspaceText(wsNum.wsId)
            }
        }
    }

    component TrailingIndicator: Item {
        id: trailingIndicator
        anchors.fill: parent
        required property int index
        property alias indicatorRectangle: indicatorRect
        property alias color: indicatorRect.color

        property var indexPair: AnimatedTabIndexPair {
            id: idxPair
            index: trailingIndicator.index
        }

        StyledRectangle {
            id: indicatorRect

            anchors {
                verticalCenter: root.vertical ? undefined : parent.verticalCenter
                horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
            }

            property real indicatorPosition: Math.min(idxPair.idx1, idxPair.idx2) * root.workspaceButtonWidth + root.activeWorkspaceMargin
            property real indicatorLength: Math.abs(idxPair.idx1 - idxPair.idx2) * root.workspaceButtonWidth + root.activeWorkspaceSize
            property real indicatorThickness: root.activeWorkspaceSize

            contentLayer: StyledRectangle.ContentLayer.Group
            radius: indicatorThickness / 2
            color: Appearance.colors.colPrimary

            x: root.vertical ? null : indicatorPosition
            y: root.vertical ? indicatorPosition : null
            implicitWidth: root.vertical ? indicatorThickness : indicatorLength
            implicitHeight: root.vertical ? indicatorLength : indicatorThickness
        }
    }
}