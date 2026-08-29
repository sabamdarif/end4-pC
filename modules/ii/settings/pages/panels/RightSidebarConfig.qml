import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    ContentSection {
        icon: "splitscreen_right"
        shape: MaterialShape.Shape.Slanted
        title: Translation.tr("Right Sidebar")

        GroupedList {
            ConfigSwitch {
                buttonIcon: "planner_banner_ad_pt"
                text: Translation.tr('Banner')
                checked: Config.options.sidebar.banner
                onCheckedChanged: {
                    Config.options.sidebar.banner = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "music_note"
                text: Translation.tr('Media Player')
                checked: Config.options.sidebar.mediaPlayer
                onCheckedChanged: {
                    Config.options.sidebar.mediaPlayer = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "calendar_month"
                text: Translation.tr('Calendar')
                checked: Config.options.sidebar.calendar
                onCheckedChanged: {
                    Config.options.sidebar.calendar = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "memory"
                text: Translation.tr('Keep right sidebar loaded')
                checked: Config.options.sidebar.keepRightSidebarLoaded
                onCheckedChanged: {
                    Config.options.sidebar.keepRightSidebarLoaded = checked;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Quick toggles")
            GroupedList {
                ConfigSelectionArray {
                    text: Translation.tr("Style")
                    icon: "toggle_on"
                    Layout.fillWidth: false
                    currentValue: Config.options.sidebar.quickToggles.style
                    onSelected: newValue => {
                        Config.options.sidebar.quickToggles.style = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Classic"),
                            icon: "password_2",
                            value: "classic"
                        },
                        {
                            displayName: Translation.tr("Android"),
                            icon: "action_key",
                            value: "android"
                        }
                    ]
                }
                ConfigSpinBox {
                    enabled: Config.options.sidebar.quickToggles.style === "android"
                    icon: "add_column_left"
                    text: Translation.tr("Columns")
                    value: Config.options.sidebar.quickToggles.android.columns
                    from: 1
                    to: 8
                    stepSize: 1
                    onValueChanged: {
                        Config.options.sidebar.quickToggles.android.columns = value;
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Sliders")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.sidebar.quickSliders.enable
                    onCheckedChanged: {
                        Config.options.sidebar.quickSliders.enable = checked;
                    }
                }

                ConfigSwitch {
                    buttonIcon: "brightness_6"
                    text: Translation.tr("Brightness")
                    enabled: Config.options.sidebar.quickSliders.enable
                    checked: Config.options.sidebar.quickSliders.showBrightness
                    onCheckedChanged: {
                        Config.options.sidebar.quickSliders.showBrightness = checked;
                    }
                }

                ConfigSwitch {
                    buttonIcon: "volume_up"
                    text: Translation.tr("Volume")
                    enabled: Config.options.sidebar.quickSliders.enable
                    checked: Config.options.sidebar.quickSliders.showVolume
                    onCheckedChanged: {
                        Config.options.sidebar.quickSliders.showVolume = checked;
                    }
                }

                ConfigSwitch {
                    buttonIcon: "mic"
                    text: Translation.tr("Microphone")
                    enabled: Config.options.sidebar.quickSliders.enable
                    checked: Config.options.sidebar.quickSliders.showMic
                    onCheckedChanged: {
                        Config.options.sidebar.quickSliders.showMic = checked;
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Corner open")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.sidebar.cornerOpen.enable
                    onCheckedChanged: { Config.options.sidebar.cornerOpen.enable = checked }
                }
                ConfigSwitch {
                    buttonIcon: "highlight_mouse_cursor"
                    text: Translation.tr("Hover to trigger")
                    checked: Config.options.sidebar.cornerOpen.clickless
                    onCheckedChanged: { Config.options.sidebar.cornerOpen.clickless = checked }
                }
                ConfigSwitch {
                    buttonIcon: "vertical_align_bottom"
                    text: Translation.tr("Place at bottom")
                    checked: Config.options.sidebar.cornerOpen.bottom
                    onCheckedChanged: { Config.options.sidebar.cornerOpen.bottom = checked }
                }
                ConfigSwitch {
                    buttonIcon: "unfold_more_double"
                    text: Translation.tr("Value scroll")
                    checked: Config.options.sidebar.cornerOpen.valueScroll
                    onCheckedChanged: { Config.options.sidebar.cornerOpen.valueScroll = checked }
                }
                ConfigSwitch {
                    buttonIcon: "visibility"
                    text: Translation.tr("Visualize region")
                    checked: Config.options.sidebar.cornerOpen.visualize
                    onCheckedChanged: { Config.options.sidebar.cornerOpen.visualize = checked }
                }
                ConfigSwitch {
                    enabled: Config.options.sidebar.cornerOpen.clickless
                    buttonIcon: "ads_click"
                    text: Translation.tr("Force hover at absolute corner")
                    checked: Config.options.sidebar.cornerOpen.clicklessCornerEnd
                    onCheckedChanged: { Config.options.sidebar.cornerOpen.clicklessCornerEnd = checked }
                }
                ConfigSpinBox {
                    enabled: Config.options.sidebar.cornerOpen.clickless
                    icon: "arrow_cool_down"
                    text: Translation.tr("Vertical offset")
                    value: Config.options.sidebar.cornerOpen.clicklessCornerVerticalOffset
                    from: 0; to: 20; stepSize: 1
                    onValueChanged: { Config.options.sidebar.cornerOpen.clicklessCornerVerticalOffset = value }
                }
                ConfigSpinBox {
                    icon: "arrow_range"
                    text: Translation.tr("Region width")
                    value: Config.options.sidebar.cornerOpen.cornerRegionWidth
                    from: 1; to: 300; stepSize: 1
                    onValueChanged: { Config.options.sidebar.cornerOpen.cornerRegionWidth = value }
                }
                ConfigSpinBox {
                    icon: "height"
                    text: Translation.tr("Region height")
                    value: Config.options.sidebar.cornerOpen.cornerRegionHeight
                    from: 1; to: 300; stepSize: 1
                    onValueChanged: { Config.options.sidebar.cornerOpen.cornerRegionHeight = value }
                }
            }
        }
    }
}
