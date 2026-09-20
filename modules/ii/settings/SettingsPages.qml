pragma Singleton

import QtQuick
import Quickshell
import qs.services
import qs.modules.common

/**
 * The settings window's navigation tree: collapsible groups of leaf pages,
 * ordered after Android's Settings (AOSP res/xml/top_level_settings.xml).
 *
 * Single source of truth for both the nav rail (modules/ii/settings/SettingsContent.qml)
 * and the launcher's `settings:` search (services/LauncherSearch.qml).
 *
 * Every `key` is stable and untranslated — GlobalStates.settingsPage deep links
 * match on it, so never key navigation off a display name or a list index.
 * A group with a `component` and no `children` is a leaf in the rail itself.
 */
Singleton {
    id: root

    function page(path) {
        return Qt.resolvedUrl("pages/" + path)
    }

    readonly property var groups: [
        {
            key: "network", name: Translation.tr("Network & Internet"), icon: "wifi",
            children: [
                { key: "wifi",      name: Translation.tr("Wi-Fi"),     icon: "wifi",      component: root.page("network/WifiConfig.qml") },
                { key: "bluetooth", name: Translation.tr("Bluetooth"), icon: "bluetooth", component: root.page("network/BluetoothConfig.qml") },
                { key: "ethernet",  name: Translation.tr("Ethernet"),  icon: "lan",       component: root.page("network/EthernetConfig.qml") },
                { key: "vpn",       name: Translation.tr("VPN"),       icon: "vpn_key",   component: root.page("network/VpnConfig.qml") },
                { key: "dns",       name: Translation.tr("DNS"),       icon: "dns",       component: root.page("network/DnsConfig.qml") },
                { key: "blocky",    name: Translation.tr("Blocky"),    icon: "shield",    component: root.page("network/BlockyConfig.qml") },
            ]
        },
        {
            key: "displays", name: Translation.tr("Displays"), icon: "desktop_windows",
            children: [
                { key: "monitors",       name: Translation.tr("Monitors"),          icon: "monitor",       component: root.page("displays/NiriMonitorsConfig.qml") },
                { key: "lock-screen",    name: Translation.tr("Lock Screen"),       icon: "lock",            component: root.page("displays/LockScreenConfig.qml") },
                { key: "screen-corners", name: Translation.tr("Screen Corners"),    icon: "rounded_corner",  component: root.page("displays/ScreenCornersConfig.qml") },
                { key: "osd",            name: Translation.tr("On-screen Display"), icon: "brightness_medium", component: root.page("displays/OsdConfig.qml") },
            ]
        },
        {
            key: "input", name: Translation.tr("Input"), icon: "keyboard",
            children: [
                { key: "keyboard", name: Translation.tr("Keyboard"),          icon: "keyboard",       component: root.page("input/NiriKeyboardConfig.qml") },
                { key: "pointer",  name: Translation.tr("Touchpad & Mouse"), icon: "trackpad_input", component: root.page("input/NiriPointerConfig.qml") },
                { key: "cursor",    name: Translation.tr("Cursor"),             icon: "mouse",    component: root.page("input/CursorConfig.qml") },
                { key: "shortcuts", name: Translation.tr("Keyboard Shortcuts"), icon: "keyboard_keys", component: root.page("input/ShortcutsConfig.qml") },
            ]
        },
        {
            key: "apps", name: Translation.tr("Apps"), icon: "apps",
            children: [
                { key: "default-apps", name: Translation.tr("Default Applications"),  icon: "apps",          component: root.page("apps/DefaultAppsConfig.qml") },
                { key: "autostart",    name: Translation.tr("Autostart"),             icon: "rocket_launch", component: root.page("apps/AutostartConfig.qml") },
                { key: "clipboard",    name: Translation.tr("Clipboard"),             icon: "content_paste", component: root.page("apps/ClipboardConfig.qml") },
                { key: "app-ids",      name: Translation.tr("App ID Substitutions"),  icon: "swap_horiz",    component: root.page("apps/AppIdsConfig.qml") },
                { key: "all-apps",     name: Translation.tr("All Apps"),               icon: "app_badging",   component: root.page("apps/AllAppsConfig.qml") },
            ]
        },
        {
            key: "notifications", name: Translation.tr("Notifications"), icon: "notifications",
            component: root.page("notifications/PopupsConfig.qml"), children: []
        },
        {
            key: "sound", name: Translation.tr("Sound"), icon: "volume_up",
            children: [
                { key: "volume",        name: Translation.tr("Volume & Limits"), icon: "volume_up",           component: root.page("sound/VolumeConfig.qml") },
                { key: "output-device", name: Translation.tr("Output Device"),   icon: "speaker",             component: root.page("sound/OutputDeviceConfig.qml") },
                { key: "input-device",  name: Translation.tr("Input Device"),    icon: "mic",                 component: root.page("sound/InputDeviceConfig.qml") },
                { key: "system-sounds", name: Translation.tr("System Sounds"),   icon: "notification_sound",  component: root.page("sound/SystemSoundsConfig.qml") },
            ]
        },
        {
            key: "style", name: Translation.tr("Wallpaper & Style"), icon: "palette",
            children: [
                { key: "wallpaper",        name: Translation.tr("Wallpaper"),          icon: "panorama",     component: root.page("style/WallpaperConfig.qml") },
                { key: "wallpaper-picker", name: Translation.tr("Wallpaper Picker"),   icon: "wallpaper",    component: root.page("style/WallpaperPickerConfig.qml") },
                { key: "colors",           name: Translation.tr("Colors & Theme"),     icon: "colors",       component: root.page("style/ColorsConfig.qml") },
                { key: "transparency",     name: Translation.tr("Transparency"),       icon: "motion_mode",  component: root.page("style/TransparencyConfig.qml") },
                { key: "fonts",            name: Translation.tr("Fonts"),              icon: "font_download", component: root.page("style/FontsConfig.qml") },
                { key: "icon-themes",      name: Translation.tr("Icons & App Themes"), icon: "interests",    component: root.page("style/IconThemesConfig.qml") },
            ]
        },
        {
            key: "compositor", name: Translation.tr("Niri"), icon: "select_window_2",
            children: [
                { key: "tiling",            name: Translation.tr("Tiling & Layout"),      icon: "auto_awesome_mosaic", component: root.page("compositor/NiriLayoutConfig.qml") },
                { key: "window-appearance", name: Translation.tr("Appearance & Effects"), icon: "deblur",              component: root.page("compositor/NiriAppearanceConfig.qml") },
                { key: "animations",        name: Translation.tr("Animations"),           icon: "animation",           component: root.page("compositor/NiriAnimationsConfig.qml") },
            ]
        },
        {
            key: "bar", name: Translation.tr("Bar"), icon: "toast", iconRotation: 180,
            children: [
                { key: "bar-layout",       name: Translation.tr("Layout"),            icon: "splitscreen_add",     component: root.page("bar/LayoutConfig.qml") },
                { key: "bar-position",     name: Translation.tr("Position & Style"),  icon: "pivot_table_chart",   component: root.page("bar/PositionStyleConfig.qml") },
                { key: "bar-workspaces",   name: Translation.tr("Workspaces"),        icon: "steppers",            component: root.page("bar/WorkspacesConfig.qml") },
                { key: "bar-resources",    name: Translation.tr("Resources"),         icon: "empty_dashboard",     component: root.page("bar/ResourcesConfig.qml") },
                { key: "bar-media",        name: Translation.tr("Media"),             icon: "music_note",          component: root.page("bar/MediaConfig.qml") },
                { key: "bar-tray",         name: Translation.tr("Tray"),              icon: "inbox",               component: root.page("bar/TrayConfig.qml") },
                { key: "bar-util-buttons", name: Translation.tr("Utility Buttons"),   icon: "toggle_on",           component: root.page("bar/UtilButtonsConfig.qml") },
                { key: "bar-privacy",      name: Translation.tr("Privacy"),           icon: "shield_lock",         component: root.page("bar/PrivacyConfig.qml") },
                { key: "bar-divider",      name: Translation.tr("Divider & Tooltips"), icon: "horizontal_distribute", component: root.page("bar/DividerTooltipsConfig.qml") },
                { key: "bar-screens",      name: Translation.tr("Screens"),           icon: "monitor",             component: root.page("bar/ScreensConfig.qml") },
            ]
        },
        {
            key: "desktop", name: Translation.tr("Desktop"), icon: "texture",
            children: [
                { key: "desktop-clock",   name: Translation.tr("Clock"),           icon: "nest_clock_farsight_analog", component: root.page("desktop/ClockConfig.qml") },
                { key: "desktop-widgets", name: Translation.tr("Widgets"),         icon: "widgets",         component: root.page("desktop/WidgetsConfig.qml") },
                { key: "custom-image",    name: Translation.tr("Custom Image"),    icon: "image",           component: root.page("desktop/CustomImageConfig.qml") },
                { key: "overlay",         name: Translation.tr("Overlay"),         icon: "layers",          component: root.page("desktop/OverlayConfig.qml") },
                { key: "region-selector", name: Translation.tr("Region Selector"), icon: "screenshot_region", component: root.page("desktop/RegionSelectorConfig.qml") },
            ]
        },
        {
            key: "panels", name: Translation.tr("Panels"), icon: "dock_to_bottom",
            children: [
                { key: "dock",          name: Translation.tr("Dock"),          icon: "call_to_action",   component: root.page("panels/DockConfig.qml") },
                { key: "left-sidebar",  name: Translation.tr("Left Sidebar"),  icon: "splitscreen_left", component: root.page("panels/LeftSidebarConfig.qml") },
                { key: "right-sidebar", name: Translation.tr("Right Sidebar"), icon: "splitscreen_right", component: root.page("panels/RightSidebarConfig.qml") },
            ]
        },
        {
            key: "system", name: Translation.tr("System"), icon: "settings",
            children: [
                { key: "date-time",         name: Translation.tr("Date & Time"),        icon: "nest_clock_farsight_analog", component: root.page("system/DateTimeConfig.qml") },
                { key: "language",          name: Translation.tr("Language & Region"),  icon: "translate",       component: root.page("system/LanguageConfig.qml") },
                { key: "battery",           name: Translation.tr("Battery"),            icon: "battery_android_frame_full", component: root.page("system/BatteryConfig.qml") },
                { key: "updates",           name: Translation.tr("Updates"),            icon: "deployed_code_update", component: root.page("system/UpdatesConfig.qml") },
                { key: "weather",           name: Translation.tr("Weather"),            icon: "flare",           component: root.page("system/WeatherConfig.qml") },
                { key: "ai",                name: Translation.tr("AI"),                 icon: "neurology",       component: root.page("system/AiConfig.qml") },
                { key: "search",            name: Translation.tr("Search"),             icon: "search",          component: root.page("system/SearchConfig.qml") },
                { key: "save-paths",        name: Translation.tr("Save Paths"),         icon: "folder",          component: root.page("system/SavePathsConfig.qml") },
                { key: "network-requests",  name: Translation.tr("Network Requests"),   icon: "cloud",           component: root.page("system/NetworkRequestsConfig.qml") },
                { key: "music-recognition", name: Translation.tr("Music Recognition"),  icon: "music_cast",      component: root.page("system/MusicRecognitionConfig.qml") },
                { key: "content-filter",    name: Translation.tr("Content Filter"),     icon: "shield_person",   component: root.page("system/ContentFilterConfig.qml") },
            ]
        },
        {
            key: "about", name: Translation.tr("About"), icon: "info",
            component: root.page("About.qml"), children: []
        },
    ]

    // Flattened leaves, in rail order. `groupKey` lets the rail auto-expand the
    // owning group when a leaf is selected from search or a deep link.
    readonly property var leaves: {
        let out = []
        for (const g of root.groups) {
            if (g.children.length === 0) {
                out.push({ key: g.key, name: g.name, icon: g.icon, iconRotation: g.iconRotation ?? 0,
                           component: g.component, groupKey: g.key, groupName: g.name })
                continue
            }
            for (const c of g.children)
                out.push({ key: c.key, name: c.name, icon: c.icon, iconRotation: c.iconRotation ?? 0,
                           component: c.component, groupKey: g.key, groupName: g.name })
        }
        return out
    }

    function leafIndex(key) {
        return root.leaves.findIndex(l => l.key === key)
    }

    function groupOf(key) {
        const leaf = root.leaves.find(l => l.key === key)
        return leaf ? leaf.groupKey : ""
    }
}
