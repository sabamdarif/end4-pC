import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    implicitHeight: Appearance.sizes.barHeight
    width: parent.width
    readonly property real barPadding: 0
    readonly property bool isMaterial: Config.options.bar.cornerStyle === 3 || Config.options.bar.cornerStyle === 4
    readonly property bool isMaterialHug: Config.options.bar.cornerStyle === 4
    readonly property color materialPillBgColor: Appearance.colors.colLayer0
    readonly property real compositorGapsOut: NiriConfig.options.layout.gaps
    readonly property real centerPillX: centerPill.x
    readonly property real centerPillWidth: centerPill.width

    readonly property bool trayHasItems: SystemTray.items.values.length > 0

    function filterLayout(layout) {
        let result = layout
        if (!trayHasItems) result = result.filter(name => name !== "sysTray")
        if (!Privacy.active) result = result.filter(name => name !== "privacyIndicator")
        if (!LiveWallpaper.available) result = result.filter(name => name !== "liveWallpaper")
        return result
    }

    readonly property var effectiveLeftLayout:   filterLayout(Config.options.bar.layouts.leftLayout)
    readonly property var effectiveMiddleLayout: filterLayout(Config.options.bar.layouts.middleLayout)
    readonly property var effectiveRightLayout:  filterLayout(Config.options.bar.layouts.rightLayout)

    function getWidgetUrl(name) {
        if (!name) return "";
        let formattedName = name.charAt(0).toUpperCase() + name.slice(1);
        return Qt.resolvedUrl("./" + formattedName + ".qml");
    }

    function getMirroredForIndex(layout, idx) {
        const prevCount = layout.slice(0, idx).filter(w => w === "visualizer").length
        return prevCount % 2 === 1
    }

    function shouldPaintMaterialPill(name) {
        if (!root.isMaterial) return false;
        const blacklist = ["workspaces", "divisor", "powerButton", "docktoPanel", "activeWindow"];
        if (blacklist.includes(name)) {
            return false;
        }
        return true;
    }

    function getMaterialPillColor(name) {
        if (!root.isMaterial) return Appearance.colors.colPrimaryContainer;
        switch(name) {
            case "media":
            case "sysTray":
                return Appearance.colors.colSecondaryContainer;
            case "resources":
                return Appearance.colors.colTertiaryContainer;
            case "privacyIndicator":
                return Appearance.colors.colErrorContainer;
            case "systemIcons":
                return Appearance.colors.colPrimary; 
            default:
                return Appearance.colors.colPrimaryContainer;
        }
    }

    property var screen: root.QsWindow.window?.screen
    property real useShortenedForm: (Appearance.sizes.barHellaShortenScreenWidthThreshold >= screen?.width) ? 2 : (Appearance.sizes.barShortenScreenWidthThreshold >= screen?.width) ? 1 : 0


    Rectangle {
        id: barBackground
        anchors.fill: parent
        anchors.margins: Config.options.bar.cornerStyle === 1 ? Appearance.sizes.windowGapsOut : 0
        color: (!centerOnly && Config.options.bar.showBackground && Config.options.bar.cornerStyle !== 2 && !root.isMaterial) 
            ? Appearance.colors.colLayer0 : "transparent"
        radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding : 0
        border.width: (!centerOnly && Config.options.bar.cornerStyle === 1) ? 1 : 0
        border.color: Appearance.colors.colLayer0Border
    }

    // center-only
    readonly property bool centerOnly: !root.isMaterial
        && root.effectiveLeftLayout.length === 0
        && root.effectiveRightLayout.length === 0

    Rectangle {
        id: centerPill
        visible: centerOnly && Config.options.bar.showBackground && Config.options.bar.cornerStyle !== 2
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        width: middleRow.implicitWidth + 10
        height: parent.height - (Config.options.bar.cornerStyle === 1 ? Appearance.sizes.windowGapsOut * 2 : 0)
        color: Appearance.colors.colLayer0
        radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding : 0
        border.width: Config.options.bar.cornerStyle === 1 ? 1 : 0
        border.color: Appearance.colors.colLayer0Border

        bottomLeftRadius:  Config.options.bar.cornerStyle === 0 && !Config.options.bar.bottom ? Appearance.rounding.screenRounding : radius
        bottomRightRadius: Config.options.bar.cornerStyle === 0 && !Config.options.bar.bottom ? Appearance.rounding.screenRounding : radius
        topLeftRadius:     Config.options.bar.cornerStyle === 0 && Config.options.bar.bottom  ? Appearance.rounding.screenRounding : radius
        topRightRadius:    Config.options.bar.cornerStyle === 0 && Config.options.bar.bottom  ? Appearance.rounding.screenRounding : radius
    }

    Item {
        id: contentContainer
        anchors.fill: barBackground
        anchors.margins: root.barPadding

        // Left
        Item {
            anchors.left: parent.left
            anchors.leftMargin: root.isMaterialHug ? 0 : (root.isMaterial ? root.compositorGapsOut : (Config.options.bar.cornerStyle === 1 ? 4 : 10))
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.isMaterial ? (leftMaterialPill.implicitWidth + (root.isMaterialHug && root.effectiveLeftLayout.length > 0 ? leftRightOutwardCorner.implicitSize : 0)) : leftRow.implicitWidth

            // Material pill wrapper
            Rectangle {
                id: leftMaterialPill
                visible: root.isMaterial && root.effectiveLeftLayout.length > 0
                anchors.left: root.isMaterialHug ? parent.left : undefined
                anchors.top: (root.isMaterialHug && !Config.options.bar.bottom) ? parent.top : undefined
                anchors.bottom: (root.isMaterialHug && Config.options.bar.bottom) ? parent.bottom : undefined
                anchors.centerIn: root.isMaterialHug ? undefined : parent
                implicitWidth: leftMaterialRow.implicitWidth + (root.isMaterialHug ? 16 : 10)
                implicitHeight: root.isMaterialHug ? parent.height : leftMaterialRow.implicitHeight
                radius: root.isMaterialHug ? 0 : Appearance.rounding.full
                color: root.materialPillBgColor

                topLeftRadius: root.isMaterialHug ? 0 : radius
                bottomLeftRadius: root.isMaterialHug ? 0 : radius
                topRightRadius: (root.isMaterialHug && Config.options.bar.bottom) ? Appearance.rounding.screenRounding : (root.isMaterialHug ? 0 : radius)
                bottomRightRadius: (root.isMaterialHug && !Config.options.bar.bottom) ? Appearance.rounding.screenRounding : (root.isMaterialHug ? 0 : radius)

                RowLayout {
                    id: leftMaterialRow
                    anchors.centerIn: parent
                    spacing: 3

                    Repeater {
                        model: root.effectiveLeftLayout
                        delegate: leftMaterialGroupDelegate
                    }

                    Component {
                        id: leftMaterialGroupDelegate
                        BarGroup {
                            Layout.fillHeight: true
                            currentIndex: index
                            totalCount: root.effectiveLeftLayout.length
                            paintMaterialPill: root.shouldPaintMaterialPill(modelData)
                            bgColor: root.getMaterialPillColor(modelData)
                            Loader {
                                Layout.fillHeight: true
                                asynchronous: true
                                source: root.getWidgetUrl(modelData)
                                onLoaded: {
                                    if (item && item.hasOwnProperty("mirrored"))
                                        item.mirrored = root.getMirroredForIndex(root.effectiveLeftLayout, index)
                                }
                            }
                        }
                    }
                }
            }

            RoundCorner {
                id: leftRightOutwardCorner
                visible: root.isMaterialHug && root.effectiveLeftLayout.length > 0
                anchors.left: leftMaterialPill.right
                anchors.top: !Config.options.bar.bottom ? parent.top : undefined
                anchors.bottom: Config.options.bar.bottom ? parent.bottom : undefined
                implicitSize: Appearance.rounding.screenRounding
                color: root.materialPillBgColor
                corner: !Config.options.bar.bottom ? RoundCorner.CornerEnum.TopLeft : RoundCorner.CornerEnum.BottomLeft
            }

            // Non-material layout
            RowLayout {
                id: leftRow
                visible: !root.isMaterial
                anchors.fill: parent
                spacing: Config.options.bar.borderless === "transparent" ? -7 : 2

                Repeater {
                    model: root.effectiveLeftLayout
                    delegate: leftBarGroupDelegate
                }

                Component {
                    id: leftBarGroupDelegate
                    BarGroup {
                        Layout.fillHeight: true
                        currentIndex: index
                        totalCount: root.effectiveLeftLayout.length
                        Loader {
                            Layout.fillHeight: true
                            asynchronous: true
                            source: root.getWidgetUrl(modelData)
                            onLoaded: {
                                if (item && item.hasOwnProperty("mirrored"))
                                    item.mirrored = root.getMirroredForIndex(root.effectiveLeftLayout, index)
                            }
                        }
                    }
                }

                Component {
                    id: leftNoGroupDelegate
                    Loader {
                        Layout.fillHeight: false
                        Layout.topMargin: Config.options.bar.bottom ? -5 : 3
                        Layout.alignment: Qt.AlignVCenter
                        asynchronous: true
                        source: root.getWidgetUrl(modelData)
                        onLoaded: {
                            if (item && item.hasOwnProperty("mirrored"))
                                item.mirrored = root.getMirroredForIndex(root.effectiveLeftLayout, index)
                        }
                    }
                }
            }
        }

        // Center
        Item {
            id: absoluteCenter
            anchors.centerIn: parent
            width: root.isMaterial ? (centerMaterialPill.implicitWidth + (root.isMaterialHug && root.effectiveMiddleLayout.length > 0 ? (centerLeftOutwardCorner.implicitSize + centerRightOutwardCorner.implicitSize) : 0)) : middleRow.implicitWidth
            height: parent.height

            RoundCorner {
                id: centerLeftOutwardCorner
                visible: root.isMaterialHug && root.effectiveMiddleLayout.length > 0
                anchors.right: centerMaterialPill.left
                anchors.top: !Config.options.bar.bottom ? parent.top : undefined
                anchors.bottom: Config.options.bar.bottom ? parent.bottom : undefined
                implicitSize: Appearance.rounding.screenRounding
                color: root.materialPillBgColor
                corner: !Config.options.bar.bottom ? RoundCorner.CornerEnum.TopRight : RoundCorner.CornerEnum.BottomRight
            }

            // Material pill wrapper
            Rectangle {
                id: centerMaterialPill
                visible: root.isMaterial && root.effectiveMiddleLayout.length > 0
                anchors.centerIn: parent
                implicitWidth: centerMaterialRow.implicitWidth + (root.isMaterialHug ? 16 : 10)
                implicitHeight: root.isMaterialHug ? parent.height : centerMaterialRow.implicitHeight
                radius: root.isMaterialHug ? 0 : Appearance.rounding.full
                color: root.materialPillBgColor

                topLeftRadius: (root.isMaterialHug && Config.options.bar.bottom) ? Appearance.rounding.screenRounding : (root.isMaterialHug ? 0 : radius)
                topRightRadius: (root.isMaterialHug && Config.options.bar.bottom) ? Appearance.rounding.screenRounding : (root.isMaterialHug ? 0 : radius)
                bottomLeftRadius: (root.isMaterialHug && !Config.options.bar.bottom) ? Appearance.rounding.screenRounding : (root.isMaterialHug ? 0 : radius)
                bottomRightRadius: (root.isMaterialHug && !Config.options.bar.bottom) ? Appearance.rounding.screenRounding : (root.isMaterialHug ? 0 : radius)

                RowLayout {
                    id: centerMaterialRow
                    anchors.centerIn: parent
                    spacing: 3

                    Repeater {
                        model: root.effectiveMiddleLayout
                        delegate: middleMaterialGroupDelegate
                    }

                    Component {
                        id: middleMaterialGroupDelegate
                        BarGroup {
                            Layout.fillHeight: true
                            currentIndex: index
                            totalCount: root.effectiveMiddleLayout.length
                            paintMaterialPill: root.shouldPaintMaterialPill(modelData)
                            bgColor: root.getMaterialPillColor(modelData)
                            Loader {
                                Layout.fillHeight: true
                                asynchronous: true
                                source: root.getWidgetUrl(modelData)
                                onLoaded: {
                                    if (item && item.hasOwnProperty("mirrored"))
                                        item.mirrored = root.getMirroredForIndex(root.effectiveMiddleLayout, index)
                                }
                            }
                        }
                    }
                }
            }

            RoundCorner {
                id: centerRightOutwardCorner
                visible: root.isMaterialHug && root.effectiveMiddleLayout.length > 0
                anchors.left: centerMaterialPill.right
                anchors.top: !Config.options.bar.bottom ? parent.top : undefined
                anchors.bottom: Config.options.bar.bottom ? parent.bottom : undefined
                implicitSize: Appearance.rounding.screenRounding
                color: root.materialPillBgColor
                corner: !Config.options.bar.bottom ? RoundCorner.CornerEnum.TopLeft : RoundCorner.CornerEnum.BottomLeft
            }

            // Non-material layout
            RowLayout {
                id: middleRow
                visible: !root.isMaterial
                anchors.fill: parent
                spacing: Config.options.bar.borderless === "transparent" ? -7 : 2

                Repeater {
                    model: root.effectiveMiddleLayout
                    delegate: middleBarGroupDelegate
                }

                Component {
                    id: middleBarGroupDelegate
                    BarGroup {
                        Layout.fillHeight: true
                        currentIndex: index
                        totalCount: root.effectiveMiddleLayout.length
                        Loader {
                            Layout.fillHeight: true
                            asynchronous: true
                            source: root.getWidgetUrl(modelData)
                            onLoaded: {
                                if (item && item.hasOwnProperty("mirrored"))
                                    item.mirrored = root.getMirroredForIndex(root.effectiveMiddleLayout, index)
                            }
                        }
                    }
                }

                Component {
                    id: middleNoGroupDelegate
                    Loader {
                        Layout.fillHeight: false
                        Layout.topMargin: Config.options.bar.bottom ? -5 : 3
                        asynchronous: true
                        source: root.getWidgetUrl(modelData)
                        onLoaded: {
                            if (item && item.hasOwnProperty("mirrored"))
                                item.mirrored = root.getMirroredForIndex(root.effectiveMiddleLayout, index)
                        }
                    }
                }
            }
        }

        // Right
        Item {
            anchors.right: parent.right
            anchors.rightMargin: root.isMaterialHug ? 0 : (root.isMaterial ? root.compositorGapsOut : (Config.options.bar.cornerStyle === 1 ? 4 : 10))
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.isMaterial ? (rightMaterialPill.implicitWidth + (root.isMaterialHug && root.effectiveRightLayout.length > 0 ? rightLeftOutwardCorner.implicitSize : 0)) : rightRow.implicitWidth

            RoundCorner {
                id: rightLeftOutwardCorner
                visible: root.isMaterialHug && root.effectiveRightLayout.length > 0
                anchors.right: rightMaterialPill.left
                anchors.top: !Config.options.bar.bottom ? parent.top : undefined
                anchors.bottom: Config.options.bar.bottom ? parent.bottom : undefined
                implicitSize: Appearance.rounding.screenRounding
                color: root.materialPillBgColor
                corner: !Config.options.bar.bottom ? RoundCorner.CornerEnum.TopRight : RoundCorner.CornerEnum.BottomRight
            }

            // Material pill wrapper
            Rectangle {
                id: rightMaterialPill
                visible: root.isMaterial && root.effectiveRightLayout.length > 0
                anchors.right: root.isMaterialHug ? parent.right : undefined
                anchors.top: (root.isMaterialHug && !Config.options.bar.bottom) ? parent.top : undefined
                anchors.bottom: (root.isMaterialHug && Config.options.bar.bottom) ? parent.bottom : undefined
                anchors.centerIn: root.isMaterialHug ? undefined : parent
                implicitWidth: rightMaterialRow.implicitWidth + (root.isMaterialHug ? 16 : 10)
                implicitHeight: root.isMaterialHug ? parent.height : rightMaterialRow.implicitHeight
                radius: root.isMaterialHug ? 0 : Appearance.rounding.full
                color: root.materialPillBgColor

                topRightRadius: root.isMaterialHug ? 0 : radius
                bottomRightRadius: root.isMaterialHug ? 0 : radius
                topLeftRadius: (root.isMaterialHug && Config.options.bar.bottom) ? Appearance.rounding.screenRounding : (root.isMaterialHug ? 0 : radius)
                bottomLeftRadius: (root.isMaterialHug && !Config.options.bar.bottom) ? Appearance.rounding.screenRounding : (root.isMaterialHug ? 0 : radius)

                RowLayout {
                    id: rightMaterialRow
                    anchors.centerIn: parent
                    spacing: 3

                    Repeater {
                        model: root.effectiveRightLayout
                        delegate: rightMaterialGroupDelegate
                    }

                    Component {
                        id: rightMaterialGroupDelegate
                        BarGroup {
                            Layout.fillHeight: true
                            currentIndex: index
                            totalCount: root.effectiveRightLayout.length
                            paintMaterialPill: root.shouldPaintMaterialPill(modelData)
                            bgColor: root.getMaterialPillColor(modelData)
                            Loader {
                                Layout.fillHeight: true
                                asynchronous: true
                                source: root.getWidgetUrl(modelData)
                                onLoaded: {
                                    if (item && item.hasOwnProperty("mirrored"))
                                        item.mirrored = root.getMirroredForIndex(root.effectiveRightLayout, index)
                                }
                            }
                        }
                    }
                }
            }

            // Non-material layout
            RowLayout {
                id: rightRow
                visible: !root.isMaterial
                anchors.fill: parent
                spacing: Config.options.bar.borderless === "transparent" ? -7 : 2

                Repeater {
                    model: root.effectiveRightLayout
                    delegate: rightBarGroupDelegate
                }

                Component {
                    id: rightBarGroupDelegate
                    BarGroup {
                        Layout.fillHeight: true
                        currentIndex: index
                        totalCount: root.effectiveRightLayout.length
                        Loader {
                            Layout.fillHeight: true
                            asynchronous: true
                            source: root.getWidgetUrl(modelData)
                            onLoaded: {
                                if (item && item.hasOwnProperty("mirrored"))
                                    item.mirrored = root.getMirroredForIndex(root.effectiveRightLayout, index)
                            }
                        }
                    }
                }

                Component {
                    id: rightNoGroupDelegate
                    Loader {
                        Layout.fillHeight: false
                        Layout.topMargin: Config.options.bar.bottom ? -5 : 3
                        asynchronous: true
                        source: root.getWidgetUrl(modelData)
                        onLoaded: {
                            if (item && item.hasOwnProperty("mirrored"))
                                item.mirrored = root.getMirroredForIndex(root.effectiveRightLayout, index)
                        }
                    }
                }
            }
        }
    }
}