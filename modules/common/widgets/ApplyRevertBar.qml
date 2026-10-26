import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root

    property int countdownSeconds: 15
    property int remainingSeconds: 15
    property bool active: false
    property string message: Translation.tr("Keep new settings? Reverting in %1s").arg(remainingSeconds)

    signal keepChanges()
    signal revertChanges()

    function start(seconds) {
        root.countdownSeconds = seconds ?? 15
        root.remainingSeconds = root.countdownSeconds
        root.active = true
        timer.restart()
    }

    function dismiss() {
        timer.stop()
        root.active = false
    }

    visible: active
    implicitHeight: 52
    Layout.fillWidth: true
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer2
    border.color: Appearance.colors.colPrimary
    border.width: 1

    Timer {
        id: timer
        interval: 1000
        repeat: true
        running: root.active
        onTriggered: {
            if (root.remainingSeconds > 1) {
                root.remainingSeconds--
            } else {
                root.dismiss()
                root.revertChanges()
            }
        }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 16
            rightMargin: 16
        }
        spacing: 12

        MaterialSymbol {
            text: "timer"
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colPrimary
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            text: root.message
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.Medium
            color: Appearance.colors.colOnLayer2
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }

        // Revert button
        RippleButton {
            implicitHeight: 34
            implicitWidth: revertLabel.implicitWidth + 20
            buttonRadius: Appearance.rounding.small
            colBackground: Appearance.colors.colErrorContainer
            colBackgroundHover: Appearance.colors.colErrorContainerHover
            Layout.alignment: Qt.AlignVCenter

            onClicked: {
                root.dismiss()
                root.revertChanges()
            }

            contentItem: StyledText {
                id: revertLabel
                anchors.centerIn: parent
                text: Translation.tr("Revert")
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.Medium
                color: Appearance.colors.colOnErrorContainer
            }
        }

        // Keep changes button
        RippleButton {
            implicitHeight: 34
            implicitWidth: keepLabel.implicitWidth + 20
            buttonRadius: Appearance.rounding.small
            colBackground: Appearance.colors.colPrimary
            colBackgroundHover: Appearance.colors.colPrimaryHover
            Layout.alignment: Qt.AlignVCenter

            onClicked: {
                root.dismiss()
                root.keepChanges()
            }

            contentItem: StyledText {
                id: keepLabel
                anchors.centerIn: parent
                text: Translation.tr("Keep changes")
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnPrimary
            }
        }
    }
}
