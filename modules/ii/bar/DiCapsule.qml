import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

RowLayout {
    id: capsule
    required property Item di
    required property string providerId
    property bool showLabel: true
    property color textColor: Appearance.colors.colOnLayer1
    spacing: 4

    readonly property var activity: IslandEvents.latestActivity

    readonly property string icon: {
        switch (capsule.providerId) {
            case "recording":     return "fiber_manual_record"
            case "timer":         return capsule.di.timerIcon()
            case "activity":      return capsule.activity?.icon ?? "bolt"
            case "display":       return "desktop_windows"
            case "notification":  return "notifications"
            case "osd":           return GlobalStates.osdIndicatorType === "brightness" ? "light_mode" : "volume_up"
            case "battery":       return capsule.di.batteryIcon()
            case "bluetooth":     return "bluetooth"
            case "audioOutput":   return IslandEvents.audioOutput.payload?.icon ?? "speaker"
            case "screenshot":    return "screenshot_monitor"
            case "weather":       return "rainy"
            case "privacy":       return "privacy_tip"
            case "hardware":      return IslandHardware.payload.icon ?? "memory"
            case "session":       return "power_settings_new"
            case "idle":          return "home"
            case "media":         return "music_note"
            case "download":      return "download"
            case "networkAlert":  return "wifi"
            case "history":       return "history"
            default:              return "stacks"
        }
    }

    readonly property string label: {
        switch (capsule.providerId) {
            case "recording":     return capsule.di.formatRecordingTime(capsule.di.recordingElapsedSeconds)
            case "timer":         return capsule.di.timerValueText()
            case "activity":      return capsule.activity?.title ?? ""
            case "media":         return capsule.di.activePlayer?.trackTitle ?? ""
            case "notification":  return IslandEvents.notificationParts(capsule.di.latestNotification).app || Translation.tr("Notification")
            case "osd":           return `${Math.round(Audio.value * 100)}%`
            case "battery":       return `${Math.round(Battery.percentage * 100)}%`
            case "bluetooth":     return IslandEvents.bluetooth.payload?.name ?? ""
            case "audioOutput":   return IslandEvents.audioOutput.payload?.name ?? ""
            case "screenshot":    return Translation.tr("Screenshots")
            case "display":       return Translation.tr("Second screen")
            case "weather":       return IslandEvents.weather.payload?.temp ?? ""
            case "privacy":       return Translation.tr("Privacy")
            case "hardware":      return IslandHardware.payload.title ?? ""
            case "download":      return IslandEvents.downloadFileName !== "" ? IslandEvents.downloadFileName
                : IslandEvents.formatBytes(IslandEvents.downloadRate, true)
            case "history":       return IslandEvents.eventLog[0]?.title ?? ""
            case "idle":          return DateTime.time
            default:              return ""
        }
    }

    property bool hovered: false
    readonly property bool compactLabel: ["recording", "timer"].includes(capsule.providerId)
    readonly property bool labelVisible: (capsule.showLabel && capsule.compactLabel) || capsule.hovered

    readonly property string shortLabel: {
        const head = capsule.label.split(" · ")[0].trim()
        return head.length > 16 ? `${head.slice(0, 15)}…` : head
    }

    readonly property color accent: {
        switch (capsule.providerId) {
            case "recording":    return Appearance.colors.colError
            case "activity":     return capsule.activity?.state === "error" ? Appearance.colors.colError : Appearance.colors.colPrimary
            case "notification": return IslandEvents.appColor(IslandEvents.notificationParts(capsule.di.latestNotification).app, Appearance.colors.colPrimary)
            case "battery":      return capsule.di.batteryAlertColor()
            case "privacy":      return IslandEvents.micInUse ? IslandEvents.colorAttention : IslandEvents.colorSuccess
            default:             return capsule.textColor
        }
    }

    readonly property real ringValue: {
        switch (capsule.providerId) {
            case "timer":    return capsule.di.timerProgress()
            case "activity": return capsule.activity?.progress ?? -1
            default:         return -1
        }
    }

    Item {
        Layout.leftMargin: 4
        Layout.rightMargin: capsule.labelVisible ? 0 : 4
        implicitWidth: 24
        implicitHeight: 24

        CircularProgress {
            anchors.fill: parent
            visible: capsule.ringValue >= 0
            implicitSize: 24
            lineWidth: 2
            value: Math.max(0, capsule.ringValue)
            colPrimary: capsule.accent
            colSecondary: ColorUtils.transparentize(capsule.accent, 0.75)
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            clip: true
            color: Appearance.colors.colLayer2
            visible: capsule.providerId === "media" && (capsule.di.activePlayer?.trackArtUrl ?? "") !== ""

            StyledImage {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: capsule.di.activePlayer?.trackArtUrl ?? ""
                sourceSize.width: 48
                sourceSize.height: 48
            }

        }

        MaterialSymbol {
            anchors.centerIn: parent
            visible: !(capsule.providerId === "media" && (capsule.di.activePlayer?.trackArtUrl ?? "") !== "")
            text: capsule.icon
            iconSize: capsule.ringValue >= 0 ? 13 : 17
            fill: 1
            color: capsule.accent

        }
    }

    StyledText {
        Layout.rightMargin: 9
        Layout.maximumWidth: capsule.di.hoverRevealed ? 150 : 110
        visible: capsule.labelVisible
        text: capsule.di.hoverRevealed ? capsule.label : capsule.shortLabel
        font.pixelSize: Appearance.font.pixelSize.smaller
        font.weight: Font.DemiBold
        font.features: { "tnum": 1 }
        color: capsule.textColor
        elide: Text.ElideRight
    }
}
