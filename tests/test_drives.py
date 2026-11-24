import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import shutil

from ui_test_utils import qml_block, run_qml

spec = importlib.util.spec_from_file_location("drives_info", Path(__file__).resolve().parents[1] / "scripts/system/drives_info.py")
drives = importlib.util.module_from_spec(spec)
spec.loader.exec_module(drives)


class DriveInfoTests(unittest.TestCase):
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
