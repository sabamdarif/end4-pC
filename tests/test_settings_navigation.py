import re
import unittest

from ui_test_utils import REPOSITORY


class SettingsNavigationTests(unittest.TestCase):
    def test_island_settings_target_is_a_registered_leaf(self):
        island = (REPOSITORY / "modules/ii/bar/DiXIdle.qml").read_text()
        registry = (REPOSITORY / "modules/ii/settings/SettingsPages.qml").read_text()
        target = re.search(r'GlobalStates\.openSettingsAt\("([^"]+)"\)', island).group(1)
        leaves = re.findall(r'\{\s*key:\s*"([^"]+)"[^\n]*component:', registry)
        self.assertEqual(target, "right-sidebar")
        self.assertIn(target, leaves)


if __name__ == "__main__":
    unittest.main()
