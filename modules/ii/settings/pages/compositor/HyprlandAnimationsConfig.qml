import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    HyprlandConfigSync {}

    ContentSection {
        icon: "animation"
        shape: MaterialShape.Shape.Oval
        title: Translation.tr("Animations")
        GroupedList {
            ConfigSwitch {
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.hyprland.animations.enable
                onCheckedChanged: {
                    if (checked === Config.options.hyprland.animations.enable) return
                    Config.options.hyprland.animations.enable = checked
                    HyprlandConfig.set("animations:enabled", checked ? 1 : 0)
                }
            }
            ConfigSelectionArray {
                text: Translation.tr("Presets")
                icon: "present_to_all"
                currentValue: Config.options.hyprland.animations.animation
                onSelected: newValue => {
                    Config.options.hyprland.animations.animation = newValue
                    saveAnimProc.command = [
                        "python3",
                        HyprlandConfig.configuratorScriptPath,
                        "--anim-preset", newValue
                    ]
                    saveAnimProc.running = true
                }
                options: [
                    { displayName: Translation.tr("Elastic"),   icon: "move_selection_right", value: "fast"   },
                    { displayName: Translation.tr("Normal"),    icon: "animation",            value: "normal" },
                    { displayName: Translation.tr("Niri Like"), icon: "mobiledata_arrows",    value: "niri"   },
                ]
            }
        }

        NoticeBox {
            Layout.fillWidth: true
            Layout.topMargin: 15
            text: Translation.tr("Animation presets require a require line in your hyprland.lua. Add the following line to enable presets:") + '\n\nrequire("hyprland/shellOverrides/animations")'

            Item { Layout.fillWidth: true }

            RippleButtonWithIcon {
                id: copySourceButton
                property bool justCopied: false
                Layout.fillWidth: false
                buttonRadius: Appearance.rounding.small
                materialIcon: justCopied ? "check" : "content_copy"
                mainText: justCopied ? Translation.tr("Copied!") : Translation.tr("Copy line")
                onClicked: {
                    copySourceButton.justCopied = true
                    Quickshell.clipboardText = 'require("hyprland/shellOverrides/animations")'
                    revertSourceTimer.restart()
                }
                colBackground: ColorUtils.transparentize(Appearance.colors.colPrimaryContainer)
                colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                colRipple: Appearance.colors.colPrimaryContainerActive
                Timer {
                    id: revertSourceTimer
                    interval: 1500
                    onTriggered: copySourceButton.justCopied = false
                }
            }
        }

        Process {
            id: saveAnimProc
            onRunningChanged: if (!running) reloadAnimProc.running = true
        }
        Process {
            id: reloadAnimProc
            command: ["hyprctl", "reload"]
        }
    }
}
