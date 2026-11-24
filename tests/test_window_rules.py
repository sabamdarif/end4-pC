import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

from ui_test_utils import qml_block


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
