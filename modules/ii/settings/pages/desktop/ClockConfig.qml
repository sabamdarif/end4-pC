import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import Quickshell

ContentPage {
    id: page
    forceWidth: true

    ContentSection {
        id: settingsClock
        icon: "clock_loader_40"
        shape: MaterialShape.Shape.Bun
        title: Translation.tr("Clock")

        function stylePresent(styleName) {
            if (!Config.options.background.widgets.clock.showOnlyWhenLocked && Config.options.background.widgets.clock.style === styleName) {
                return true;
            }
            if (Config.options.background.widgets.clock.styleLocked === styleName) {
                return true;
            }
            return false;
        }

        readonly property bool digitalPresent: stylePresent("digital")
        readonly property bool cookiePresent: stylePresent("cookie")

        GroupedList {
            ConfigSwitch {
                Layout.fillWidth: false
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.background.widgets.clock.enable
                onCheckedChanged: {
                    Config.options.background.widgets.clock.enable = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "lock_clock"
                text: Translation.tr("Show only when locked")
                checked: Config.options.background.widgets.clock.showOnlyWhenLocked
                onCheckedChanged: {
                    Config.options.background.widgets.clock.showOnlyWhenLocked = checked;
                }
            }
            ConfigSelectionArray {
                text: Translation.tr("Placement strategy")
                icon: "move"
                Layout.fillWidth: false
                currentValue: Config.options.background.widgets.clock.placementStrategy
                onSelected: newValue => {
                    Config.options.background.widgets.clock.placementStrategy = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Draggable"),
                        icon: "drag_pan",
                        value: "free"
                    },
                    {
                        displayName: Translation.tr("Least busy"),
                        icon: "category",
                        value: "leastBusy"
                    },
                    {
                        displayName: Translation.tr("Most busy"),
                        icon: "shapes",
                        value: "mostBusy"
                    },
                ]
            }
            ConfigSelectionArray {
                text: Translation.tr("Clock style")
                icon: "nest_clock_farsight_analog"
                currentValue: Config.options.background.widgets.clock.style
                onSelected: newValue => {
                    Config.options.background.widgets.clock.style = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Digital"),
                        icon: "timer_10",
                        value: "digital"
                    },
                    {
                        displayName: Translation.tr("Cookie"),
                        icon: "cookie",
                        value: "cookie"
                    },
                    {
                        displayName: Translation.tr("Pixel"),
                        icon: "grid_view",
                        value: "pixel"
                    }
                ]
            }
            ConfigSelectionArray {
                text: Translation.tr("Clock style (locked)")
                icon: "shield_watch"
                currentValue: Config.options.background.widgets.clock.styleLocked
                onSelected: newValue => {
                    Config.options.background.widgets.clock.styleLocked = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Digital"),
                        icon: "timer_10",
                        value: "digital"
                    },
                    {
                        displayName: Translation.tr("Cookie"),
                        icon: "cookie",
                        value: "cookie"
                    },
                    {
                        displayName: Translation.tr("Pixel"),
                        icon: "grid_view",
                        value: "pixel"
                    }
                ]
            }
        }

        ContentSubsection {
            visible: settingsClock.digitalPresent
            title: Translation.tr("Digital clock settings")

            ConfigRow {
                uniform: true

                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "vertical_distribute"
                        text: Translation.tr("Vertical")
                        checked: Config.options.background.widgets.clock.digital.vertical
                        onCheckedChanged: { Config.options.background.widgets.clock.digital.vertical = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "date_range"
                        text: Translation.tr("Show date")
                        checked: Config.options.background.widgets.clock.digital.showDate
                        onCheckedChanged: { Config.options.background.widgets.clock.digital.showDate = checked }
                    }
                }

                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "animation"
                        text: Translation.tr("Animate time change")
                        checked: Config.options.background.widgets.clock.digital.animateChange
                        onCheckedChanged: { Config.options.background.widgets.clock.digital.animateChange = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "activity_zone"
                        text: Translation.tr("Use adaptive alignment")
                        checked: Config.options.background.widgets.clock.digital.adaptiveAlignment
                        onCheckedChanged: { Config.options.background.widgets.clock.digital.adaptiveAlignment = checked }
                    }
                }
            }

            GroupedList {
                ConfigSwitch {
                    id: autoColorSwitch
                    buttonIcon: "auto_awesome"
                    text: Translation.tr("Automatic colors")
                    checked: Config.options.background.widgets.clock.color === ""
                    onCheckedChanged: {
                        if (checked) {
                            Config.options.background.widgets.clock.color = ""
                        }
                    }
                }

                ColorSelectionArray {
                    icon: "palette"
                    text: Translation.tr("Color")
                    currentValue: Config.options.background.widgets.clock.color
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.color = newValue
                        autoColorSwitch.checked = false
                    }
                }
            }

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Font family")
                text: Config.options.background.widgets.clock.digital.font.family
                wrapMode: TextEdit.Wrap

                Timer {
                    id: debounceTimer
                    interval: 500
                    repeat: false
                    onTriggered: {
                        Config.options.background.widgets.clock.digital.font.family = parent.text
                    }
                }

                onTextChanged: {
                    debounceTimer.restart()
                }
            }
            GroupedList {
                Layout.topMargin: 10
                ConfigSlider {
                    text: Translation.tr("Font weight")
                    value: Config.options.background.widgets.clock.digital.font.weight
                    usePercentTooltip: false
                    buttonIcon: "format_bold"
                    from: 1
                    to: 1000
                    stopIndicatorValues: [350]
                    onValueChanged: {
                        Config.options.background.widgets.clock.digital.font.weight = value;
                    }
                }

                ConfigSlider {
                    text: Translation.tr("Font size")
                    value: Config.options.background.widgets.clock.digital.font.size
                    usePercentTooltip: false
                    buttonIcon: "format_size"
                    from: 50
                    to: 700
                    stopIndicatorValues: [90]
                    onValueChanged: {
                        Config.options.background.widgets.clock.digital.font.size = value;
                    }
                }

                ConfigSlider {
                    text: Translation.tr("Font width")
                    value: Config.options.background.widgets.clock.digital.font.width
                    usePercentTooltip: false
                    buttonIcon: "fit_width"
                    from: 25
                    to: 125
                    stopIndicatorValues: [100]
                    onValueChanged: {
                        Config.options.background.widgets.clock.digital.font.width = value;
                    }
                }
                ConfigSlider {
                    text: Translation.tr("Font roundness")
                    value: Config.options.background.widgets.clock.digital.font.roundness
                    usePercentTooltip: false
                    buttonIcon: "line_curve"
                    from: 0
                    to: 100
                    onValueChanged: {
                        Config.options.background.widgets.clock.digital.font.roundness = value;
                    }
                }
            }
        }

        ContentSubsection {
            visible: settingsClock.cookiePresent
            title: Translation.tr("Cookie clock settings")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "airwave"
                    text: Translation.tr("Use old sine wave cookie implementation")
                    checked: Config.options.background.widgets.clock.cookie.useSineCookie
                    onCheckedChanged: {
                        Config.options.background.widgets.clock.cookie.useSineCookie = checked;
                    }
                }

                ConfigSpinBox {
                    icon: "add_triangle"
                    text: Translation.tr("Sides")
                    value: Config.options.background.widgets.clock.cookie.sides
                    from: 0
                    to: 40
                    stepSize: 1
                    onValueChanged: {
                        Config.options.background.widgets.clock.cookie.sides = value;
                    }
                }

                ConfigSwitch {
                    buttonIcon: "autoplay"
                    text: Translation.tr("Constantly rotate")
                    checked: Config.options.background.widgets.clock.cookie.constantlyRotate
                    onCheckedChanged: {
                        Config.options.background.widgets.clock.cookie.constantlyRotate = checked;
                    }
                }

                ConfigRow {

                    ConfigSwitch {
                        enabled: Config.options.background.widgets.clock.cookie.dialNumberStyle === "dots" || Config.options.background.widgets.clock.cookie.dialNumberStyle === "full"
                        buttonIcon: "brightness_7"
                        text: Translation.tr("Hour marks")
                        checked: Config.options.background.widgets.clock.cookie.hourMarks
                        onEnabledChanged: {
                            checked = Config.options.background.widgets.clock.cookie.hourMarks;
                        }
                        onCheckedChanged: {
                            Config.options.background.widgets.clock.cookie.hourMarks = checked;
                        }
                    }

                    ConfigSwitch {
                        enabled: Config.options.background.widgets.clock.cookie.dialNumberStyle !== "numbers"
                        buttonIcon: "timer_10"
                        text: Translation.tr("Digits in the middle")
                        checked: Config.options.background.widgets.clock.cookie.timeIndicators
                        onEnabledChanged: {
                            checked = Config.options.background.widgets.clock.cookie.timeIndicators;
                        }
                        onCheckedChanged: {
                            Config.options.background.widgets.clock.cookie.timeIndicators = checked;
                        }
                    }
                }
            }
        }

        GroupedList {
            Layout.topMargin: 10
            visible: settingsClock.cookiePresent
            ConfigSelectionArray {
                text: "Dial Style"
                icon: "graph_6"
                currentValue: Config.options.background.widgets.clock.cookie.dialNumberStyle
                onSelected: newValue => {
                    Config.options.background.widgets.clock.cookie.dialNumberStyle = newValue;
                    if (newValue !== "dots" && newValue !== "full") {
                        Config.options.background.widgets.clock.cookie.hourMarks = false;
                    }
                    if (newValue === "numbers") {
                        Config.options.background.widgets.clock.cookie.timeIndicators = false;
                    }
                }
                options: [
                    {
                        displayName: "",
                        icon: "block",
                        value: "none"
                    },
                    {
                        displayName: Translation.tr("Dots"),
                        icon: "graph_6",
                        value: "dots"
                    },
                    {
                        displayName: Translation.tr("Full"),
                        icon: "history_toggle_off",
                        value: "full"
                    },
                    {
                        displayName: Translation.tr("Numbers"),
                        icon: "counter_1",
                        value: "numbers"
                    }
                ]
            }
            ConfigSelectionArray {
                icon: "highlighter_size_2"
                text: Translation.tr("Hour hand")
                currentValue: Config.options.background.widgets.clock.cookie.hourHandStyle
                onSelected: newValue => {
                    Config.options.background.widgets.clock.cookie.hourHandStyle = newValue;
                }
                options: [
                    {
                        displayName: "",
                        icon: "block",
                        value: "hide"
                    },
                    {
                        displayName: Translation.tr("Classic"),
                        icon: "radio",
                        value: "classic"
                    },
                    {
                        displayName: Translation.tr("Hollow"),
                        icon: "circle",
                        value: "hollow"
                    },
                    {
                        displayName: Translation.tr("Fill"),
                        icon: "eraser_size_5",
                        value: "fill"
                    },
                ]
            }
            ConfigSelectionArray {
                text: Translation.tr("Minute hand")
                icon: "eraser_size_1" 
                currentValue: Config.options.background.widgets.clock.cookie.minuteHandStyle
                onSelected: newValue => {
                    Config.options.background.widgets.clock.cookie.minuteHandStyle = newValue;
                }
                options: [
                    {
                        displayName: "",
                        icon: "block",
                        value: "hide"
                    },
                    {
                        displayName: Translation.tr("Classic"),
                        icon: "radio",
                        value: "classic"
                    },
                    {
                        displayName: Translation.tr("Thin"),
                        icon: "line_end",
                        value: "thin"
                    },
                    {
                        displayName: Translation.tr("Medium"),
                        icon: "eraser_size_2",
                        value: "medium"
                    },
                    {
                        displayName: Translation.tr("Bold"),
                        icon: "eraser_size_4",
                        value: "bold"
                    },
                ]
            }
            ConfigSelectionArray {
                text: Translation.tr("Second hand")
                icon: "pen_size_1"
                currentValue: Config.options.background.widgets.clock.cookie.secondHandStyle
                onSelected: newValue => {
                    Config.options.background.widgets.clock.cookie.secondHandStyle = newValue;
                }
                options: [
                    {
                        displayName: "",
                        icon: "block",
                        value: "hide"
                    },
                    {
                        displayName: Translation.tr("Classic"),
                        icon: "radio",
                        value: "classic"
                    },
                    {
                        displayName: Translation.tr("Line"),
                        icon: "line_end",
                        value: "line"
                    },
                    {
                        displayName: Translation.tr("Dot"),
                        icon: "adjust",
                        value: "dot"
                    },
                ]
            }
            ConfigSelectionArray {
                text: Translation.tr("Date style")
                icon: "date_range"
                currentValue: Config.options.background.widgets.clock.cookie.dateStyle
                onSelected: newValue => {
                    Config.options.background.widgets.clock.cookie.dateStyle = newValue;
                }
                options: [
                    {
                        displayName: "",
                        icon: "block",
                        value: "hide"
                    },
                    {
                        displayName: Translation.tr("Bubble"),
                        icon: "bubble_chart",
                        value: "bubble"
                    },
                    {
                        displayName: Translation.tr("Border"),
                        icon: "rotate_right",
                        value: "border"
                    },
                    {
                        displayName: Translation.tr("Rect"),
                        icon: "rectangle",
                        value: "rect"
                    }
                ]
            }
        }

        ContentSubsection {
            visible: Config.options.background.widgets.clock.style === "pixel"
            title: Translation.tr("Pixel Clock Settings")
            GroupedList {
                visible: Config.options.background.widgets.clock.style === "pixel"
                ConfigSelectionArray {
                    text: Translation.tr("Pixel clock orientation")
                    visible: Config.options.background.widgets.clock.style === "pixel"
                    icon: "screen_rotation"
                    currentValue: Config.options.background.widgets.clock.pixel.orientation
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.pixel.orientation = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Horizontal"),
                            icon: "swap_horiz",
                            value: "horizontal"
                        },
                        {
                            displayName: Translation.tr("Vertical"),
                            icon: "swap_vert",
                            value: "vertical"
                        }
                    ]
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Quote")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.background.widgets.clock.quote.enable
                    onCheckedChanged: {
                        Config.options.background.widgets.clock.quote.enable = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "font_download"
                    text: Translation.tr("Follow Clock Font")
                    enabled: Config.options.background.widgets.clock.style !== "pixel"
                    checked: Config.options.background.widgets.clock.quote.followClock
                    onCheckedChanged: {
                        Config.options.background.widgets.clock.quote.followClock = checked;
                    }
                }
                ConfigTextArea {
                    id: quoteField
                    Layout.fillWidth: true
                    fieldWidth: 300
                    buttonIcon: "format_quote"
                    text: Translation.tr("Quote")
                    placeholderText: Translation.tr("Quote")
                    value: Config.options.background.widgets.clock.quote.text
                    onValueChanged: {
                        quoteDebounceTimer.restart();
                    }

                    Timer {
                        id: quoteDebounceTimer
                        interval: 600
                        repeat: false
                        onTriggered: {
                            Config.options.background.widgets.clock.quote.text = quoteField.value;
                        }
                    }
                }
            }
        }
    }
}
