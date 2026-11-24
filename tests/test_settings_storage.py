import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPOSITORY = Path(__file__).resolve().parents[1]


class SettingsScriptPathTests(unittest.TestCase):
    def test_readers_respect_xdg_config_home_and_home_fallback(self):
        with tempfile.TemporaryDirectory(prefix="settings-scripts-") as directory:
            home = Path(directory) / "custom home"
            for name in ("switchwall.sh", "applycolor.sh", "random/random_konachan_wall.sh", "random/random_osu_wall.sh"):
                source = (REPOSITORY / "scripts/colors" / name).read_text()
                binding = next(line for line in source.splitlines()
                               if line.startswith(("SHELL_CONFIG_FILE=", "CONFIG_FILE=")))
                variable = binding.split("=", 1)[0]
                script = 'XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"\n' + binding + f'\nprintf "%s" "${variable}"'
                for custom_xdg in (False, True):
                    with self.subTest(script=name, custom_xdg=custom_xdg):
                        env = dict(os.environ, HOME=str(home))
                        env.pop("XDG_CONFIG_HOME", None)
                        if custom_xdg:
                            env["XDG_CONFIG_HOME"] = str(home / "xdg")
                        result = subprocess.run(["bash", "-c", script], env=env, text=True, capture_output=True, check=True)
                        expected = Path(env["XDG_CONFIG_HOME"]) if custom_xdg else home / ".config"
                        self.assertEqual(result.stdout, str(expected / "qssettings/config.json"))


@unittest.skipUnless(shutil.which("qs"), "Quickshell is required")
class SettingsStorageQmlTests(unittest.TestCase):
    def run_storage(self, contents=None):
        with tempfile.TemporaryDirectory(prefix="settings-qml-") as directory:
            root = Path(directory)
            config_home = root / "custom config"
            new = config_home / "qssettings"
            new.mkdir(parents=True)
            if contents is not None:
                (new / "config.json").write_text(contents)
            common = root / "modules/common"
            functions = common / "functions"
            functions.mkdir(parents=True)
            shutil.copy(REPOSITORY / "modules/common/Config.qml", common)
            shutil.copy(REPOSITORY / "modules/common/functions/FileUtils.qml", functions)
            source = (REPOSITORY / "modules/common/Directories.qml").read_text()
            # Cache cleanup must not touch the live shell's /tmp files in this fixture.
            source = "\n".join(line for line in source.splitlines() if "Quickshell.execDetached(" not in line)
            (common / "Directories.qml").write_text(source)
            services = root / "services"
            services.mkdir()
            (services / "SystemInfo.qml").write_text('pragma Singleton\nimport Quickshell\nSingleton { property string username: "test" }\n')
            (root / "shell.qml").write_text('''import QtQuick
import Quickshell
import "modules/common"
ShellRoot {
    function check(condition, message) {
        if (!condition) console.error("ASSERTION_FAILED", message);
    }
    Component.onCompleted: console.log("SETTINGS_INIT", Config.ready)
    Timer {
        interval: 300; running: true
        onTriggered: {
            check(Config.ready, "settings loaded");
            check(Directories.shellConfigPath.endsWith("/qssettings/config.json"), "canonical config location");
            check(Directories.systemSounds.endsWith("/qssettings/sounds"), "sound overrides location");
            check(Directories.userActions.endsWith("/qssettings/actions"), "custom actions location");
            check(Qt.resolvedUrl(Directories.shellConfigPath).toString().startsWith("file:///"), "config link resolves as a file URL");
            Config.options.apps.terminal = "new-terminal";
            console.log("SETTINGS_TEST_DONE");
        }
    }
    Timer { interval: 700; running: true; onTriggered: Qt.quit() }
}
''')
            result = subprocess.run(["qs", "-p", str(root)], capture_output=True, text=True, timeout=8,
                                    env=dict(os.environ, QT_QPA_PLATFORM="offscreen", XDG_CONFIG_HOME=str(config_home)))
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertIn("SETTINGS_TEST_DONE", output)
            for error in ("ASSERTION_FAILED", "TypeError", "ReferenceError"):
                self.assertNotIn(error, output)
            return json.loads((new / "config.json").read_text())

    def test_loads_and_saves_preferences_in_new_folder(self):
        saved = self.run_storage('{"apps":{"terminal":"saved-terminal"},"language":{"ui":"de_DE"}}')
        self.assertEqual(saved["apps"]["terminal"], "new-terminal")
        self.assertEqual(saved["language"]["ui"], "de_DE")

    def test_missing_settings_are_initialized_in_new_folder(self):
        saved = self.run_storage()
        self.assertEqual(saved["apps"]["terminal"], "new-terminal")


if __name__ == "__main__":
    unittest.main()
