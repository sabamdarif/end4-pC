import os
from pathlib import Path
import shutil
import re
import subprocess
import tempfile
import unittest


REPOSITORY = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("qs"), "Quickshell is required")
class FeatureComponentTests(unittest.TestCase):
    def load_components(self, paths):
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
            loaders = "\n".join(f'Loader {{ source: "{path}"; onLoaded: console.log("LOADED", source) }}' for path in paths)
            (root / "shell.qml").write_text('''import QtQuick
import QtQuick.Controls
import QtQuick.Window
import Quickshell
ShellRoot {
    Window {
        visible: true
        width: 980
        height: 800
''' + loaders + '''
    }
    Timer { interval: 1200; running: true; onTriggered: Qt.quit() }
}
''')
            result = subprocess.run(["qs", "-p", str(root)], capture_output=True, text=True,
                                    timeout=10, env=dict(os.environ, QT_QPA_PLATFORM="offscreen",
                                    XDG_CONFIG_HOME=str(config), XDG_CACHE_HOME=str(root / "cache"),
                                    NIRI_SOCKET=""))
            output = re.sub(r"\x1b\[[0-9;]*m", "", result.stdout + result.stderr)
            output = "\n".join(line for line in output.splitlines() if "@modules/common/widgets/GroupedList.qml" not in line)
            self.assertEqual(result.returncode, 0, output)
            self.assertEqual(output.count("qml: LOADED"), len(paths), output)
            for error in ("TypeError", "ReferenceError", "Cannot assign", "is not a type", "is unavailable"):
                self.assertNotIn(error, output)

    def test_wifi_sharing_components_load(self):
        self.load_components(["modules/ii/settings/pages/network/WifiQrDialog.qml",
                              "modules/ii/settings/pages/network/WifiConfig.qml",
                              "modules/ii/settings/pages/network/WifiProfileEditor.qml"])

    def test_window_rule_components_load(self):
        self.load_components(["modules/ii/settings/pages/compositor/WindowRuleEditorDialog.qml",
                              "modules/ii/settings/pages/compositor/WindowRulesConfig.qml"])
