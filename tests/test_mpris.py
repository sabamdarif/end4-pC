import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPOSITORY = Path(__file__).resolve().parents[1]
SERVER = r'''
import os
import subprocess
import sys
import threading
from gi.repository import Gio, GLib

loop = GLib.MainLoop()

class Player:
    def __init__(self, name, state):
        self.connection = Gio.DBusConnection.new_for_address_sync(
            os.environ["DBUS_SESSION_BUS_ADDRESS"],
            Gio.DBusConnectionFlags.AUTHENTICATION_CLIENT | Gio.DBusConnectionFlags.MESSAGE_BUS_CONNECTION, None, None)
        self.properties = {
            "org.mpris.MediaPlayer2": {
                "Identity": ("s", name), "DesktopEntry": ("s", name), "CanQuit": ("b", False),
                "CanRaise": ("b", False), "HasTrackList": ("b", False),
                "SupportedUriSchemes": ("as", []), "SupportedMimeTypes": ("as", []),
            },
            "org.mpris.MediaPlayer2.Player": {
                "PlaybackStatus": ("s", state), "LoopStatus": ("s", "None"), "Rate": ("d", 1.0),
                "Shuffle": ("b", False), "Volume": ("d", 1.0), "Position": ("x", 0),
                "MinimumRate": ("d", 1.0), "MaximumRate": ("d", 1.0),
                "CanGoNext": ("b", True), "CanGoPrevious": ("b", True), "CanPlay": ("b", True),
                "CanPause": ("b", True), "CanSeek": ("b", False), "CanControl": ("b", True),
                "Metadata": ("a{sv}", {"mpris:trackid": GLib.Variant("o", "/test/track"),
                                      "xesam:title": GLib.Variant("s", "Track")}),
            },
        }
        for interface, values in self.properties.items():
            xml = '<node><interface name="' + interface + '">' + ''.join(
                '<property name="' + key + '" type="' + value[0] + '" access="read"/>'
                for key, value in values.items()) + '</interface></node>'
            info = Gio.DBusNodeInfo.new_for_xml(xml).interfaces[0]
            self.connection.register_object("/org/mpris/MediaPlayer2", info, None, self.get_property, None)
        self.owner = Gio.bus_own_name_on_connection(self.connection, "org.mpris.MediaPlayer2." + name,
                                                   Gio.BusNameOwnerFlags.NONE, None, None)

    def get_property(self, connection, sender, path, interface, name):
        signature, value = self.properties[interface][name]
        return GLib.Variant(signature, value)

    def state(self, state):
        interface = "org.mpris.MediaPlayer2.Player"
        self.properties[interface]["PlaybackStatus"] = ("s", state)
        self.connection.emit_signal(None, "/org/mpris/MediaPlayer2", "org.freedesktop.DBus.Properties",
            "PropertiesChanged", GLib.Variant("(sa{sv}as)", (interface, {"PlaybackStatus": GLib.Variant("s", state)}, [])))
        return False

alpha = Player("Alpha", "Paused")
beta = Player("Beta", "Playing")
proxy = Player("playerctld", "Playing")

def run_shell():
    result = subprocess.run(["qs", "-p", sys.argv[1]], capture_output=True, text=True, timeout=7)
    print(result.stdout + result.stderr)
    if result.returncode:
        print("ASSERTION_FAILED shell exit", result.returncode)
    GLib.idle_add(loop.quit)

def start():
    threading.Thread(target=run_shell, daemon=True).start()
    return False

GLib.timeout_add(100, start)
GLib.timeout_add(1100, lambda: alpha.state("Playing"))
GLib.timeout_add(1300, lambda: beta.state("Paused"))
GLib.timeout_add(1400, lambda: proxy.state("Paused"))
GLib.timeout_add(2000, lambda: (Gio.bus_unown_name(alpha.owner), False)[1])
loop.run()
'''


@unittest.skipUnless(shutil.which("qs") and shutil.which("dbus-run-session")
                     and importlib.util.find_spec("gi"), "Quickshell, D-Bus and PyGObject are required")
class MprisTests(unittest.TestCase):
    def test_selection_filtering_and_player_removal(self):
        with tempfile.TemporaryDirectory(prefix="mpris-", dir=os.environ.get("TMPDIR")) as directory:
            root = Path(directory)
            common = root / "modules/common"
            common.mkdir(parents=True)
            services = root / "services"
            services.mkdir()
            shutil.copy(REPOSITORY / "services/MprisController.qml", services)
            (common / "Config.qml").write_text('''pragma Singleton
import Quickshell
Singleton { property var options: ({ media: { filterDuplicatePlayers: true } }) }
''')
            (services / "Translation.qml").write_text('''pragma Singleton
import Quickshell
Singleton { function tr(text) { return text; } }
''')
            (root / "shell.qml").write_text('''import QtQuick
import Quickshell
import "services"
ShellRoot {
    function check(condition, message) {
        if (!condition) console.error("ASSERTION_FAILED", message);
    }
    Component.onCompleted: console.log("MPRIS_INIT", MprisController.players.length)
    Timer {
        interval: 600; running: true
        onTriggered: {
            check(MprisController.players.length === 2, "proxy filtered");
            check(MprisController.activePlayer?.identity === "Beta", "playing player preferred");
            const alpha = MprisController.players.find(player => player.identity === "Alpha");
            const beta = MprisController.players.find(player => player.identity === "Beta");
            MprisController.setActivePlayer(alpha);
            check(MprisController.activePlayer === alpha, "manual selection");
            MprisController.setActivePlayer(beta);
        }
    }
    Timer {
        interval: 1700; running: true
        onTriggered: check(MprisController.activePlayer?.identity === "Alpha", "pausing other players does not steal selection")
    }
    Timer {
        interval: 2700; running: true
        onTriggered: {
            check(MprisController.players.length === 1, "closed player removed");
            check(MprisController.activePlayer?.identity === "Beta", "remaining real player selected");
            MprisController.setActivePlayer(null);
            check(MprisController.activePlayer?.identity === "Beta", "null selection uses list fallback");
            console.log("MPRIS_TEST_DONE");
            Qt.quit();
        }
    }
}
''')
            result = subprocess.run(["dbus-run-session", "--", "python3", "-c", SERVER, str(root)],
                                    capture_output=True, text=True, timeout=10,
                                    env=dict(os.environ, QT_QPA_PLATFORM="offscreen"))
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertIn("MPRIS_TEST_DONE", output)
            for error in ("ASSERTION_FAILED", "TypeError", "ReferenceError", "Traceback"):
                self.assertNotIn(error, output)


if __name__ == "__main__":
    unittest.main()
