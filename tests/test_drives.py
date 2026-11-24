import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import Mock, patch
import shutil

from ui_test_utils import qml_block, run_qml

spec = importlib.util.spec_from_file_location("drives_info", Path(__file__).resolve().parents[1] / "scripts/system/drives_info.py")
drives = importlib.util.module_from_spec(spec)
spec.loader.exec_module(drives)


class DriveInfoTests(unittest.TestCase):
    def test_mtp_discovery_keeps_mounted_and_unmounted_phones_without_duplicates(self):
        mounted_uri = "mtp://Phone_A/"
        unmounted_uri = "mtp://Phone_B/"
        mount = Mock()
        mount.get_root.return_value.get_uri.return_value = mounted_uri
        mount.get_name.return_value = "mtp"
        volumes = []
        for name, uri, connection in (("Phone A", mounted_uri, mount), ("Phone B", unmounted_uri, None)):
            volume = Mock()
            volume.get_activation_root.return_value.get_uri.return_value = uri
            volume.get_name.return_value = name
            volume.get_mount.return_value = connection
            volumes.append(volume)
        remote = Mock()
        remote.get_root.return_value.get_uri.return_value = "smb://server/share/"
        phones = drives.parse_mtp(volumes, [mount, remote])
        self.assertEqual(len(phones), 2)
        self.assertEqual(phones[0]["name"], "Phone A")
        self.assertEqual(phones[0]["partitions"][0]["mountPoint"], mounted_uri)
        self.assertEqual(phones[1]["partitions"][0]["mountPoint"], "")
        self.assertTrue(phones[1]["removable"])
        self.assertIsNone(phones[0]["size"])
        self.assertIsNone(phones[0]["partitions"][0]["total"])

    def test_mtp_mounts_without_volume_metadata_are_discovered(self):
        mount = Mock()
        mount.get_root.return_value.get_uri.return_value = "mtp://Phone_A/"
        mount.get_name.return_value = "Phone A"
        phones = drives.parse_mtp([], [mount])
        self.assertEqual(phones[0]["device"], "mtp://Phone_A/")

    def test_smart_never_runs_for_mtp_devices(self):
        with patch.object(drives, "discover", return_value={"allDrives": [{"device": "mtp://Phone_A/"}]}), patch.object(drives.subprocess, "run") as run:
            with self.assertRaisesRegex(ValueError, "unknown-device"):
                drives.smart("mtp://Phone_A/")
            run.assert_not_called()

    def test_discovery_classifies_nested_partitions_and_whole_disks(self):
        data = {"blockdevices": [
            {"name": "sda", "type": "disk", "path": "/dev/sda", "size": 1000, "tran": "usb", "children": [
                {"name": "sda1", "type": "part", "path": "/dev/sda1", "size": 800, "fstype": "ext4", "label": "Work"}]},
            {"name": "nvme0n1", "type": "disk", "path": "/dev/nvme0n1", "size": 2000, "tran": "nvme", "fstype": "btrfs"},
            {"name": "zram0", "type": "disk", "path": "/dev/zram0", "fstype": "swap"},
            {"name": "loop0", "type": "loop"}]}
        with patch.object(drives, "usage", return_value={"used": 100, "free": 700, "total": 800, "usage": 0.125}):
            result = drives.parse_drives(data, {"/dev/sda1": ["/media/My Disk"]})
        self.assertEqual(len(result["allDrives"]), 2)
        self.assertEqual(len(result["removableDrives"]), 1)
        partition = result["removableDrives"][0]["partitions"][0]
        self.assertEqual(partition["mountPoint"], "/media/My Disk")
        self.assertEqual(partition["usage"], 0.125)
        self.assertEqual(result["allDrives"][1]["partitions"][0]["device"], "/dev/nvme0n1")

    def test_mount_table_unescapes_spaces_and_preserves_multiple_mounts(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "mounts"
            path.write_text('/dev/sda1 /media/My\\040Disk ext4 rw 0 0\n/dev/sda1 /other ext4 rw 0 0\n')
            self.assertEqual(drives.mount_points(path)["/dev/sda1"], ["/media/My Disk", "/other"])

    def test_smart_health_thresholds(self):
        healthy = {"smart_status": {"passed": True}, "nvme_smart_health_information_log":
            {"percentage_used": 12, "temperature": 40, "power_on_hours": 100}}
        self.assertEqual(drives.parse_smart(healthy)["status"], "ok")
        healthy["nvme_smart_health_information_log"]["percentage_used"] = 85
        self.assertEqual(drives.parse_smart(healthy)["status"], "warning")
        healthy["smart_status"]["passed"] = False
        self.assertEqual(drives.parse_smart(healthy)["status"], "critical")
        self.assertEqual(drives.parse_smart({})["status"], "unknown")

    def test_smart_rejects_devices_outside_discovery(self):
        with patch.object(drives, "discover", return_value={"allDrives": []}), patch.object(drives.subprocess, "run") as run:
            with self.assertRaisesRegex(ValueError, "unknown-device"):
                drives.smart("--help")
            run.assert_not_called()

    def test_unreadable_usage_is_not_reported_as_empty(self):
        with patch.object(drives.os, "statvfs", side_effect=PermissionError):
            self.assertIsNone(drives.usage("/unreadable")["used"])


@unittest.skipUnless(shutil.which("qs"), "Quickshell is required")
class DriveActionTests(unittest.TestCase):
    def test_mtp_actions_use_gio_and_never_power_off_the_phone(self):
        actions = qml_block("services/Drives.qml", "    function partition(", "    function openPartition(")
        run_qml(self, '''
        property var allDrives: [{device: "mtp://Phone_A/", kind: "mtp", partitions: [
            {device: "mtp://Phone_A/", kind: "mtp", mountPoint: "", filesystem: "MTP"}]}]
        property var removableDrives: allDrives
        property var actionQueue: []
        property bool busy: false
        property string lastError: ""
        property var executed: []
        function refresh() {}
        QtObject { id: actionProc; function exec(command) { root.executed.push(command); } }
''' + actions + '''
        Component.onCompleted: {
            root.mountPartition("mtp://Phone_A/");
            root.check(root.executed[0].join(" ") === "gio mount mtp://Phone_A/", "unmounted phone connects through GIO");
            root.allDrives[0].partitions[0].mountPoint = "mtp://Phone_A/";
            root.unmountPartition("mtp://Phone_A/");
            root.check(root.executed[1].join(" ") === "gio mount -u mtp://Phone_A/", "phone disconnects through GIO");
            root.ejectDrive("mtp://Phone_A/");
            root.check(root.executed[2].join(" ") === "gio mount -u mtp://Phone_A/", "eject only unmounts the phone");
            root.check(root.actionQueue.length === 0, "no power-off command is queued");
            console.log("UI_TEST_DONE");
        }
''')

    def test_failed_unmount_stops_the_eject_queue(self):
        handler = qml_block("services/Drives.qml", "        onExited: code => {", "    Process {\n        id: smartProc")
        handler = handler[:handler.rfind("    }")]
        run_qml(self, '''
        property var actionQueue: [["udisksctl", "power-off", "-b", "/dev/sda"]]
        property string lastError: ""
        property int refreshes: 0
        property int nextCalls: 0
        function refresh() { root.refreshes++; }
        function runNext() { root.nextCalls++; }
        QtObject { id: actionError; property string text: "device is busy" }
        QtObject { id: translation; function tr(text) { return text; } }
        QtObject {
            id: actionProc
            signal exited(int code)
''' + handler.replace("Translation.tr", "translation.tr") + '''
        }
        Component.onCompleted: {
            actionProc.exited(1);
            root.check(root.actionQueue.length === 0, "a failed unmount drops the pending power-off");
            root.check(root.nextCalls === 0, "no more commands run after failure");
            root.check(root.refreshes === 1, "failure refreshes the device state");
            root.check(root.lastError.includes("device is busy"), "command error reaches the UI");
            actionProc.exited(0);
            root.check(root.nextCalls === 1, "only success advances the queue");
            console.log("UI_TEST_DONE");
        }
''')

    def test_ejection_unmounts_every_volume_and_rejects_internal_drives(self):
        actions = qml_block("services/Drives.qml", "    function partition(", "    function openPartition(")
        run_qml(self, '''
        property var allDrives: [{device: "/dev/sda", partitions: [
            {device: "/dev/sda1", mountPoint: "/media/one"},
            {device: "/dev/sda2", mountPoint: "/media/two"}]}]
        property var removableDrives: allDrives
        property var actionQueue: []
        property bool busy: false
        property string lastError: ""
        property var executed: []
        function refresh() {}
        QtObject { id: actionProc; function exec(command) { root.executed.push(command); } }
''' + actions + '''
        Component.onCompleted: {
            root.ejectDrive("/dev/internal");
            root.check(root.executed.length === 0, "internal device cannot be powered off");
            root.ejectDrive("/dev/sda");
            root.check(root.executed[0].join(" ") === "udisksctl unmount -b /dev/sda1", "first volume unmounts first");
            root.runNext();
            root.check(root.executed[1][3] === "/dev/sda2", "second volume unmounts next");
            root.runNext();
            root.check(root.executed[2][1] === "power-off", "power-off is last");
            root.busy = true;
            root.mountPartition("/dev/sda1");
            root.check(root.executed.length === 3, "busy actions do not overlap");
            console.log("UI_TEST_DONE");
        }
''')
