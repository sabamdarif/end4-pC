import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// Dynamic Island compact idle pill: left pin, center pin, and right pin,
// dynamically configurable or automatically matched from Bar Layout.
Item {
    id: diIdleRoot
    required property Item di
    anchors.fill: parent

    MouseArea {
        anchors.fill: parent
        z: -1
        cursorShape: Qt.PointingHandCursor
        onClicked: diIdleRoot.di.toggleExpanded()
    }

    readonly property string displayFont: {
        switch (diIdleRoot.di.cfg.anchorFont ?? "expressive") {
            case "numbers":   return Appearance.font.family.numbers
            case "monospace": return Appearance.font.family.monospace
            case "main":      return Appearance.font.family.main
            default:          return Appearance.font.family.expressive
        }
    }

    readonly property string effectiveLeftPin: {
        const pin = Config.options.bar.dynamicIsland.leftPin ?? "auto"
        if (pin !== "auto") return pin
        const leftLayout = Config.options.bar.layouts.leftLayout ?? []
        if (leftLayout.includes("batteryIndicator")) return "battery"
        if (leftLayout.includes("networkSpeed")) return "networkSpeed"
        if (leftLayout.includes("workspaces")) return "workspaces"
        if (leftLayout.includes("weatherBar")) return "weather"
        return "battery"
    }

    readonly property string effectiveMiddlePin: {
        const pin = Config.options.bar.dynamicIsland.middlePin ?? "auto"
        if (pin !== "auto") return pin
        const midLayout = Config.options.bar.layouts.middleLayout ?? []
        if (midLayout.includes("clockWidget")) return "clock"
        return "clock"
    }

    readonly property string effectiveRightPin: {
        const pin = Config.options.bar.dynamicIsland.rightPin ?? "auto"
        if (pin !== "auto") return pin
        const rightLayout = Config.options.bar.layouts.rightLayout ?? []
        if (rightLayout.includes("systemIcons")) return "systemIcons"
        if (rightLayout.includes("batteryIndicator")) return "battery"
        if (rightLayout.includes("weatherBar")) return "weather"
        return "systemIcons"
    }

    component StatusGlyph: Item {
        id: glyph
        property string icon
        property color tone: Appearance.colors.colOnLayer0
        property bool toned: false
        property bool filled: false
        property var onTap: null
        implicitWidth: 20
        implicitHeight: 20

        MaterialSymbol {
            anchors.centerIn: parent
            text: glyph.icon
            iconSize: 14
            fill: glyph.filled ? 1 : 0
            color: glyph.tone
            opacity: glyph.toned ? 1 : 0.7
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: glyph.onTap ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (glyph.onTap) glyph.onTap()
        }
    }

    // Network speed tracker
    property real dlSpeed: 0
    property real ulSpeed: 0
    property real prevRx: -1
    property real prevTx: -1
    property double prevTime: 0

    FileView {
        id: netDevFile
        path: "/proc/net/dev"
        onLoaded: {
            const now = Date.now()
            let rx = 0
            let tx = 0
            const lines = text().split("\n")
            for (const line of lines) {
                const sep = line.indexOf(":")
                if (sep < 0) continue
                const iface = line.slice(0, sep).trim()
                if (!iface || iface === "lo") continue
                const fields = line.slice(sep + 1).trim().split(/\s+/)
                rx += Number(fields[0]) || 0
                tx += Number(fields[8]) || 0
            }
            if (diIdleRoot.prevTime > 0) {
                const dt = Math.max(0.5, (now - diIdleRoot.prevTime) / 1000)
                diIdleRoot.dlSpeed = Math.max(0, (rx - diIdleRoot.prevRx) / dt)
                diIdleRoot.ulSpeed = Math.max(0, (tx - diIdleRoot.prevTx) / dt)
            }
            diIdleRoot.prevRx = rx
            diIdleRoot.prevTx = tx
            diIdleRoot.prevTime = now
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: diIdleRoot.effectiveLeftPin === "networkSpeed"
        onTriggered: netDevFile.reload()
    }

    function formatSpeed(bytes) {
        if (bytes >= 1048576) return `${(bytes / 1048576).toFixed(1)}M`
        if (bytes >= 1024) return `${(bytes / 1024).toFixed(0)}K`
        return `${Math.round(bytes)}B`
    }

    RowLayout {
        id: row
        anchors {
            fill: parent
            leftMargin: 10
            rightMargin: 10
        }
        spacing: 10

        // Left Pin Widget
        Loader {
            Layout.alignment: Qt.AlignVCenter
            sourceComponent: {
                switch (diIdleRoot.effectiveLeftPin) {
                    case "battery":      return batteryComp
                    case "networkSpeed": return netSpeedComp
                    case "workspaces":   return workspacesComp
                    case "weather":      return weatherComp
                    case "glance":       return glanceComp
                    case "none":         return null
                    default:             return batteryComp
                }
            }
        }

        // Center / Middle Pin Widget
        Loader {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            sourceComponent: {
                switch (diIdleRoot.effectiveMiddlePin) {
                    case "clock":     return clockComp
                    case "dateClock": return dateClockComp
                    case "media":     return mediaComp
                    case "none":      return null
                    default:          return clockComp
                }
            }
        }

        // Privacy Indicator (inside the pill)
        Revealer {
            id: privacyRevealer
            reveal: IslandEvents.anyPrivacy && (Config.options.bar.dynamicIsland.privacyIndicators ?? true)
            Layout.alignment: Qt.AlignVCenter

            Item {
                implicitWidth: 11
                implicitHeight: 11

                Rectangle {
                    anchors.centerIn: parent
                    width: 7
                    height: 7
                    radius: 3.5
                    color: "#48D065"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: diIdleRoot.di.expandTo(2, "privacy")
                }
            }
        }

        // Right Pin Widget
        Loader {
            Layout.alignment: Qt.AlignVCenter
            sourceComponent: {
                switch (diIdleRoot.effectiveRightPin) {
                    case "systemIcons": return sysIconsComp
                    case "battery":     return batteryComp
                    case "weather":     return weatherComp
                    case "none":        return null
                    default:            return sysIconsComp
                }
            }
        }
    }

    // Component: Battery
    Component {
        id: batteryComp
        RowLayout {
            spacing: 3
            MaterialSymbol {
                text: Battery.isCharging ? "bolt"
                    : (Battery.percentage > 0.8 ? "battery_full" : (Battery.percentage > 0.2 ? "battery_5_bar" : "battery_alert"))
                iconSize: 15
                fill: 1
                color: Battery.percentage <= 0.2 && !Battery.isCharging ? Appearance.colors.colError : Appearance.colors.colOnLayer0
            }
            StyledText {
                text: `${Math.round(Battery.percentage * 100)}%`
                font.family: diIdleRoot.displayFont
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
                color: Appearance.colors.colOnLayer0
            }
        }
    }

    // Component: Network Speed
    Component {
        id: netSpeedComp
        RowLayout {
            spacing: 4
            MaterialSymbol {
                text: "arrow_downward"
                iconSize: 11
                color: Appearance.colors.colOnLayer0
                opacity: 0.7
            }
            StyledText {
                text: diIdleRoot.formatSpeed(diIdleRoot.dlSpeed)
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.features: { "tnum": 1 }
                color: Appearance.colors.colOnLayer0
            }
            MaterialSymbol {
                text: "arrow_upward"
                iconSize: 11
                color: Appearance.colors.colOnLayer0
                opacity: 0.7
            }
            StyledText {
                text: diIdleRoot.formatSpeed(diIdleRoot.ulSpeed)
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.features: { "tnum": 1 }
                color: Appearance.colors.colOnLayer0
            }
        }
    }

    // Component: Workspaces
    Component {
        id: workspacesComp
        RowLayout {
            spacing: 4
            Repeater {
                model: Math.min(5, NiriData.workspaces.length)
                Rectangle {
                    required property int index
                    readonly property var ws: NiriData.workspaces[index] ?? ({})
                    readonly property bool active: ws.is_active ?? (index === 0)
                    width: active ? 12 : 6
                    height: 6
                    radius: 3
                    color: active ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer0
                    opacity: active ? 1 : 0.4
                    Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }
            }
        }
    }

    // Component: Weather
    Component {
        id: weatherComp
        RowLayout {
            spacing: 3
            MaterialSymbol {
                text: IslandEvents.weatherSymbol(Weather.data?.wCode ?? 800, Weather.data?.night)
                iconSize: 14
                fill: 1
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: `${parseInt(Weather.data?.temp ?? "0") || 0}°`
                font.family: diIdleRoot.displayFont
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
                color: Appearance.colors.colOnLayer0
            }
        }
    }

    // Component: Glance (Date & day)
    Component {
        id: glanceComp
        StyledText {
            text: Qt.locale().toString(DateTime.clock.date, "ddd, d MMM")
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.Medium
            color: Appearance.colors.colOnLayer0
            opacity: 0.85
        }
    }

    // Component: Clock (Time)
    Component {
        id: clockComp
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: DateTime.time
            font.family: diIdleRoot.displayFont
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.DemiBold
            font.letterSpacing: 0.3
            font.features: { "tnum": 1 }
            color: Appearance.colors.colOnLayer0
        }
    }

    // Component: Date & Clock
    Component {
        id: dateClockComp
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6
            StyledText {
                text: Qt.locale().toString(DateTime.clock.date, "ddd, d MMM")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnLayer0
                opacity: 0.75
            }
            StyledText {
                text: DateTime.time
                font.family: diIdleRoot.displayFont
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
                color: Appearance.colors.colOnLayer0
            }
        }
    }

    // Component: Media (Track title & play state)
    Component {
        id: mediaComp
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 5
            MaterialSymbol {
                text: (MprisController.activePlayer?.isPlaying ?? false) ? "equalizer" : "music_note"
                iconSize: 14
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: MprisController.activePlayer?.trackTitle || DateTime.time
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer0
                elide: Text.ElideRight
                Layout.maximumWidth: 160
            }
        }
    }

    // Component: System Icons
    Component {
        id: sysIconsComp
        RowLayout {
            spacing: 2

            // DND
            Revealer {
                reveal: Notifications.silent
                StatusGlyph {
                    icon: "notifications_off"
                    tone: IslandEvents.colorAttention
                    toned: true
                    filled: true
                    onTap: () => Notifications.silent = false
                }
            }

            // Wi-Fi
            Revealer {
                reveal: true
                StatusGlyph {
                    icon: Network.materialSymbol || "wifi"
                    toned: Network.wifiStatus !== "disabled" && Network.wifiStatus !== "disconnected"
                    tone: Network.wifiStatus !== "disabled" ? Appearance.colors.colOnLayer0 : Appearance.colors.colError
                }
            }

            // Audio mute indicator
            Revealer {
                reveal: Audio.sink?.audio?.muted ?? false
                StatusGlyph {
                    icon: "volume_off"
                    tone: IslandEvents.colorAttention
                    toned: true
                }
            }

            // Bluetooth
            Revealer {
                reveal: BluetoothStatus.enabled
                StatusGlyph {
                    icon: BluetoothStatus.connected ? "bluetooth_connected" : "bluetooth"
                    toned: BluetoothStatus.connected
                    tone: BluetoothStatus.connected ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer0
                }
            }
        }
    }

    readonly property real computedIdleWidth: row.implicitWidth + row.anchors.leftMargin + row.anchors.rightMargin
    onComputedIdleWidthChanged: diIdleRoot.di.idleTextContentWidth = diIdleRoot.computedIdleWidth
    Component.onCompleted: diIdleRoot.di.idleTextContentWidth = diIdleRoot.computedIdleWidth
}
