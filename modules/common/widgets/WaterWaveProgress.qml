import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property real progress: 0.0
    property real animatedProgress: 0.0
    property bool behaviorEnabled: true
    property bool running: false
    property color colPrimary: Appearance.colors.colPrimary
    property color colSecondary: Qt.rgba(Appearance.colors.colOnSurface.r, Appearance.colors.colOnSurface.g, Appearance.colors.colOnSurface.b, 0.28)
    property real circleRadius: 36
    property real lineWidth: 5.5
    property real waveAmplitude: 3.8
    property int waveCount: 8
    property real waveSpeed: 4.5

    anchors.fill: parent
    visible: opacity > 0
    opacity: running ? 1.0 : 0.0

    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    Behavior on animatedProgress {
        enabled: root.behaviorEnabled
        NumberAnimation {
            duration: Appearance.animationCurves.expressiveDefaultSpatialDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
        }
    }

    onProgressChanged: {
        if (root.running) {
            root.animatedProgress = root.progress;
        }
    }

    onRunningChanged: {
        if (root.running) {
            root.behaviorEnabled = false;
            root.animatedProgress = 0.0;
            root.behaviorEnabled = true;
        }
    }

    // Dimming backdrop over the thumbnail
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
    }

    // Material 3 Expressive circular wavy progress indicator
    Item {
        id: progressContainer
        anchors.centerIn: parent
        width: (root.circleRadius + root.waveAmplitude + root.lineWidth + 8) * 2
        height: width

        scale: root.running ? 1.0 : 0.8
        Behavior on scale {
            animation: Appearance.animation.clickBounce.numberAnimation.createObject(this)
        }

        Canvas {
            id: canvas
            anchors.fill: parent

            onPaint: {
                const ctx = getContext("2d");
                if (!ctx) return;
                ctx.clearRect(0, 0, width, height);

                const cx = width / 2;
                const cy = height / 2;
                const R = root.circleRadius;
                if (R <= 0) return;

                const pct = Math.max(0, Math.min(100, root.animatedProgress)) / 100.0;
                const startAngle = -Math.PI / 2;
                const sweepAngle = (2 * Math.PI) * pct;
                const gapAngle = (Math.PI / 18);
                const now = Date.now() / 1000.0;
                const phase = now * root.waveSpeed;

                // 1. Inactive smooth circular track
                if (pct < 0.98) {
                    const inactiveStart = startAngle + sweepAngle + (pct > 0.01 ? gapAngle : 0);
                    const inactiveEnd = startAngle + (2 * Math.PI) - (pct > 0.01 ? gapAngle : 0);

                    if (inactiveEnd - inactiveStart > 0.05) {
                        ctx.beginPath();
                        ctx.arc(cx, cy, R, inactiveStart, inactiveEnd);
                        ctx.strokeStyle = root.colSecondary;
                        ctx.lineWidth = root.lineWidth;
                        ctx.lineCap = "round";
                        ctx.stroke();
                    }
                }

                // 2. Active wavy progress arc
                if (sweepAngle > 0.02) {
                    ctx.beginPath();
                    const numPoints = Math.max(16, Math.round((sweepAngle / (2 * Math.PI)) * 140));

                    for (let i = 0; i <= numPoints; i++) {
                        const u = sweepAngle * (i / numPoints);
                        const angle = startAngle + u;
                        const distFromEnd = Math.min(u, sweepAngle - u);
                        const taper = Math.min(1.0, distFromEnd / 0.18);
                        const r = R + Math.sin(angle * root.waveCount - phase) * (root.waveAmplitude * taper);
                        const px = cx + r * Math.cos(angle);
                        const py = cy + r * Math.sin(angle);

                        if (i === 0) ctx.moveTo(px, py);
                        else ctx.lineTo(px, py);
                    }

                    ctx.strokeStyle = root.colPrimary;
                    ctx.lineWidth = root.lineWidth;
                    ctx.lineCap = "round";
                    ctx.stroke();
                }
            }

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
        }

        FrameAnimation {
            running: root.visible && (root.running || root.animatedProgress > 0)
            onTriggered: {
                canvas.requestPaint();
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: root.animatedProgress >= 99.5 ? "check" : "download"
                iconSize: 28
                color: root.colPrimary
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: `${Math.min(100, Math.max(0, Math.round(root.animatedProgress)))}%`
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Bold
                color: "#ffffff"
                style: Text.Outline
                styleColor: Qt.rgba(0, 0, 0, 0.7)
            }
        }
    }
}
