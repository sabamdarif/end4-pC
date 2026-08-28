import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    ContentSection {
        icon: "volume_up"
        shape: MaterialShape.Shape.Circle
        title: Translation.tr("Audio")
        GroupedList {
            ConfigSwitch {
                buttonIcon: "brand_awareness"
                text: Translation.tr("Overamplified sound (up to 150%)")
                checked: Config.options.audio.overamplify
                onCheckedChanged: {
                    if (checked === Config.options.audio.overamplify) return;
                    Config.options.audio.overamplify = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "hearing"
                text: Translation.tr("Earbang protection")
                checked: Config.options.audio.protection.enable
                onCheckedChanged: {
                    Config.options.audio.protection.enable = checked;
                }
            }
            ConfigRow {
                enabled: Config.options.audio.protection.enable
                ConfigSpinBox {
                    icon: "arrow_warm_up"
                    text: Translation.tr("Max allowed increase")
                    value: Config.options.audio.protection.maxAllowedIncrease
                    from: 0
                    to: 100
                    stepSize: 2
                    onValueChanged: {
                        Config.options.audio.protection.maxAllowedIncrease = value;
                    }
                }
                ConfigSpinBox {
                    icon: "vertical_align_top"
                    text: Translation.tr("Volume limit")
                    value: Config.options.audio.protection.maxAllowed
                    from: 0
                    to: 154 // pavucontrol allows up to 153%
                    stepSize: 2
                    onValueChanged: {
                        Config.options.audio.protection.maxAllowed = value;
                    }
                }
            }
        }
    }
}
