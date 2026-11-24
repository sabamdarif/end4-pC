import importlib.util
from pathlib import Path
import os
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("wifi_qr", Path(__file__).resolve().parents[1] / "scripts/network/wifi_qr.py")
qr = importlib.util.module_from_spec(spec)
spec.loader.exec_module(qr)


class WifiQrTests(unittest.TestCase):
    def profile(self, mode="wpa-psk"):
        return {"connection.type": "802-11-wireless", "802-11-wireless.ssid": 'a;:b\\"',
                "802-11-wireless-security.key-mgmt": mode, "802-11-wireless-security.psk": "secret;"}

    def test_escaping_and_hidden(self):
        profile = self.profile()
        profile["802-11-wireless.hidden"] = "yes"
        payload, details = qr.profile_payload(profile)
        self.assertEqual(payload, 'WIFI:S:a\\;\\:b\\\\\\";T:WPA;P:secret\\;;H:true;;')
        self.assertEqual(details["password"], "secret;")

    def test_open_and_wep(self):
        self.assertIn("T:nopass;P:;;", qr.profile_payload(self.profile(""))[0])
        profile = self.profile("none")
        profile.update({"802-11-wireless-security.wep-tx-keyidx": "2", "802-11-wireless-security.wep-key2": "abcde"})
        self.assertIn("T:WEP;P:abcde;;", qr.profile_payload(profile)[0])

    def test_missing_and_unsupported_secrets(self):
        for mode in ("wpa-eap", "owe"):
            with self.assertRaisesRegex(ValueError, "unsupported-security"):
                qr.profile_payload(self.profile(mode))
        profile = self.profile()
        profile["802-11-wireless-security.psk"] = "<hidden>"
        with self.assertRaisesRegex(ValueError, "missing-secret"):
            qr.profile_payload(profile)

    def test_uuid_validation_precedes_commands(self):
        with patch.object(qr.subprocess, "run") as run:
            with self.assertRaises(ValueError):
                qr.generate("--help")
            run.assert_not_called()

    def test_saved_images_are_private_and_atomic(self):
        with tempfile.TemporaryDirectory() as directory:
            source, target = Path(directory) / "source", Path(directory) / "target"
            source.write_bytes(b"png")
            target.write_bytes(b"old")
            qr.save_image(source, target)
            self.assertEqual(target.read_bytes(), b"png")
            self.assertEqual(target.stat().st_mode & 0o777, 0o600)
            with self.assertRaises(OSError):
                qr.save_image(Path(directory) / "missing", target)
            self.assertEqual(target.read_bytes(), b"png")
