import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

from ui_test_utils import prepare_niri_config_fixture, qml_block


REPOSITORY = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("niri_list_binds", REPOSITORY / "scripts/niri/list-binds.py")
BINDS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(BINDS)


class ShortcutParserTests(unittest.TestCase):
    def test_actions_and_options_survive_strings_and_repeated_includes(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "keys.kdl").write_text('''binds {
    Mod+T repeat=false allow-when-locked=true cooldown-ms=250 hotkey-overlay-title="A \\\"title\\\"" {
        spawn "sh" "-c" "printf 'a  b // { }'";
    }
    /-Mod+Q { close-window; }
}''')
            (root / "config.kdl").write_text('include "keys.kdl"\nbinds { Mod+T { close-window; }; }\ninclude "keys.kdl"')
            result = BINDS.read_binds(root / "config.kdl")
            self.assertEqual(len(result["binds"]), 3)
            first, middle, last = result["binds"]
            self.assertEqual(first["action"], 'spawn "sh" "-c" "printf \'a  b // { }\'"')
            self.assertEqual(first["title"], 'A "title"')
            self.assertEqual(first["properties"], {"repeat": False, "allow-when-locked": True, "cooldown-ms": 250})
            self.assertEqual(middle["action"], "close-window")
            self.assertEqual(last, first)

    def test_optional_include_is_detected_before_overrides_exist(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config = root / "config.kdl"
            config.write_text('input { mod-key "Alt"; }\ninclude "qssettings/binds.kdl" optional=true')
            result = BINDS.read_binds(config)
            self.assertTrue(result["included"])
            self.assertEqual(result["modKey"], "Alt")
            self.assertEqual(result["binds"], [])

    def test_missing_include_keeps_saved_overrides_visible_and_reports_setup(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "qssettings").mkdir()
            config = root / "config.kdl"
            config.write_text('binds { Mod+T { close-window; }; }')
            (root / "qssettings/binds.kdl").write_text('binds { Mod+T { spawn "kitty"; }; }')
            result = BINDS.read_binds(config)
            self.assertFalse(result["included"])
            self.assertEqual([b["action"] for b in result["binds"]], ["close-window", 'spawn "kitty"'])

    def test_globs_symlinks_and_include_cycles(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "keys").mkdir()
            (root / "keys/a.kdl").write_text('binds { Mod+A { close-window; }; }')
            (root / "keys/b.kdl").symlink_to(root / "keys/a.kdl")
            config = root / "config.kdl"
            config.write_text('include "keys/*.kdl"')
            self.assertEqual(len(BINDS.read_binds(config)["binds"]), 2)
            (root / "keys/a.kdl").write_text('include "../config.kdl"')
            with self.assertRaises(ValueError):
                BINDS.read_binds(config)

    def test_action_cannot_escape_its_bind_block(self):
        for text in ('binds {\n Mod+T { close-window; }\n}\ninput {}\n',
                     'binds {\n Mod+T { close-window; spawn "kitty"; }\n}\n'):
            with self.subTest(text=text), self.assertRaises(ValueError):
                BINDS.validate_binds(text)
        injection = 'close-window; }\nMod+Q { quit;'
        with self.assertRaises(ValueError):
            BINDS.validate_binds('binds {\n Mod+T { close-window; }\n Mod+Q { quit; }\n}\n', [injection])


@unittest.skipUnless(shutil.which("node"), "Node.js is required")
class ShortcutLogicTests(unittest.TestCase):
    def run_js(self, body):
        source = (REPOSITORY / "services/NiriShortcuts.js").read_text().replace(".pragma library", "")
        script = source + '\nconst assert = require("node:assert/strict");\n' + body
        result = subprocess.run(["node", "-e", script], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_grouping_search_and_override_conflicts_use_normalized_keys(self):
        self.run_js('''
const raw = [
 {key: "Ctrl+Mod+T", action: "close-window", title: "Close", source: "/keys.kdl"},
 {key: "Super+Control+T", action: 'spawn "kitty"', title: "Terminal", source: "/qssettings/binds.kdl"},
 {key: "Mod+Return", action: 'spawn "kitty"', title: "Terminal", source: "/keys.kdl"}
];
const effective = effectiveBinds(raw, "Super");
assert.equal(effective.length, 2);
assert.equal(effective[0].conflict, true);
const groups = groupedBinds(effective);
assert.equal(groups.length, 1);
assert.equal(groups[0].keys.length, 2);
assert.equal(matchesSearch(groups[0], "meta+ctrl+t", "Super"), true);
assert.equal(matchesSearch(groups[0], "Terminal kitty", "Super"), true);
assert.equal(matchesSearch(groups[0], "unrelated", "Super"), false);
const overridden = effectiveBinds(raw.concat({key: "Mod+Ctrl+T", action: "close-window", source: "/later.kdl"}), "Super");
assert.equal(overridden[0].overriddenByConfig, true);
''')

    def test_moving_override_replaces_old_key_without_dropping_other_options(self):
        self.run_js('''
const other = {key: "Mod+B", action: "close-window", properties: {repeat: false}};
const entry = {key: "Mod+N", action: 'spawn "kitty"', properties: {"allow-when-locked": true}};
const result = updatedOverrides([{key: "Super+T"}, other, {key: "Mod+N"}], "Mod+T", entry, "Super");
assert.deepEqual(result, [other, entry]);
''')

    def test_capture_handles_mod_key_keypad_shifted_digits_and_search_editing(self):
        self.run_js('''
assert.equal(eventCombo({key: 84, modifiers: 0x10000000 | 0x02000000}, "Super"), "Mod+Shift+T");
assert.equal(eventCombo({key: 84, modifiers: 0x08000000}, "Alt"), "Mod+T");
assert.equal(eventCombo({key: 16777221, modifiers: 0x20000000}, "Super"), "KP_Enter");
assert.equal(eventCombo({key: 33, modifiers: 0x02000000, nativeScanCode: 10}, "Super"), "Shift+1");
assert.equal(searchCombo({key: 65, text: "a", modifiers: 0}, "Super"), "");
assert.equal(searchCombo({key: 67, text: "c", modifiers: 0x04000000}, "Super"), "");
assert.equal(searchCombo({key: 16777330, text: "", modifiers: 0}, "Super"), "XF86AudioRaiseVolume");
''')

    def test_command_and_shell_fields_round_trip_quoted_arguments(self):
        self.run_js('''
const command = 'kitty -e "printf hello world"';
const action = commandAction(command);
assert.deepEqual(spawnTokens(action), ["kitty", "-e", "printf hello world"]);
assert.equal(commandAction(actionForm(action).text), action);
const shell = "printf 'a  b' | cat";
assert.deepEqual(actionForm(shellAction(shell)), {type: "shell", text: shell});
''')

    def test_generated_options_and_escaped_title_validate_with_niri(self):
        generator = qml_block("services/NiriConfig.qml", "    function bindsKdl(", "    function generateBindsKdl(")
        escape = qml_block("services/NiriConfig.qml", "    function kdlEscape(", "    function windowRulesKdl(")
        script = escape + generator + '\nconst root = {kdlEscape};\nconsole.log(bindsKdl(' + json.dumps([
            {"key": "Mod+T", "action": 'spawn "sh" "-c" "printf \'a  b\'"', "title": 'A "title"',
             "properties": {"repeat": False, "allow-when-locked": True, "allow-inhibiting": False, "cooldown-ms": 250}}
        ]) + '));'
        result = subprocess.run(["node", "-e", script], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        if shutil.which("niri"):
            BINDS.validate_binds(result.stdout)


@unittest.skipUnless(shutil.which("qs") and shutil.which("niri"), "Quickshell and niri are required")
class ShortcutPersistenceTests(unittest.TestCase):
    def test_invalid_action_does_not_replace_saved_override(self):
        with tempfile.TemporaryDirectory(prefix="shortcut-save-") as directory:
            root = Path(directory)
            managed = prepare_niri_config_fixture(root)
            (root / "shell.qml").write_text('''import QtQuick
import Quickshell
import "services"
ShellRoot {
    id: root
    property int stage: 0
    function check(condition, message) { if (!condition) console.error("ASSERTION_FAILED", message); }
    Timer {
        interval: 10; running: true; repeat: true
        onTriggered: {
            if (root.stage || !NiriConfig.ready) return;
            root.stage = 1;
            NiriConfig.saveBindOverride("", {key: "Mod+T", action: 'spawn "kitty"', title: "Terminal", properties: {repeat: false}}, "Super");
        }
    }
    Connections {
        target: NiriConfig
        function onBindSaveCompleted(success) {
            if (root.stage === 1) {
                root.check(success, NiriConfig.bindError);
                root.check(NiriConfig.options.bindOverrides.length === 1, "valid bind saved");
                root.stage = 2;
                NiriConfig.saveBindOverride("Mod+T", {key: "Mod+T", action: "not-a-niri-action", title: "Invalid"}, "Super");
            } else if (root.stage === 2) {
                root.check(!success, "invalid action rejected");
                root.check(NiriConfig.options.bindOverrides[0].action === 'spawn "kitty"', "saved action preserved");
                root.stage = 3;
                NiriConfig.saveBindOverride("Mod+T", {key: "Mod+N", action: 'spawn "kitty"', title: "Terminal", properties: {repeat: false}}, "Super");
            } else if (root.stage === 3) {
                root.check(success, NiriConfig.bindError);
                root.check(NiriConfig.options.bindOverrides.length === 1 && NiriConfig.options.bindOverrides[0].key === "Mod+N", "override moved rather than duplicated");
                root.stage = 4;
                NiriConfig.removeBindOverride("Super+N", "Super");
            } else {
                root.check(success && NiriConfig.options.bindOverrides.length === 0, "reset removes normalized override key");
                console.log("SHORTCUT_SAVE_TEST_DONE");
                Qt.quit();
            }
        }
    }
    Timer { interval: 6000; running: true; onTriggered: { console.error("ASSERTION_FAILED", "save did not complete", root.stage, NiriConfig.bindError); Qt.quit(); } }
}
''')
            result = subprocess.run(["qs", "-p", str(root)], capture_output=True, text=True, timeout=9,
                                    env=dict(os.environ, QT_QPA_PLATFORM="offscreen"))
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertIn("SHORTCUT_SAVE_TEST_DONE", output)
            for error in ("ASSERTION_FAILED", "TypeError", "ReferenceError"):
                self.assertNotIn(error, output)
            self.assertEqual(json.loads((managed / "settings.json").read_text())["bindOverrides"], [])
            self.assertEqual((managed / "binds.kdl").read_text().split("binds", 1)[1].strip(), "{\n}")


@unittest.skipUnless(shutil.which("qs") and shutil.which("niri") and os.environ.get("WAYLAND_DISPLAY")
                     and (Path(os.environ.get("XDG_RUNTIME_DIR", "")) / os.environ["WAYLAND_DISPLAY"]).is_socket(),
                     "Quickshell, niri and a running Wayland compositor are required")
class ShortcutPageLoadingTests(unittest.TestCase):
    def test_url_loaded_page_resolves_rows_and_opens_editor(self):
        with tempfile.TemporaryDirectory(prefix="shortcut-page-") as directory:
            root = Path(directory)
            for name in ("modules", "services", "scripts", "assets", "GlobalStates.qml"):
                (root / name).symlink_to(REPOSITORY / name, target_is_directory=(REPOSITORY / name).is_dir())
            config = root / "config"
            (config / "niri/qssettings").mkdir(parents=True)
            (config / "niri/config.kdl").write_text('binds { Mod+T { spawn "kitty"; }; }\n')
            (root / "shell.qml").write_text('''import QtQuick
import QtQuick.Controls
import Quickshell
ShellRoot {
    Window {
        id: window
        visible: true; width: 1000; height: 760
        property int stage: 0
        function findNamed(item, name) {
            if (item.objectName === name) return item;
            for (const child of item.children || []) { const found = findNamed(child, name); if (found) return found; }
            return null;
        }
        function checkSearchControls() {
            const search = findNamed(page.item, "shortcutSearchField");
            const reload = findNamed(page.item, "shortcutReloadButton");
            if (!search || !reload || search.height <= 0 || reload.height !== search.height || reload.width !== search.height)
                console.error("ASSERTION_FAILED", "reload must be square and match search height");
            if (search && (!search.background || search.background.radius < search.height / 2))
                console.error("ASSERTION_FAILED", "search must use the pill ToolbarTextField");
            if (reload && reload.buttonRadius < reload.height / 2)
                console.error("ASSERTION_FAILED", "reload must use pill radius matching search");
        }
        function checkFocusedSearchHint() {
            const search = findNamed(page.item, "shortcutSearchField");
            if (!search.activeFocus)
                console.error("ASSERTION_FAILED", "search must have focus for the hint check");
            if (!search.background || search.background.border.width !== 0)
                console.error("ASSERTION_FAILED", "pill search field must stay borderless");
            return true;
        }
        function findRow(item) {
            if (item.bindData) return item;
            for (const child of item.children || []) { const row = findRow(child); if (row) return row; }
            return null;
        }
        function findEditor(item) {
            if (item.item && typeof item.item.present === "function") return item.item;
            for (const child of item.children || []) { const editor = findEditor(child); if (editor) return editor; }
            return null;
        }
        Loader {
            id: page
            anchors.fill: parent
            source: Qt.resolvedUrl("modules/ii/settings/pages/input/ShortcutsConfig.qml")
        }
        Timer {
            interval: 100; running: true; repeat: true
            onTriggered: {
                if (!page.item || page.item.filteredGroups.length !== 1) return;
                if (window.stage === 0) {
                    const row = window.findRow(page.item);
                    if (!row || row.width <= 0 || row.height <= 0) return;
                    window.checkSearchControls();
                    window.findNamed(page.item, "shortcutSearchField").forceActiveFocus();
                    window.width = 600;
                    window.stage = 1;
                } else if (window.stage === 1) {
                    window.checkSearchControls();
                    if (!window.checkFocusedSearchHint()) return;
                    const row = window.findRow(page.item);
                    window.stage = 2;
                    row.editRequested(0);
                } else {
                    const editor = window.findEditor(page.item);
                    if (!editor || !editor.visible || editor.originalKey !== "Mod+T") return;
                    console.log("SHORTCUT_PAGE_TEST_DONE");
                    Qt.quit();
                }
            }
        }
        Timer { interval: 5000; running: true; onTriggered: {
            console.error("ASSERTION_FAILED", "lazy shortcuts page or editor did not load", page.status, window.stage);
            Qt.quit();
        } }
    }
}
''')
            result = subprocess.run(["qs", "-p", str(root)], capture_output=True, text=True, timeout=8,
                                    env=dict(os.environ, QT_QPA_PLATFORM="wayland", XDG_CONFIG_HOME=str(config),
                                             XDG_CACHE_HOME=str(root / "cache"), XDG_STATE_HOME=str(root / "state")))
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertIn("SHORTCUT_PAGE_TEST_DONE", output)
            for error in ("ASSERTION_FAILED", "is not a type", "is not installed", "TypeError", "ReferenceError"):
                self.assertNotIn(error, output)
