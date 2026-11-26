import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

from ui_test_utils import prepare_niri_config_fixture


REPOSITORY = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("niri_config_settings", REPOSITORY / "scripts/niri/config-settings.py")
CONFIG = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = CONFIG
SPEC.loader.exec_module(CONFIG)


class NiriConfigTests(unittest.TestCase):
    def test_nested_includes_follow_order_and_allow_repeated_files(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "parts").mkdir()
            (root / "parts/input.kdl").write_text('input { mouse { natural-scroll; accel-speed 0.3; }; }')
            (root / "parts/extra.kdl").write_text('include "input.kdl"\nlayout { gaps 9; }')
            (root / "config.kdl").write_text('include "parts/extra.kdl"\ninput { mouse { accel-speed -0.2; }; }\ninclude "parts/input.kdl"\ninclude "missing.kdl" optional=true')
            files = set()
            state = CONFIG.values(CONFIG.effective(CONFIG.load_config(root / "config.kdl", files)))
            self.assertTrue(state["input.mouse.naturalScroll"])
            self.assertEqual(state["input.mouse.accelSpeed"], 0.3)
            self.assertEqual(state["layout.gaps"], 9)
            self.assertIn(str(root / "missing.kdl"), files)

    def test_sections_merge_but_pointing_devices_and_xkb_replace(self):
        nodes = CONFIG.parse('''input { keyboard { repeat-rate 50; xkb { layout "us"; options "compose:ralt"; }; }; mouse { natural-scroll; accel-speed 0.2; }; touchpad { tap; }; }
input { keyboard { xkb { layout "de"; }; }; mouse {}; }
layout { border { off; width 1.5; }; }
layout { gaps 8; border { on; }; }
blur { off; }
blur { passes 4; }
animations { off; }
animations { on; slowdown 2; }''')
        current = CONFIG.effective(nodes)
        state = CONFIG.values(current)
        self.assertFalse(state["input.mouse.naturalScroll"])
        self.assertEqual(state["input.mouse.accelSpeed"], 0)
        self.assertTrue(state["input.touchpad.tap"])
        self.assertEqual(state["input.repeatRate"], 50)
        self.assertIsNone(CONFIG.find(current, "input/keyboard/xkb/options"))
        self.assertTrue(state["decoration.border.enable"])
        self.assertEqual(state["decoration.border.width"], 1.5)
        self.assertFalse(state["decoration.blur.enable"])
        self.assertTrue(state["animations.enable"])

    def test_comments_raw_strings_and_conditional_rules_do_not_change_global_values(self):
        current = CONFIG.effective(CONFIG.parse('''/* outer /* inner */ comment */
/-input { mouse { natural-scroll; }; }
input { mouse { /-natural-scroll; accel-speed 0.2; }; keyboard { xkb { options r#"compose:ralt // {}"#; }; }; }
window-rule { geometry-corner-radius 8; }
window-rule { match app-id=r#"^org\\.app{foo}$"#; geometry-corner-radius 20; }
// input { mouse { natural-scroll; }; }
cursor { xcursor-theme "a\\\"b"; }'''))
        state = CONFIG.values(current)
        self.assertFalse(state["input.mouse.naturalScroll"])
        self.assertEqual(state["decoration.rounding"], 8)
        self.assertEqual(state["cursor.theme"], 'a"b')
        self.assertEqual(CONFIG.find(current, "input/keyboard/xkb/options").argument(), "compose:ralt // {}")

    def test_symlink_targets_are_watched_and_cycles_fail(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "actual.kdl").write_text('input { mouse { natural-scroll; }; }')
            (root / "linked.kdl").symlink_to(root / "actual.kdl")
            (root / "config.kdl").write_text('include "linked.kdl"')
            files = set()
            CONFIG.load_config(root / "config.kdl", files)
            self.assertIn(str(root / "linked.kdl"), files)
            self.assertIn(str(root / "actual.kdl"), files)
            (root / "actual.kdl").write_text('include "config.kdl"')
            with self.assertRaises(ValueError):
                CONFIG.load_config(root / "config.kdl")

    def test_generation_only_overrides_changed_settings_and_preserves_device_extras(self):
        current = CONFIG.effective(CONFIG.parse('''input {
mouse { natural-scroll; accel-speed 0.4; accel-profile "flat"; left-handed; }
touchpad { tap; dwtp; drag false; }
keyboard { xkb { layout "us"; options "compose:ralt"; variant "intl"; }; }
}
layout { gaps 9; }
cursor { xcursor-theme "example"; }'''))
        kdl = CONFIG.generate([], current, {"cursor.size": 32})
        self.assertNotIn("input", kdl)
        self.assertNotIn("layout {", kdl)
        self.assertNotIn("xcursor-theme", kdl)
        kdl = CONFIG.generate([], current, {"input.mouse.naturalScroll": False, "input.kbLayout": "de"})
        self.assertNotIn("natural-scroll", kdl)
        self.assertIn('accel-profile "flat"', kdl)
        self.assertIn("left-handed", kdl)
        self.assertIn('options "compose:ralt"', kdl)
        self.assertIn('variant "intl"', kdl)
        self.assertNotIn("touchpad", kdl)
        self.assertNotIn("layout {", kdl)

    def test_explicit_off_flags_and_parameters_survive_generation(self):
        changes = {"decoration.blur.enable": False, "animations.enable": True,
                   "input.numlock": False, "cursor.hideWhenTyping": False,
                   "input.focusFollowsMouseMaxScroll": "0%", "input.focusFollowsMouse": True}
        kdl = CONFIG.generate([], [], changes)
        self.assertIn('max-scroll-amount="0%"', kdl)
        self.assertIn("numlock false", kdl)
        self.assertIn("hide-when-typing false", kdl)
        self.assertFalse(CONFIG.values(CONFIG.effective(CONFIG.parse(kdl)))["decoration.blur.enable"])
        if shutil.which("niri"):
            with tempfile.TemporaryDirectory() as directory:
                path = Path(directory) / "shell.kdl"
                path.write_text(kdl)
                CONFIG.validate(path)

    def test_invalid_changes_fail_without_producing_config(self):
        for changes in ({"unknown": True}, {"input.mouse.naturalScroll": "true"},
                        {"cursor.size": 1000}, {"input.mouse.accelSpeed": float("nan")},
                        {"input.repeatRate": 1.5}, {"cursor.theme": "bad\x00theme"}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                CONFIG.generate([], [], changes)

    def test_all_supported_options_generate_valid_kdl(self):
        changes = {key: spec[1] for key, spec in CONFIG.SETTINGS.items()}
        kdl = CONFIG.generate([], [], changes)
        if shutil.which("niri"):
            with tempfile.TemporaryDirectory() as directory:
                path = Path(directory) / "shell.kdl"
                path.write_text(kdl)
                CONFIG.validate(path)

    def test_custom_column_widths_are_not_reported_as_a_preset(self):
        current = CONFIG.effective(CONFIG.parse('layout { default-column-width { proportion 0.5; }; }\nlayout { default-column-width { fixed 1000; }; }'))
        self.assertEqual(CONFIG.values(current)["layout.defaultColumnWidth"], -1)
        kdl = CONFIG.generate([], current, {"layout.defaultColumnWidth": 0.3})
        self.assertNotIn("fixed", kdl)
        self.assertIn("proportion 0.3", kdl)

    def test_external_rules_preserve_match_groups_exclusions_and_source(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            managed = root / "qssettings"
            managed.mkdir()
            custom = root / "rules.kdl"
            custom.write_text('window-rule { match app-id="kitty"; match title="Browser"; exclude is-focused=true; background-effect { blur true; }; }')
            (managed / "windowrules.kdl").write_text('window-rule { match app-id="managed"; open-floating true; }')
            path = root / "config.kdl"
            path.write_text('include "rules.kdl"\ninclude "qssettings/windowrules.kdl"')
            rules = CONFIG.external_window_rules(CONFIG.load_config(path), managed)
            self.assertEqual(len(rules), 1)
            self.assertEqual(rules[0]["source"], str(custom))
            self.assertEqual(rules[0]["kdl"].count("match "), 2)
            self.assertIn("exclude is-focused=true", rules[0]["kdl"])
            self.assertIn("background-effect", rules[0]["kdl"])

    def test_root_empty_border_enables_it_but_included_empty_border_does_not(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "part.kdl").write_text('layout { border {}; }')
            path = root / "config.kdl"
            path.write_text('include "part.kdl"')
            self.assertFalse(CONFIG.values(CONFIG.effective(CONFIG.load_config(path)))["decoration.border.enable"])
            path.write_text('layout { border {}; }')
            self.assertTrue(CONFIG.values(CONFIG.effective(CONFIG.load_config(path)))["decoration.border.enable"])


@unittest.skipUnless(shutil.which("qs") and shutil.which("niri"), "Quickshell and niri are required")
class NiriConfigServiceTests(unittest.TestCase):
    def test_reads_watches_and_saves_without_replacing_unrelated_user_settings(self):
        with tempfile.TemporaryDirectory(prefix="niri-config-ui-") as directory:
            root = Path(directory)
            managed = prepare_niri_config_fixture(root)
            config = managed.parent
            (config / "custom").mkdir()
            custom = config / "custom/input.kdl"
            custom.write_text('input { mouse { natural-scroll; accel-speed 0.4; accel-profile "flat"; }; touchpad { tap; dwtp; }; }\nblur { off; }')
            (config / "config.kdl").write_text('include "custom/input.kdl"\ninclude optional=true "qssettings/shell.kdl"')
            settings = managed / "settings.json"
            settings.write_text('{"input":{"mouse":{"naturalScroll":false}},"windowRules":[]}')
            before = settings.read_bytes()
            (root / "shell.qml").write_text('''import QtQuick
import Quickshell
import Quickshell.Io
import "services"
ShellRoot {
    id: root
    property int stage: 0
    function check(condition, message) { if (!condition) console.error("ASSERTION_FAILED", message); }
    FileView { id: custom; path: ''' + json.dumps(str(custom)) + ''' }
    Timer {
        interval: 30; running: true; repeat: true
        onTriggered: {
            if (!NiriConfig.ready) return;
            if (root.stage === 0) {
                root.check(NiriConfig.options.input.mouse.naturalScroll, "KDL wins over stale JSON");
                root.check(NiriConfig.options.input.mouse.accelSpeed === 0.4, "custom acceleration is read");
                root.check(!NiriConfig.options.decoration.blur.enable, "custom blur off is read");
                console.log("INITIAL_READ_DONE");
                root.stage = 1;
                initialDelay.start();
            } else if (root.stage === 2 && !NiriConfig.refreshPending && !Object.keys(NiriConfig.generatingChanges).length && !Object.keys(NiriConfig.pendingChanges).length) {
                root.stage = 3;
                custom.setText('input { mouse { accel-speed 0.6; accel-profile "flat"; }; touchpad { tap; dwtp; }; }\\nblur { off; }');
            } else if (root.stage === 3 && NiriConfig.options.input.mouse.accelSpeed === 0.6) {
                root.check(!NiriConfig.options.input.mouse.naturalScroll, "included file edits are watched");
                root.stage = 4;
                NiriConfig.options.input.mouse.naturalScroll = true;
            } else if (root.stage === 4 && !NiriConfig.refreshPending && !Object.keys(NiriConfig.generatingChanges).length && !Object.keys(NiriConfig.pendingChanges).length) {
                root.check(NiriConfig.configError === "", NiriConfig.configError);
                console.log("NIRI_CONFIG_TEST_DONE");
                Qt.quit();
            }
        }
    }
    Timer {
        id: initialDelay; interval: 300
        onTriggered: {
            root.stage = 2;
            NiriConfig.options.cursor.size = 32;
        }
    }
    Timer { interval: 5000; running: true; onTriggered: { console.error("ASSERTION_FAILED", "test timed out", root.stage, NiriConfig.configError); Qt.quit(); } }
}
''')
            process = subprocess.Popen(["qs", "-p", str(root)], stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                       text=True, env=dict(os.environ, QT_QPA_PLATFORM="offscreen"))
            output = ""
            try:
                for line in process.stdout:
                    output += line
                    if "INITIAL_READ_DONE" in line:
                        self.assertEqual(settings.read_bytes(), before)
                        self.assertFalse((managed / "shell.kdl").exists())
                    if "NIRI_CONFIG_TEST_DONE" in line:
                        break
                tail, _ = process.communicate(timeout=10)
                output += tail
            finally:
                if process.poll() is None:
                    process.kill()
                    process.wait()
            self.assertEqual(process.returncode, 0, output)
            self.assertIn("NIRI_CONFIG_TEST_DONE", output)
            for error in ("ASSERTION_FAILED", "TypeError", "ReferenceError", "Error loading configuration"):
                self.assertNotIn(error, output)
            kdl = (managed / "shell.kdl").read_text()
            self.assertIn('accel-profile "flat"', kdl)
            self.assertIn("accel-speed 0.6", kdl)
            self.assertIn("natural-scroll", kdl)
            self.assertIn("xcursor-size 32", kdl)
            for section in ("touchpad", "layout", "blur", "animations", "keyboard"):
                self.assertNotIn(section, kdl)
            self.assertTrue(json.loads(settings.read_text())["input"]["mouse"]["naturalScroll"])
