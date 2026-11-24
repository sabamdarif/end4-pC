import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


REPOSITORY = Path(__file__).resolve().parents[1]
SCRIPT = REPOSITORY / "scripts/colors/applycolor.sh"


class ApplyColorTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="applycolor-")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.state = self.root / "state/quickshell/user/generated"
        self.state.mkdir(parents=True)
        self.state.joinpath("material_colors.scss").write_text("$term0: #123456;\n$term7: #abcdef;\n")
        config = self.root / "config/illogical-impulse"
        config.mkdir(parents=True)
        config.joinpath("config.json").write_text(json.dumps({
            "appearance": {"wallpaperTheming": {"enableTerminal": False}}
        }))
        self.env = dict(os.environ, XDG_CONFIG_HOME=str(self.root / "config"),
                        XDG_STATE_HOME=str(self.root / "state"), XDG_CACHE_HOME=str(self.root / "cache"),
                        KILL_LOG=str(self.root / "signals"))

    def test_disabled_terminal_theming_does_not_generate_files(self):
        result = subprocess.run(["bash", str(SCRIPT)], cwd=self.root, env=self.env,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.state / "terminal").exists())

    def test_kitty_generation_does_not_require_an_ii_checkout(self):
        result = subprocess.run(["bash", "-c", '''
kill() { printf '%s\n' "$@" > "$KILL_LOG"; }
pidof() { printf '%s' 1234; }
source "$1"
test "$CONFIG_DIR" = "$2" || exit 1
apply_kitty
''', "applycolor-test", str(SCRIPT), str(REPOSITORY)],
            cwd=self.root, env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        theme = (self.state / "terminal/kitty-theme.conf").read_text()
        self.assertIn("background            #123456", theme)
        self.assertIn("foreground            #abcdef", theme)
        self.assertEqual((self.root / "signals").read_text().splitlines(), ["-SIGUSR1", "1234"])


if __name__ == "__main__":
    unittest.main()
