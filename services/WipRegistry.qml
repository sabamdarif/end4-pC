pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // Feature ID -> isWip flag (true: placeholder under overlay, false: live feature)
    readonly property var flags: ({
        "permissions": true,
        "location": true,
        "firewall": true,
        "ethernet_config": true,
        "hidden_wifi": true,
        "wifi_qr": true,
        "network_details": true,
        "bluetooth_visibility": true,
        "bluetooth_device_details": true,
        "xkb_remap": true,
        "terminal_picker": true,
        "flatpak_permissions": true,
        "window_rules": true,
        "inactive_window_opacity": true,
        "gestures_hotcorners": true,
        "per_monitor_wallpaper": true,
        "wallpaper_fit": true,
        "theme_schedule": true,
        "qt_theme": true,
        "reboot_indicator": true,
        "firmware_updates": true,
        "storage_cleanup": true,
        "kernel_gpu_info": true
    })

    function isWip(featureId) {
        if (!featureId || featureId === "") return false
        return root.flags[featureId] === true
    }
}
