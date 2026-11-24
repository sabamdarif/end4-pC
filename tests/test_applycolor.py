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
        self.terminal = self.state / "terminal"
        self.terminal.mkdir()
        self.terminal.joinpath("kitty-theme.conf").write_text("background #123456\nforeground #abcdef\n")
        self.palette = {f"term{i}": f"#{i:06x}" for i in range(16)}
        self.palette.update(background="#123456", foreground="#abcdef", cursor="#fedcba",
                            selection_background="#112233", selection_foreground="#aabbcc")
        self.terminal.joinpath("colors.json").write_text(json.dumps(self.palette))
        config = self.root / "config/qssettings"
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
        self.assertFalse((self.terminal / "sequences.txt").exists())

    def test_kitty_reloads_the_matugen_output_without_rewriting_it(self):
        result = subprocess.run(["bash", "-c", '''
kill() { printf '%s\n' "$@" > "$KILL_LOG"; }
pidof() { printf '%s' 1234; }
source "$1"
apply_kitty
''', "applycolor-test", str(SCRIPT)],
            cwd=self.root, env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        theme = (self.state / "terminal/kitty-theme.conf").read_text()
        self.assertEqual(theme, "background #123456\nforeground #abcdef\n")
        self.assertEqual((self.root / "signals").read_text().splitlines(), ["-SIGUSR1", "1234"])

    def test_escape_sequences_use_the_matugen_palette(self):
        result = subprocess.run(["bash", "-c", 'source "$1"; write_sequences', "test", str(SCRIPT)],
                                env=self.env, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        for index in range(16):
            self.assertIn(f"\x1b]4;{index};#{index:06x}\x1b\\".encode(), result.stdout)
        self.assertIn(b"\x1b]10;#abcdef\x1b\\", result.stdout)
        self.assertIn(b"\x1b]11;#123456\x1b\\", result.stdout)

    def test_invalid_palette_is_rejected_before_emitting_sequences(self):
        self.palette["term1"] = "\x1b]0;injected"
        self.terminal.joinpath("colors.json").write_text(json.dumps(self.palette))
        result = subprocess.run(["bash", "-c", 'source "$1"; write_sequences', "test", str(SCRIPT)],
                                env=self.env, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, b"")


if __name__ == "__main__":
    unittest.main()
