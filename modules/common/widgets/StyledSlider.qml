pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets

/**
 * Material 3 slider. See https://m3.material.io/components/sliders/overview
 * It doesn't exactly match the spec because it does not make sense to have stuff on a computer that fucking huge.
 * Should be at 3/4 scale...
 */

Slider {
    id: root

    property list<real> stopIndicatorValues: [1]
    property list<real> dividerValues: []
    enum Configuration {
        Wavy = 4,
        XS = 12,
        S = 18,
        M = 30,
        L = 42,
        XL = 72
    }

    property var configuration: StyledSlider.Configuration.S

    property real handleDefaultWidth: 4
    property real handlePressedWidth: 2.5
    property color highlightColor: Appearance.colors.colPrimary
    property color trackColor: Appearance.colors.colSecondaryContainer
    property color handleColor: Appearance.colors.colPrimary
    property color dotColor: Appearance.m3colors.m3onSecondaryContainer
    property color dotColorHighlighted: Appearance.m3colors.m3onPrimary
    property real unsharpenRadius: Appearance.rounding.unsharpen
    property real trackWidth: configuration
    property real trackRadius: trackWidth >= StyledSlider.Configuration.XL ? Appearance.rounding.verylarge
        : trackWidth >= StyledSlider.Configuration.L ? Appearance.rounding.large
        : trackWidth / 2
    property real baseHandleHeight: (configuration === StyledSlider.Configuration.Wavy) ? 28 : Math.max(36, trackWidth + 18)
    property real handleHeight: root.pressed ? baseHandleHeight + 4 : baseHandleHeight
    property real handleWidth: root.pressed ? handlePressedWidth : handleDefaultWidth
    property real handleMargins: 6
    property real dividerMargins: 2
    property real trackDotSize: 4
    implicitHeight: Math.max(trackWidth, baseHandleHeight + 4)
    property bool usePercentTooltip: true
    property string tooltipContent: usePercentTooltip ? `${Math.round(((value - from) / (to - from)) * 100)}%` : `${Math.round(value)}`
    property bool wavy: configuration === StyledSlider.Configuration.Wavy // If true, the progress bar will have a wavy fill effect
    property bool animateWave: true
    property real waveAmplitudeMultiplier: wavy ? 0.5 : 0
    property real waveFrequency: 6
    property real waveFps: 60

    leftPadding: handleMargins
    rightPadding: handleMargins
    property real effectiveDraggingWidth: width - leftPadding - rightPadding

    Layout.fillWidth: true
    from: 0
    to: 1

    Behavior on value { // This makes the adjusted value (like volume) shift smoothly
        SmoothedAnimation {
            velocity: Appearance.animation.elementMoveFast.velocity
        }
    }

    Behavior on handleMargins {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    component TrackDot: Rectangle {
        required property real value
        property real normalizedValue: (value - root.from) / (root.to - root.from)
        anchors.verticalCenter: parent.verticalCenter
        x: root.handleMargins + (normalizedValue * root.effectiveDraggingWidth) - (root.trackDotSize / 2)
        width: root.trackDotSize
        height: root.trackDotSize
        radius: Appearance.rounding.full
        color: normalizedValue > root.visualPosition ? root.dotColor : root.dotColorHighlighted

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    MouseArea {
        anchors.fill: parent
        onPressed: (mouse) => mouse.accepted = false
        cursorShape: root.pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor 
    }

    background: Item {
        id: background
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.width
        implicitHeight: trackWidth
        property var normalized: root.dividerValues.map(v => (v - root.from) / (root.to - root.from))
        property var filtered: normalized.filter(v => Math.abs(v - root.visualPosition) * effectiveDraggingWidth > handleMargins + handleWidth / 2 - dividerMargins)
        property var leftValues: [0, ...filtered.filter(v => v < root.visualPosition), root.visualPosition]
        property var rightValues: [root.visualPosition, ...filtered.filter(v => v > root.visualPosition), 1]
        property var leftWidths: leftValues.map((v, i, a) => a[i + 1] - v).slice(0, -1)
        property var rightWidths: rightValues.map((v, i, a) => a[i + 1] - v).slice(0, -1)

        // Fill left
        Repeater {
            model: background.leftWidths.length

            Loader {
                required property real index
                anchors.verticalCenter: background.verticalCenter
                property real leftMargin: index > 0 ? root.dividerMargins : 0
                property real rightMargin: index < background.leftWidths.length - 1 ? root.dividerMargins : root.handleMargins
                x: background.leftValues[index] * root.effectiveDraggingWidth + leftMargin + (index > 0 ? leftPadding : 0)
                width: background.leftWidths[index] * root.effectiveDraggingWidth - leftMargin - rightMargin - (index === background.leftWidths.length - 1 ? handleWidth / 2 : 0) + (index === 0 ? leftPadding : 0)
                height: root.trackWidth
                active: !root.wavy
                sourceComponent: Rectangle {
                    color: root.highlightColor
                    topLeftRadius: index === 0 ? root.trackRadius : root.unsharpenRadius
                    bottomLeftRadius: index === 0 ? root.trackRadius : root.unsharpenRadius
                    topRightRadius: root.unsharpenRadius
                    bottomRightRadius: root.unsharpenRadius
                }
            }
        }

        Repeater {
            model: background.leftWidths.length

            Loader {
                required property int index
                anchors.verticalCenter: background.verticalCenter
                property real leftMargin: index > 0 ? root.dividerMargins : 0
                property real rightMargin: index < background.leftWidths.length - 1 ? root.dividerMargins : root.handleMargins
                x: background.leftValues[index] * root.effectiveDraggingWidth + leftMargin + (index > 0 ? leftPadding : 0)
                width: background.leftWidths[index] * root.effectiveDraggingWidth - leftMargin - rightMargin - (index === background.leftWidths.length - 1 ? handleWidth / 2 : 0) + (index === 0 ? leftPadding : 0)
                height: root.height
                active: root.wavy
                sourceComponent: WavyLine {
                    id: wavyFill
                    frequency: root.waveFrequency
                    fullLength: root.width
                    color: root.highlightColor
                    amplitudeMultiplier: root.wavy ? 0.5 : 0
                    width: parent.width
                    height: root.trackWidth
                    Connections {
                        target: root
                        function onValueChanged() { wavyFill.requestPaint(); }
                        function onHighlightColorChanged() { wavyFill.requestPaint(); }
                    }
                    FrameAnimation {
                        running: root.animateWave
                        onTriggered: {
                            wavyFill.requestPaint()
                        }
                    }
                }
            }
        }

        // Fill right
        Repeater {
            model: background.rightWidths.length

            Rectangle {
                required property int index
                anchors.verticalCenter: background.verticalCenter
                property real leftMargin: index > 0 ? root.dividerMargins : root.handleMargins
                property real rightMargin: index < background.rightWidths.length - 1 ? root.dividerMargins : 0
                x: background.rightValues[index] * root.effectiveDraggingWidth + leftMargin + (index === 0 ? handleWidth / 2 : 0) + leftPadding
                width: background.rightWidths[index] * root.effectiveDraggingWidth - leftMargin - rightMargin - (index === 0 ? handleWidth / 2 : 0) + (index === background.rightWidths.length - 1 ? rightPadding : 0)
                height: trackWidth
                color: root.trackColor
                topRightRadius: index === background.rightWidths.length - 1 ? root.trackRadius : root.unsharpenRadius
                bottomRightRadius: index === background.rightWidths.length - 1 ? root.trackRadius : root.unsharpenRadius
                topLeftRadius: root.unsharpenRadius
                bottomLeftRadius: root.unsharpenRadius
            }
        }

        // Stop indicators
        Repeater {
            model: root.stopIndicatorValues
            TrackDot {
                required property real modelData
                value: modelData
                anchors.verticalCenter: parent?.verticalCenter
            }
        }
    }

    handle: Rectangle {
        id: handle

        implicitWidth: root.handleWidth
        implicitHeight: root.handleHeight
        x: root.leftPadding + (root.visualPosition * root.effectiveDraggingWidth) - (implicitWidth / 2)
        anchors.verticalCenter: parent.verticalCenter
        radius: Appearance.rounding.full
        color: root.handleColor
        border.width: root.visualFocus ? 2 : 0
        border.color: Appearance.colors.colOnSurface

        Behavior on implicitWidth {
            animation: Appearance?.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on implicitHeight {
            animation: Appearance?.animation.elementMoveSmall.numberAnimation.createObject(this)
        }

        StyledToolTip {
            extraVisibleCondition: root.pressed
            text: root.tooltipContent
            font {
                family: Appearance.font.family.numbers
                variableAxes: Appearance.font.variableAxes.numbers
            }
        }
    }
}
