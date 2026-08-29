import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import qs.modules.common.functions
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models

ContentPage {
    id: page
    forceWidth: true

    NiriIncludeNotice {}

    MonitorConfigOption { id: monitorConfig }

    ContentSection {
        icon: "monitor"
        shape: MaterialShape.Shape.ClamShell
        title: Translation.tr("Displays")
        visible: monitorConfig.monitors.length > 0

        MonitorCanvas {
            id: monitorCanvas
            Layout.fillWidth: true
            monitorConfig: monitorConfig
        }

        ContentSubsection {
            Layout.topMargin: 10
            title: (monitorConfig.monitors[monitorCanvas.selectedIndex]?.name ?? "")
                + " · "
                + (monitorConfig.monitors[monitorCanvas.selectedIndex]?.description ?? "")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "tv_off"
                    text: Translation.tr("Enabled")
                    checked: !(monitorConfig.monitors[monitorCanvas.selectedIndex]?.disabled ?? false)
                    onCheckedChanged: {
                        if (checked === !(monitorConfig.monitors[monitorCanvas.selectedIndex]?.disabled ?? false)) return
                        monitorConfig.updateMonitor(monitorCanvas.selectedIndex, { disabled: !checked })
                        monitorConfig.applyAndSave(monitorCanvas.selectedIndex)
                    }
                }

                ConfigComboBox {
                    Layout.fillWidth: true
                    buttonIcon: "aspect_ratio"
                    text: Translation.tr("Resolution & Refresh Rate")
                    textRole: "display"
                    model: (monitorConfig.monitors[monitorCanvas.selectedIndex]?.availableModes ?? [])
                        .map(mode => ({ display: mode, value: mode }))
                    currentValue: monitorConfig.monitors[monitorCanvas.selectedIndex]?.currentMode ?? ""
                    onSelected: newValue => {
                        const mode = newValue
                        const parts = mode.match(/(\d+)x(\d+)@([\d.]+)Hz/)
                        monitorConfig.updateMonitor(monitorCanvas.selectedIndex, {
                            currentMode: mode,
                            width: parseInt(parts[1]),
                            height: parseInt(parts[2]),
                            refreshRate: parseFloat(parts[3])
                        })
                        monitorConfig.applyAndSave(monitorCanvas.selectedIndex)
                    }
                }

                ConfigSelectionArray {
                    text: Translation.tr("Orientation")
                    icon: "mobile_rotate"
                    currentValue: monitorConfig.monitors[monitorCanvas.selectedIndex]?.transform ?? 0
                    onSelected: newValue => {
                        monitorConfig.updateMonitor(monitorCanvas.selectedIndex, { transform: newValue })
                        monitorConfig.applyAndSave(monitorCanvas.selectedIndex)
                    }
                    options: [
                        { displayName: Translation.tr("Normal"), icon: "screen_rotation_alt", value: 0 },
                        { displayName: "90°",                    icon: "rotate_90_degrees_cw",  value: 1 },
                        { displayName: "180°",                   icon: "screen_rotation",       value: 2 },
                        { displayName: "270°",                   icon: "rotate_90_degrees_ccw", value: 3 },
                    ]
                }

                ConfigSwitch {
                    buttonIcon: "autoplay"
                    text: Translation.tr("Variable refresh rate (VRR)")
                    checked: monitorConfig.monitors[monitorCanvas.selectedIndex]?.vrr ?? false
                    onCheckedChanged: {
                        if (checked === (monitorConfig.monitors[monitorCanvas.selectedIndex]?.vrr ?? false)) return
                        monitorConfig.updateMonitor(monitorCanvas.selectedIndex, { vrr: checked })
                        monitorConfig.applyAndSave(monitorCanvas.selectedIndex)
                    }
                }

                ConfigSpinBox {
                    icon: "zoom_in"
                    text: Translation.tr("Scale")
                    value: Math.round((monitorConfig.monitors[monitorCanvas.selectedIndex]?.scale ?? 1.0) * 100)
                    from: 50; to: 300; stepSize: 25
                    onValueChanged: {
                        const newVal = value / 100.0
                        if (newVal === (monitorConfig.monitors[monitorCanvas.selectedIndex]?.scale ?? 1.0)) return
                        monitorConfig.updateMonitor(monitorCanvas.selectedIndex, { scale: newVal })
                        monitorConfig.applyAndSave(monitorCanvas.selectedIndex)
                    }
                }

                ConfigSpinBox {
                    icon: "swap_horiz"
                    text: Translation.tr("Position X")
                    value: monitorConfig.monitors[monitorCanvas.selectedIndex]?.x ?? 0
                    from: 0; to: 7680; stepSize: 1
                    onValueChanged: {
                        if (value === (monitorConfig.monitors[monitorCanvas.selectedIndex]?.x ?? 0)) return
                        monitorConfig.updateMonitor(monitorCanvas.selectedIndex, { x: value })
                        monitorConfig.applyAndSave(monitorCanvas.selectedIndex)
                    }
                }

                ConfigSpinBox {
                    icon: "swap_vert"
                    text: Translation.tr("Position Y")
                    value: monitorConfig.monitors[monitorCanvas.selectedIndex]?.y ?? 0
                    from: 0; to: 4320; stepSize: 1
                    onValueChanged: {
                        if (value === (monitorConfig.monitors[monitorCanvas.selectedIndex]?.y ?? 0)) return
                        monitorConfig.updateMonitor(monitorCanvas.selectedIndex, { y: value })
                        monitorConfig.applyAndSave(monitorCanvas.selectedIndex)
                    }
                }
            }
        }
    }
}
