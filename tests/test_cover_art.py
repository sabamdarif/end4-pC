import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "scripts/images/fetch-cover.sh"


class CoverArtTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="cover-art-", dir="/tmp/opencode")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.target = self.root / "cache with 'quotes'" / "cover"
        curl = self.root / "curl"
        curl.write_text('''#!/usr/bin/env python3
import os
from pathlib import Path
import sys
args = sys.argv[1:]
Path(os.environ["CURL_ARGS"]).write_text(repr(args))
Path(args[args.index("--output") + 1]).write_bytes(os.environ.get("CURL_DATA", "image").encode())
sys.exit(int(os.environ.get("CURL_EXIT", "0")))
''')
        curl.chmod(0o755)
        self.env = dict(os.environ, PATH=f"{self.root}:{os.environ['PATH']}", CURL_ARGS=str(self.root / "args"))

    def fetch(self, url="https://example.test/cover", **environment):
        return subprocess.run(["bash", str(SCRIPT), str(self.target), url],
                              env=dict(self.env, **environment), capture_output=True)

    def test_url_and_path_are_literal_arguments(self):
        url = "https://example.test/art'; touch injected; echo '$(whoami)"
        self.assertEqual(self.fetch(url).returncode, 0)
        self.assertEqual(self.target.read_bytes(), b"image")
        self.assertIn(repr(url), (self.root / "args").read_text())
        self.assertFalse((self.root / "injected").exists())

    def test_cached_cover_is_not_downloaded_again(self):
        self.assertEqual(self.fetch().returncode, 0)
        (self.root / "args").unlink()
        self.assertEqual(self.fetch(CURL_EXIT="22").returncode, 0)
        self.assertFalse((self.root / "args").exists())

    def test_failed_download_does_not_cache_partial_data(self):
        self.assertNotEqual(self.fetch(CURL_EXIT="22").returncode, 0)
        self.assertFalse(self.target.exists())
        self.assertEqual(list(self.target.parent.iterdir()), [])

    def test_empty_download_is_rejected(self):
        self.assertNotEqual(self.fetch(CURL_DATA="").returncode, 0)
        self.assertFalse(self.target.exists())

    def test_empty_old_cache_is_replaced(self):
        self.target.parent.mkdir()
        self.target.touch()
        self.assertEqual(self.fetch().returncode, 0)
        self.assertEqual(self.target.read_bytes(), b"image")


if __name__ == "__main__":
    unittest.main()
