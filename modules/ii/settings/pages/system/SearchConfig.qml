import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true
    bottomContentPadding: 15

    function toggleLocation(path, enabled) {
        let locs = (Config.options.search.searchLocations ?? []).slice();
        if (enabled) {
            if (!locs.includes(path))
                locs.push(path);
        } else {
            locs = locs.filter(l => l !== path);
        }
        Config.options.search.searchLocations = locs;
    }

    ContentSection {
        icon: "search"
        shape: MaterialShape.Shape.Cookie6Sided
        title: Translation.tr("Search")

        ContentSubsection {
            title: Translation.tr("Search Providers")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "folder"
                    text: Translation.tr("Files")
                    checked: Config.options.search.providers?.files ?? true
                    onCheckedChanged: {
                        Config.options.search.providers.files = checked;
                    }
                }

                ConfigSwitch {
                    buttonIcon: "calculate"
                    text: Translation.tr("Calculator")
                    checked: Config.options.search.providers?.calculator ?? true
                    onCheckedChanged: {
                        Config.options.search.providers.calculator = checked;
                    }
                }

                ConfigSwitch {
                    buttonIcon: "settings"
                    text: Translation.tr("Settings")
                    checked: Config.options.search.providers?.settings ?? true
                    onCheckedChanged: {
                        Config.options.search.providers.settings = checked;
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Search Locations")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "home"
                    text: Translation.tr("Home Directory (~)")
                    checked: (Config.options.search.searchLocations ?? []).includes("~")
                    onCheckedChanged: page.toggleLocation("~", checked)
                }

                ConfigSwitch {
                    buttonIcon: "description"
                    text: Translation.tr("Documents")
                    checked: (Config.options.search.searchLocations ?? []).includes("~/Documents")
                    onCheckedChanged: page.toggleLocation("~/Documents", checked)
                }

                ConfigSwitch {
                    buttonIcon: "download"
                    text: Translation.tr("Downloads")
                    checked: (Config.options.search.searchLocations ?? []).includes("~/Downloads")
                    onCheckedChanged: page.toggleLocation("~/Downloads", checked)
                }

                ConfigSwitch {
                    buttonIcon: "image"
                    text: Translation.tr("Pictures")
                    checked: (Config.options.search.searchLocations ?? []).includes("~/Pictures")
                    onCheckedChanged: page.toggleLocation("~/Pictures", checked)
                }

                ConfigSwitch {
                    buttonIcon: "movie"
                    text: Translation.tr("Videos")
                    checked: (Config.options.search.searchLocations ?? []).includes("~/Videos")
                    onCheckedChanged: page.toggleLocation("~/Videos", checked)
                }

                ConfigSwitch {
                    buttonIcon: "folder_special"
                    text: Translation.tr("Projects")
                    checked: (Config.options.search.searchLocations ?? []).includes("~/Projects")
                    onCheckedChanged: page.toggleLocation("~/Projects", checked)
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Matching")

            GroupedList {
                ConfigSwitch {
                    text: Translation.tr("Use Levenshtein distance-based algorithm instead of fuzzy")
                    checked: Config.options.search.sloppy
                    onCheckedChanged: {
                        Config.options.search.sloppy = checked;
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "screenshot_region"
        shape: MaterialShape.Shape.PuffyDiamond
        title: Translation.tr("Region Selector & Google Lens")

        ContentSubsection {
            title: Translation.tr("Google Lens")

            GroupedList {
                ConfigSelectionArray {
                    text: Translation.tr("Selection Type")
                    icon: "ink_selection"
                    currentValue: Config.options.search.imageSearch.useCircleSelection ? "circle" : "rectangles"
                    onSelected: newValue => {
                        Config.options.search.imageSearch.useCircleSelection = (newValue === "circle");
                    }
                    options: [
                        { icon: "activity_zone", value: "rectangles", displayName: Translation.tr("Rectangular selection") },
                        { icon: "gesture", value: "circle", displayName: Translation.tr("Circle to Search") }
                    ]
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Hint target regions")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "nearby"
                    text: Translation.tr("Content")
                    checked: Config.options.regionSelector.targetRegions.content
                    onCheckedChanged: {
                        Config.options.regionSelector.targetRegions.content = checked;
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Rectangular selection")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "point_scan"
                    text: Translation.tr("Show aim lines")
                    checked: Config.options.regionSelector.rect.showAimLines
                    onCheckedChanged: {
                        Config.options.regionSelector.rect.showAimLines = checked;
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Circle selection")

            GroupedList {
                ConfigSpinBox {
                    icon: "eraser_size_3"
                    text: Translation.tr("Stroke width")
                    value: Config.options.regionSelector.circle.strokeWidth
                    from: 1
                    to: 20
                    stepSize: 1
                    onValueChanged: {
                        Config.options.regionSelector.circle.strokeWidth = value;
                    }
                }

                ConfigSpinBox {
                    icon: "screenshot_frame_2"
                    text: Translation.tr("Padding")
                    value: Config.options.regionSelector.circle.padding
                    from: 0
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.options.regionSelector.circle.padding = value;
                    }
                }
            }
        }
    }
}
