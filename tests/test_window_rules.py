import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import os

from ui_test_utils import prepare_niri_config_fixture, qml_block


@unittest.skipUnless(shutil.which("node"), "Node.js is required")
class WindowRulesTests(unittest.TestCase):
    def generate(self, rules):
        escape = qml_block("services/NiriConfig.qml", "    function kdlEscape(", "    function windowRulesKdl(")
        generator = qml_block("services/NiriConfig.qml", "    function windowRulesKdl(", "    function generateWindowRulesKdl(")
        script = escape + generator + "\nconst root = {kdlEscape};\nconsole.log(windowRulesKdl(" + json.dumps(rules) + "));"
        return subprocess.run(["node", "-e", script], capture_output=True, text=True)

    def test_combined_match_and_all_properties_validate(self):
        rule = {"match": {"appId": '^org\\.example\\.App$', "title": 'a"b\nc', "isFloating": False, "isFocused": True},
                "properties": {"openFloating": True, "openMaximized": False, "openFullscreen": False,
                    "opacity": 0.95, "columnWidth": 0.5, "blockOutFrom": "screencast", "clipToGeometry": True, "scrollFactor": 0.8}}
        result = self.generate([rule])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.count("match "), 1)
        self.assertIn("is-floating=false is-focused=true", result.stdout)
        self.assertIn('title="a\\"b\\nc"', result.stdout)
        if shutil.which("niri"):
            with tempfile.TemporaryDirectory() as directory:
                path = Path(directory) / "rules.kdl"
                path.write_text(result.stdout)
                validation = subprocess.run(["niri", "validate", "-c", str(path)], capture_output=True, text=True)
                self.assertEqual(validation.returncode, 0, validation.stderr)

    def test_disabled_rules_and_defaults_are_omitted(self):
        result = self.generate([{"enabled": False}, {"match": {"appId": "kitty"}, "properties": {"opacity": None}}])
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout.count("window-rule"), 1)
        self.assertNotIn("opacity", result.stdout)

    def test_invalid_values_never_produce_kdl(self):
        for props in ({"opacity": "0.9; malicious"}, {"opacity": 2}, {"columnWidth": 0},
                      {"scrollFactor": -1}, {"openFloating": "true"}, {"blockOutFrom": '"; }'}):
            with self.subTest(props=props):
                self.assertNotEqual(self.generate([{"match": {"appId": "kitty"}, "properties": props}]).returncode, 0)
        self.assertNotEqual(self.generate([{"match": {}}]).returncode, 0)


@unittest.skipUnless(shutil.which("qs") and shutil.which("niri"), "Quickshell and niri are required")
class WindowRulePersistenceTests(unittest.TestCase):
    def test_save_validates_before_persisting_and_keeps_invalid_drafts_out(self):
        with tempfile.TemporaryDirectory(prefix="window-rule-save-") as directory:
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
        interval: 20; running: true; repeat: true
        onTriggered: {
            if (root.stage !== 0 || !NiriConfig.ready) return;
            root.stage = 1;
            NiriConfig.saveWindowRule(-1, {match: {appId: "^kitty$"}, properties: {opacity: 0.95}});
        }
    }
    Connections {
        target: NiriConfig
        function onWindowRuleSaved() {
            root.check(root.stage === 1, "only the valid draft saves");
            root.check(NiriConfig.options.windowRules.length === 1, "valid rule enters settings");
            root.stage = 2;
            NiriConfig.saveWindowRule(0, {match: {appId: "["}, properties: {opacity: 0.5}});
        }
        function onWindowRuleErrorChanged() {
            if (root.stage !== 2 || NiriConfig.windowRuleError === "") return;
            root.check(NiriConfig.options.windowRules[0].properties.opacity === 0.95, "invalid regex leaves the saved rule intact");
            root.stage = 3;
        }
    }
    Timer {
        interval: 1000; running: true
        onTriggered: {
            root.check(root.stage === 3, "both validation outcomes completed");
            console.log("RULE_SAVE_TEST_DONE");
            Qt.quit();
        }
    }
}
''')
            result = subprocess.run(["qs", "-p", str(root)], capture_output=True, text=True, timeout=10,
                env=dict(os.environ, QT_QPA_PLATFORM="offscreen"))
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertIn("RULE_SAVE_TEST_DONE", output)
            for error in ("ASSERTION_FAILED", "TypeError", "ReferenceError"):
                self.assertNotIn(error, output)
            saved = json.loads((managed / "settings.json").read_text())["windowRules"]
            self.assertEqual(saved[0]["properties"]["opacity"], 0.95)
            self.assertIn("opacity 0.95", (managed / "windowrules.kdl").read_text())
