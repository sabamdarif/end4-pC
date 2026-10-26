pragma Singleton

import QtQuick
import Quickshell
import qs.services
import qs.modules.common

/**
 * The settings window navigation tree: eleven groups ordered after user mental model:
 * connections, hardware, appearance, shell, then system.
 *
 * Single source of truth for both the nav rail (modules/ii/settings/SettingsContent.qml)
 * and the launcher search (services/LauncherSearch.qml).
 *
 * Every `key` is stable and untranslated. GlobalStates.settingsPage deep links match on it.
 */
Singleton {
    id: root

    function page(path) {
        return Qt.resolvedUrl("pages/" + path)
    }

    readonly property var legacyAliases: ({
        "blocky": "dns",
        "osd": "notifications",
        "cursor": "icon-themes",
        "transparency": "windows-effects",
        "window-appearance": "windows-effects",
        "animations": "windows-effects",
        "bar-position": "bar",
        "bar-layout": "bar",
        "wallpaper-picker": "wallpaper",
        "output-device": "sound",
        "input-device": "sound",
        "volume": "sound",
        "system-sounds": "sound"
    })

    readonly property var groups: [
        {
            key: "network", name: Translation.tr("Network and Bluetooth"), icon: "wifi",
            children: [
                { key: "wifi",      name: Translation.tr("Wi-Fi"),          icon: "wifi",      component: root.page("network/WifiConfig.qml") },
                { key: "bluetooth", name: Translation.tr("Bluetooth"),      icon: "bluetooth", component: root.page("network/BluetoothConfig.qml") },
                { key: "ethernet",  name: Translation.tr("Ethernet"),       icon: "lan",       component: root.page("network/EthernetConfig.qml") },
                { key: "vpn",       name: Translation.tr("VPN"),            icon: "vpn_key",   component: root.page("network/VpnConfig.qml") },
                { key: "dns",       name: Translation.tr("DNS and Blocky"), icon: "dns",       component: root.page("network/DnsConfig.qml") },
            ]
        },
        {
            key: "sound", name: Translation.tr("Sound"), icon: "volume_up",
            children: [
                { key: "sound", name: Translation.tr("Sound"), icon: "volume_up", component: root.page("sound/SoundConfig.qml") },
            ]
        },
        {
            key: "displays", name: Translation.tr("Displays"), icon: "desktop_windows",
            children: [
                { key: "monitors", name: Translation.tr("Monitors"), icon: "monitor", component: root.page("displays/NiriMonitorsConfig.qml") },
            ]
        },
        {
            key: "appearance", name: Translation.tr("Appearance"), icon: "palette",
            children: [
                { key: "wallpaper",       name: Translation.tr("Wallpaper"),           icon: "panorama",    component: root.page("style/WallpaperConfig.qml") },
                { key: "colors",          name: Translation.tr("Colors and Theme"),    icon: "colors",      component: root.page("style/ColorsConfig.qml") },
                { key: "fonts",           name: Translation.tr("Fonts"),               icon: "font_download", component: root.page("style/FontsConfig.qml") },
                { key: "icon-themes",     name: Translation.tr("Icons and Themes"),    icon: "interests",   component: root.page("style/IconThemesConfig.qml") },
                { key: "windows-effects", name: Translation.tr("Windows and Effects"), icon: "deblur",      component: root.page("style/WindowsEffectsConfig.qml") },
            ]
        },
        {
            key: "input", name: Translation.tr("Input"), icon: "keyboard",
            children: [
                { key: "keyboard",  name: Translation.tr("Keyboard"),           icon: "keyboard",       component: root.page("input/NiriKeyboardConfig.qml") },
                { key: "pointer",   name: Translation.tr("Mouse and Touchpad"), icon: "trackpad_input", component: root.page("input/NiriPointerConfig.qml") },
                { key: "shortcuts", name: Translation.tr("Shortcuts"),          icon: "keyboard_keys", component: root.page("input/ShortcutsConfig.qml") },
            ]
        },
        {
            key: "workspaces", name: Translation.tr("Windows and Workspaces"), icon: "select_window_2",
            children: [
                { key: "tiling",       name: Translation.tr("Layout and Focus"),         icon: "auto_awesome_mosaic", component: root.page("compositor/NiriLayoutConfig.qml") },
                { key: "window-rules", name: Translation.tr("Window rules"),             icon: "splitscreen",         component: root.page("compositor/WindowRulesConfig.qml") },
                { key: "gestures",     name: Translation.tr("Gestures and Hot Corners"), icon: "gesture",             component: root.page("compositor/GesturesConfig.qml") },
            ]
        },
        {
            key: "apps", name: Translation.tr("Apps"), icon: "apps",
            children: [
                { key: "default-apps", name: Translation.tr("Default Apps"),        icon: "apps",          component: root.page("apps/DefaultAppsConfig.qml") },
                { key: "autostart",    name: Translation.tr("Autostart"),           icon: "rocket_launch", component: root.page("apps/AutostartConfig.qml") },
                { key: "clipboard",    name: Translation.tr("Clipboard"),           icon: "content_paste", component: root.page("apps/ClipboardConfig.qml") },
                { key: "flatpak",      name: Translation.tr("Flatpak Permissions"),  icon: "extension",     component: root.page("apps/FlatpakPermissionsConfig.qml") },
            ]
        },
        {
            key: "shell", name: Translation.tr("Shell"), icon: "dock_to_bottom",
            children: [
                { key: "bar",           name: Translation.tr("Bar"),                   icon: "toast", iconRotation: 180, component: root.page("bar/BarConfig.qml") },
                { key: "dock",          name: Translation.tr("Dock"),                  icon: "call_to_action",           component: root.page("panels/DockConfig.qml") },
                { key: "right-sidebar", name: Translation.tr("Side panel"),            icon: "splitscreen_right",        component: root.page("panels/RightSidebarConfig.qml") },
                { key: "notifications", name: Translation.tr("Notifications and OSD"), icon: "notifications",            component: root.page("notifications/NotificationsOsdConfig.qml") },
                { key: "search",        name: Translation.tr("Search"),                icon: "search",                   component: root.page("system/SearchConfig.qml") },
            ]
        },
        {
            key: "desktop", name: Translation.tr("Desktop"), icon: "texture",
            children: [
                { key: "desktop-clock",   name: Translation.tr("Clock"),        icon: "nest_clock_farsight_analog", component: root.page("desktop/ClockConfig.qml") },
                { key: "desktop-widgets", name: Translation.tr("Widgets"),      icon: "widgets",         component: root.page("desktop/WidgetsConfig.qml") },
                { key: "custom-image",    name: Translation.tr("Custom Image"), icon: "image",           component: root.page("desktop/CustomImageConfig.qml") },
                { key: "overlay",         name: Translation.tr("Overlay"),      icon: "layers",          component: root.page("desktop/OverlayConfig.qml") },
            ]
        },
        {
            key: "privacy", name: Translation.tr("Privacy and Security"), icon: "security",
            children: [
                { key: "lock-screen",  name: Translation.tr("Lock screen"),  icon: "lock",        component: root.page("displays/LockScreenConfig.qml") },
                { key: "permissions",  name: Translation.tr("Permissions"),  icon: "key",         component: root.page("privacy/PermissionsConfig.qml") },
                { key: "location",     name: Translation.tr("Location"),     icon: "location_on", component: root.page("privacy/LocationConfig.qml") },
                { key: "firewall",     name: Translation.tr("Firewall"),     icon: "shield",      component: root.page("privacy/FirewallConfig.qml") },
            ]
        },
        {
            key: "system", name: Translation.tr("System"), icon: "settings",
            children: [
                { key: "users",     name: Translation.tr("Users"),               icon: "person",                component: root.page("Profile.qml") },
                { key: "presets",   name: Translation.tr("Presets"),             icon: "tune",                  component: root.page("Profile.qml") },
                { key: "updates",   name: Translation.tr("Updates and Storage"), icon: "deployed_code_update",  component: root.page("system/UpdatesConfig.qml") },
                { key: "battery",   name: Translation.tr("Battery"),             icon: "battery_android_frame_full", component: root.page("system/BatteryConfig.qml") },
                { key: "date-time", name: Translation.tr("Date and Time"),       icon: "nest_clock_farsight_analog", component: root.page("system/DateTimeConfig.qml") },
                { key: "weather",   name: Translation.tr("Weather"),             icon: "flare",                 component: root.page("system/WeatherConfig.qml") },
                { key: "about",     name: Translation.tr("About"),               icon: "info",                  component: root.page("About.qml") },
                { key: "gallery",   name: Translation.tr("Component Gallery"),   icon: "palette",               component: root.page("dev/ComponentGallery.qml") },
            ]
        },
    ]

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

    function resolveKey(key) {
        if (!key) return ""
        if (root.leafIndex(key) >= 0) return key
        if (key in root.legacyAliases) {
            let mapped = root.legacyAliases[key]
            if (root.leafIndex(mapped) >= 0) return mapped
        }
        return ""
    }

    function leafIndex(key) {
        return root.leaves.findIndex(l => l.key === key)
    }

    function groupOf(key) {
        const resolved = root.resolveKey(key)
        const leaf = root.leaves.find(l => l.key === resolved)
        return leaf ? leaf.groupKey : ""
    }
}
