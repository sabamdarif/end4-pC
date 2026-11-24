import shutil
import unittest

from ui_test_utils import qml_block, run_qml


@unittest.skipUnless(shutil.which("qs"), "Quickshell is required")
class SettingsColorsTests(unittest.TestCase):
    def test_theme_controls_fit_wide_and_narrow_layouts(self):
        path = "modules/ii/settings/pages/style/ColorsConfig.qml"
        button = qml_block(path, "    component SmallLightDarkPreferenceButton:", "    ContentSection {")
        layout = qml_block(path, "        GridLayout {", '\n    ContentSection {\n        icon: "colors"')
        layout = layout.rsplit("\n    }", 1)[0]
        fixture = button + layout
        for original, replacement in (("Appearance", "appearance"), ("Config", "config"),
                                      ("Directories", "directories"), ("Translation", "translation")):
            fixture = fixture.replace(original + ".", "root." + replacement + ".")

        run_qml(self, '''
        property QtObject appearance: QtObject {
            property var colors: ({ colPrimary: "tan", colOnPrimary: "black", colOnLayer2: "white",
                colLayer2: "gray", colSecondaryContainer: "gray", colSecondaryContainerHover: "silver",
                colOnSecondaryContainer: "white" })
            property var rounding: ({ large: 24, normal: 16 })
            property var font: ({ pixelSize: { smaller: 12, larger: 18 } })
            property var m3colors: ({ darkmode: true })
        }
        property QtObject config: QtObject {
            property var options: ({ background: { wallpaperPath: "", thumbnailPath: "" },
                appearance: { palette: { type: "scheme-neutral" } } })
        }
        property QtObject directories: QtObject { property string wallpaperSwitchScriptPath: "" }
        property QtObject translation: QtObject { function tr(text) { return text } }
        component RippleButton: Button {
            property bool toggled
            property color colBackground
            property real buttonRadius
            background: Rectangle { implicitHeight: 30 }
        }
        component MaterialSymbol: Item {
            property string text
            property color color
            property real iconSize
            implicitWidth: iconSize
            implicitHeight: iconSize
        }
        component StyledText: Text {}
        component StyledImage: Image {}
        component OpacityMask: Item { property var maskSource }
        component ToolbarPairedFab: Button { property string iconText }
        component StyledToolTip: Item { property string text }
''' + fixture + '''
        Binding { target: themeLayout; property: "width"; value: root.width }
        property var widths: [1250, 800, 799, 600, 320, 238]
        property int step: 0
        property bool checking: false
        Timer {
            interval: 50
            running: true
            repeat: true
            onTriggered: {
                if (!root.checking) {
                    root.width = root.widths[root.step];
                    root.checking = true;
                    return;
                }
                const controls = themeLayout.children[1];
                const modes = controls.children[0];
                root.check(themeLayout.columns === (root.width >= 800 ? 2 : 1), "responsive layout");
                root.check(wallpaperPreview.width <= Math.min(420, root.width), "preview fits viewport");
                root.check(Math.abs(wallpaperPreview.height / wallpaperPreview.width - 2 / 3) < 0.01,
                    "preview keeps aspect ratio");
                root.check(controls.x + controls.width <= root.width + 1, "selector fits viewport");
                root.check(root.width >= 800 ? controls.y === wallpaperPreview.y
                    : controls.y >= wallpaperPreview.y + wallpaperPreview.height, "preview and controls do not overlap");
                for (const button of modes.children) {
                    if (!button.contentItem) continue;
                    root.check(button.height >= button.contentItem.implicitHeight + button.topPadding + button.bottomPadding,
                        "mode button reserves icon and label height");
                    const label = button.contentItem.children[1];
                    root.check(label.mapToItem(button, 0, label.height).y <= button.height, "mode label stays inside button");
                }
                root.check(schemeGrid.columns === (schemeGrid.width >= 360 ? 3 : 2), "responsive scheme columns");
                for (const card of schemeGrid.children) {
                    if (card.isSelected === undefined) continue;
                    root.check(card.height >= 72 && card.height <= 90, "scheme card stays compact");
                    root.check(card.x + card.width <= schemeGrid.width + 1, "scheme card fits grid");
                    const icon = card.children[0];
                    const label = card.children[1];
                    root.check(label.y >= icon.y + icon.height, "scheme icon and label do not overlap");
                    root.check(label.y + label.height <= card.height, "scheme label stays inside card");
                }
                root.checking = false;
                if (++root.step === root.widths.length) {
                    console.log("UI_TEST_DONE");
                    stop();
                }
            }
        }
''')


if __name__ == "__main__":
    unittest.main()
