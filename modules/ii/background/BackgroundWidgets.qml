import QtQuick
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets.calendar
import qs.modules.ii.background.widgets.clock
import qs.modules.ii.background.widgets.images
import qs.modules.ii.background.widgets.media
import qs.modules.ii.background.widgets.notes
import qs.modules.ii.background.widgets.resources
import qs.modules.ii.background.widgets.usercard
import qs.modules.ii.background.widgets.visualizer
import qs.modules.ii.background.widgets.weather
import qs.modules.ii.background.widgets.worldclock
import qs.modules.ii.background.widgets.customtext

// The desktop widgets, kept out of Background.qml so their type trees are
// compiled on the QML worker thread instead of ahead of the wallpaper.
WidgetCanvas {
    id: root

    // The background PanelWindow these widgets are placed on.
    required property var panel

    transitions: Transition {
        PropertyAnimation {
            properties: "width,height"
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
        AnchorAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
    }
    FadeLoader {
        shown: Config.options.background.widgets.visualizer.enable
            && (Config.options.background.screenList.length === 0
                || Config.options.background.screenList.includes(root.panel.screen.name))
        sourceComponent: VisualizerWidget {
            screenWidth: root.panel.screen.width
            screenHeight: root.panel.screen.height
            scaledScreenWidth: root.panel.screen.width
            scaledScreenHeight: root.panel.screen.height
            wallpaperScale: 1
        }
    }
    FadeLoader {
        shown: Config.options.background.widgets.customImage.enable
            && (Config.options.background.screenList.length === 0
                || Config.options.background.screenList.includes(root.panel.screen.name))
        sourceComponent: CustomImage {
            screenWidth:        root.panel.screen.width
            screenHeight:       root.panel.screen.height
            scaledScreenWidth:  root.panel.screen.width
            scaledScreenHeight: root.panel.screen.height
            wallpaperScale:     1
        }
    }
    FadeLoader {
        shown: Config.options.background.widgets.customText.enable
            && (Config.options.background.screenList.length === 0
                || Config.options.background.screenList.includes(root.panel.screen.name))
        sourceComponent: CustomTextWidget {
            screenWidth:        root.panel.screen.width
            screenHeight:       root.panel.screen.height
            scaledScreenWidth:  root.panel.screen.width
            scaledScreenHeight: root.panel.screen.height
            wallpaperScale:     1
        }
    }
    FadeLoader {
        shown: Config.options.background.widgets.calendar.enable
            && (Config.options.background.screenList.length === 0
                || Config.options.background.screenList.includes(root.panel.screen.name))
        sourceComponent: CalendarWidget {
            screenWidth: root.panel.screen.width
            screenHeight: root.panel.screen.height
            scaledScreenWidth: root.panel.screen.width
            scaledScreenHeight: root.panel.screen.height
            wallpaperScale: 1
        }
    }
    FadeLoader {
        shown: Config.options.background.widgets.weather.enable
            && (Config.options.background.screenList.length === 0
                || Config.options.background.screenList.includes(root.panel.screen.name))
        sourceComponent: WeatherWidget {
            screenWidth: root.panel.screen.width
            screenHeight: root.panel.screen.height
            scaledScreenWidth: root.panel.screen.width
            scaledScreenHeight: root.panel.screen.height
            wallpaperScale: 1
        }
    }
    FadeLoader {
        shown: Config.options.background.widgets.clock.enable
            && (GlobalStates.screenLocked
                || Config.options.background.screenList.length === 0
                || Config.options.background.screenList.includes(root.panel.screen.name))
        sourceComponent: ClockWidget {
            screenWidth: root.panel.screen.width
            screenHeight: root.panel.screen.height
            scaledScreenWidth: root.panel.screen.width
            scaledScreenHeight: root.panel.screen.height
            wallpaperScale: 1
            wallpaperSafetyTriggered: root.panel.wallpaperSafetyTriggered
        }
    }
    FadeLoader {
        shown: Config.options.background.widgets.notes.enable
            && (Config.options.background.screenList.length === 0
                || Config.options.background.screenList.includes(root.panel.screen.name))
        sourceComponent: NotesWidget {
            screenWidth: root.panel.screen.width
            screenHeight: root.panel.screen.height
            scaledScreenWidth: root.panel.screen.width
            scaledScreenHeight: root.panel.screen.height
            wallpaperScale: 1
        }
    }
    FadeLoader {
        id: mediaLoader
        property bool enableLoading: true
        shown: Config.options.background.widgets.media.enable && enableLoading
            && (Config.options.background.screenList.length === 0
                || Config.options.background.screenList.includes(root.panel.screen.name))
        sourceComponent: MediaWidget {
            screenWidth: root.panel.screen.width
            screenHeight: root.panel.screen.height
            scaledScreenWidth: root.panel.screen.width
            scaledScreenHeight: root.panel.screen.height
            wallpaperScale: 1
        }
        onLoaded: {
            if (item && item.requestReset) {
                item.requestReset.connect(() => {
                    mediaLoader.enableLoading = false
                    mediaTimer.running = true
                })
            }
        }
    }
    FadeLoader {
        shown: Config.options.background.widgets.images.enable
            && (Config.options.background.screenList.length === 0
                || Config.options.background.screenList.includes(root.panel.screen.name))
        sourceComponent: ImageConverterWidget {
            screenWidth:        root.panel.screen.width
            screenHeight:       root.panel.screen.height
            scaledScreenWidth:  root.panel.screen.width
            scaledScreenHeight: root.panel.screen.height
            wallpaperScale:     1
        }
    }
    FadeLoader {
        shown: Config.options.background.widgets.resources.enable
            && (Config.options.background.screenList.length === 0
                || Config.options.background.screenList.includes(root.panel.screen.name))
        sourceComponent: ResourcesWidget {
            screenWidth:        root.panel.screen.width
            screenHeight:       root.panel.screen.height
            scaledScreenWidth:  root.panel.screen.width
            scaledScreenHeight: root.panel.screen.height
            wallpaperScale:     1
        }
    }
    FadeLoader {
        shown: Config.options.background.widgets.worldClock.enable
            && (Config.options.background.screenList.length === 0
                || Config.options.background.screenList.includes(root.panel.screen.name))
        sourceComponent: WorldClockWidget {
            screenWidth: root.panel.screen.width
            screenHeight: root.panel.screen.height
            scaledScreenWidth: root.panel.screen.width
            scaledScreenHeight: root.panel.screen.height
            wallpaperScale: 1
        }
    }
    FadeLoader {
        shown: Config.options.background.widgets.userCard.enable
            && (Config.options.background.screenList.length === 0
                || Config.options.background.screenList.includes(root.panel.screen.name))
        sourceComponent: UserCardWidget {
            screenWidth: root.panel.screen.width
            screenHeight: root.panel.screen.height
            scaledScreenWidth: root.panel.screen.width
            scaledScreenHeight: root.panel.screen.height
            wallpaperScale: 1
        }
    }
}
