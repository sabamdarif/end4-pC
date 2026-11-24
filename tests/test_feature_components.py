import os
from pathlib import Path
import shutil
import re
import subprocess
import tempfile
import unittest
import datetime
import json


REPOSITORY = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("qs"), "Quickshell is required")
class FeatureComponentTests(unittest.TestCase):
    def load_components(self, paths, interaction=""):
        with tempfile.TemporaryDirectory(prefix="feature-qml-") as directory:
            root = Path(directory)
            for name in ("modules", "scripts", "assets", "translations", "GlobalStates.qml"):
                (root / name).symlink_to(REPOSITORY / name)
            services = root / "services"
            services.mkdir()
            for service in (REPOSITORY / "services").iterdir():
                if service.name != "Idle.qml":
                    (services / service.name).symlink_to(service)
            (services / "Idle.qml").write_text("pragma Singleton\nimport Quickshell\nSingleton {}\n")
            config = root / "config"
            (config / "qssettings").mkdir(parents=True)
            (config / "niri/qssettings").mkdir(parents=True)
            (config / "qssettings/config.json").write_text(json.dumps({"wellbeing": {"enable": False}}))
            (config / "qssettings/screentime.json").write_text(json.dumps({"version": 1, "days": [
                {"date": datetime.date.today().isoformat(), "active": 3600, "apps": {"kitty": 3600}}]}))
            if "modules/ii/bar/RemovableDrivePopup.qml" in paths:
                # Offscreen Qt has no layer-window backend; keep the real popup contents.
                popup = (REPOSITORY / "modules/ii/bar/RemovableDrivePopup.qml").read_text().replace("StyledPopup {", """Item {
    property bool active: false
    property bool dismissOnOutsideClick
    signal dismissRequested()
    property QtObject contentComponent: QtObject {
        function createObject(parent) {
            const content = root.children[0];
            content.parent = parent;
            return content;
        }
    }
""", 1)
                (root / "RemovableDrivePopupFixture.qml").write_text(popup)
                paths = ["RemovableDrivePopupFixture.qml" if path.endswith("RemovableDrivePopup.qml") else path for path in paths]
            loaders = "\n".join('Loader { id: loader' + str(index) + '; '
                + ('width: item ? item.implicitWidth : 0; height: item ? item.implicitHeight : 0;' if path.endswith("ScreenTimeWidget.qml") else 'anchors.fill: parent;')
                + ' Component.onCompleted: setSource("' + path + '", '
                + ('{screenWidth: 1920, screenHeight: 1080, scaledScreenWidth: 1920, scaledScreenHeight: 1080, wallpaperScale: 1, x: 0, y: 0}'
                   if path.endswith("ScreenTimeWidget.qml") else '{}')
                + '); onLoaded: { console.log("LOADED", source); '
                + ('item.show = true;' if path.endswith("Dialog.qml") and "sidebarRight" in path else '') + '} }' for index, path in enumerate(paths))
            (root / "shell.qml").write_text('''import QtQuick
import QtQuick.Controls
import QtQuick.Window
import Quickshell
import qs.modules.ii.sidebarRight.drives
import qs.modules.ii.sidebarRight.screentime
import qs.modules.ii.background.widgets
import qs.services
import qs.modules.common
import qs
ShellRoot {
    Window {
        id: fixtureWindow
        visible: true
        width: 980
        height: 800
''' + loaders + interaction + '''
    }
    Timer { interval: 1200; running: true; onTriggered: Qt.quit() }
}
''')
            result = subprocess.run(["qs", "-p", str(root)], capture_output=True, text=True,
                                    timeout=10, env=dict(os.environ, QT_QPA_PLATFORM="offscreen",
                                    XDG_CONFIG_HOME=str(config), XDG_CACHE_HOME=str(root / "cache"),
                                    XDG_STATE_HOME=str(root / "state"),
                                    NIRI_SOCKET=""))
            output = re.sub(r"\x1b\[[0-9;]*m", "", result.stdout + result.stderr)
            output = "\n".join(line for line in output.splitlines() if "@modules/common/widgets/GroupedList.qml" not in line)
            self.assertEqual(result.returncode, 0, output)
            self.assertEqual(output.count("qml: LOADED"), len(paths), output)
            for error in ("ASSERTION_FAILED", "TypeError", "ReferenceError", "Cannot assign", "is not a type", "is unavailable"):
                self.assertNotIn(error, output)

    def test_wifi_sharing_components_load(self):
        self.load_components(["modules/ii/settings/pages/network/WifiQrDialog.qml",
                              "modules/ii/settings/pages/network/WifiConfig.qml",
                              "modules/ii/settings/pages/network/WifiProfileEditor.qml"])

    def test_window_rule_components_load(self):
        self.load_components(["modules/ii/settings/pages/compositor/WindowRuleEditorDialog.qml",
                              "modules/ii/settings/pages/compositor/WindowRulesConfig.qml"])

    def test_storage_components_load(self):
        self.load_components(["modules/ii/sidebarRight/drives/DrivesDialog.qml"])

    def test_wellbeing_components_load_with_usage(self):
        self.load_components(["modules/ii/sidebarRight/screentime/ScreenTimeDialog.qml",
                              "modules/ii/settings/pages/system/WellbeingConfig.qml",
                              "modules/ii/background/widgets/screentime/ScreenTimeWidget.qml"])

    def test_wellbeing_navigation_and_limit_changes(self):
        self.load_components(["modules/ii/sidebarRight/screentime/AppLimitSheet.qml",
                              "modules/ii/sidebarRight/screentime/WeeklyChart.qml",
                              "modules/ii/sidebarRight/screentime/AppUsageList.qml"], '''
        function check(condition, message) { if (!condition) console.error("ASSERTION_FAILED", message); }
        Timer {
            interval: 400; running: true
            onTriggered: {
                fixtureWindow.check(Config.ready, "settings are ready before changes");
                loader0.item.presentFor("kitty");
                loader0.item.setLimit(75);
                fixtureWindow.check(ScreenTime.appLimits.kitty === 75, "app duration saves");
                loader0.item.presentFor("kitty");
                loader0.item.setLimit(0);
                fixtureWindow.check(!("kitty" in ScreenTime.appLimits), "zero duration removes the limit");
                loader0.item.presentFor("");
                loader0.item.setLimit(120);
                fixtureWindow.check(Config.options.wellbeing.dailyLimit === 120, "global duration saves separately");
                loader1.item.selectedDate = ScreenTime.todayKey;
                loader1.item.weekOffset = -1;
                fixtureWindow.check(loader1.item.selectedDate === "", "week navigation clears day selection");
                fixtureWindow.check(loader1.item.week.length === 7, "previous week remains complete");
                loader2.item.days = ScreenTime.days;
                fixtureWindow.check(loader2.item.apps[0].appId === "kitty", "usage list receives the tracked application");
            }
        }
''')

    def test_desktop_wellbeing_is_interactive_without_opening_quick_settings(self):
        self.load_components(["modules/ii/background/widgets/screentime/ScreenTimeWidget.qml"], '''
        function check(condition, message) { if (!condition) console.error("ASSERTION_FAILED", message); }
        function descendants(node, found, visited) {
            if (visited.has(node)) return;
            visited.add(node);
            found.push(node);
            for (const child of [...(node.children || []), ...(node.data || [])]) descendants(child, found, visited);
        }
        Timer {
            interval: 400; running: true
            onTriggered: {
                const nodes = [];
                fixtureWindow.descendants(loader0.item, nodes, new Set());
                const tips = nodes.filter(node => "extraVisibleCondition" in node);
                fixtureWindow.check(tips.length >= 7, "chart tooltips are instantiated");
                fixtureWindow.check(tips.every(tip => !tip.visible), "tooltips stay hidden while the chart is not hovered");
                const content = nodes.find(node => "desktop" in node && "period" in node);
                fixtureWindow.check(!!content, "desktop hosts the shared detailed wellbeing content");
                const limits = nodes.find(node => "presentFor" in node);
                limits.presentFor("kitty");
                fixtureWindow.check(GlobalStates.desktopWidgetKeyboardFocus, "desktop limit editor requests keyboard focus");
                limits.setLimit(45);
                fixtureWindow.check(ScreenTime.appLimits.kitty === 45, "desktop app limit is editable");
                fixtureWindow.check(!GlobalStates.desktopWidgetKeyboardFocus, "closing the editor releases keyboard focus");
                GlobalStates.sidebarRightOpen = false;
                loader0.item.clicked(null);
                fixtureWindow.check(!GlobalStates.sidebarRightOpen, "clicking the desktop card does not open quick settings");
                fixtureWindow.check(loader0.item.height === 620, "portrait card has room for the full layout");
                const footer = nodes.find(node => node.buttonText === Translation.tr("Daily limit"));
                fixtureWindow.check(footer.mapToItem(loader0.item, 0, 0).y + footer.height <= loader0.item.height,
                    "portrait limit controls fit inside the card");
                Config.options.background.widgets.screentime.sizeMode = "1x4";
                Qt.callLater(() => {
                    fixtureWindow.check(footer.mapToItem(loader0.item, 0, 0).y + footer.height <= loader0.item.height,
                        "wide limit controls fit inside the card too");
                });
            }
        }
''')

    def test_storage_manager_switches_inside_the_popup(self):
        self.load_components(["modules/ii/bar/RemovableDrivePopup.qml"], '''
        function check(condition, message) { if (!condition) console.error("ASSERTION_FAILED", message); }
        function findButton(node, text) {
            if (node.buttonText === text) return node;
            for (const child of node.children || []) {
                const found = fixtureWindow.findButton(child, text);
                if (found) return found;
            }
            return null;
        }
        Timer {
            interval: 400; running: true
            onTriggered: {
                const content = loader0.item.contentComponent.createObject(fixtureWindow.contentItem);
                content.width = Qt.binding(() => content.implicitWidth);
                content.height = Qt.binding(() => content.implicitHeight);
                GlobalStates.sidebarRightOpen = false;
                fixtureWindow.check(content.width === 340, "removable view has a stable width");
                Drives.lastError = "Drive operation failed: " + "x".repeat(200);
                fixtureWindow.check(content.implicitWidth === 340, "long errors cannot stretch the popup");
                const button = fixtureWindow.findButton(content, Translation.tr("Storage manager"));
                fixtureWindow.check(!!button, "popup exposes the storage manager button");
                button.clicked();
                fixtureWindow.check(loader0.item.showStorageManager, "button switches the popup to storage details");
                fixtureWindow.check(content.implicitWidth === 420, "storage view provides more room inside the dropdown");
                fixtureWindow.check(!GlobalStates.sidebarRightOpen, "storage details do not open quick settings");
                button.clicked();
                fixtureWindow.check(!loader0.item.showStorageManager, "back returns to removable devices");
                content.destroy();
            }
        }
''')
