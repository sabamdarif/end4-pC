#!/usr/bin/env python3
"""Discover block disks and MTP phones, with optional SMART diagnostics."""

import argparse
import json
import os
import re
import subprocess


def mount_points(path="/proc/self/mounts"):
    mounts = {}
    with open(path) as source:
        for line in source:
            fields = line.split()
            if len(fields) < 2:
                continue
            device, mount = (re.sub(r"\\([0-7]{3})", lambda m: chr(int(m[1], 8)), value) for value in fields[:2])
            mounts.setdefault(os.path.realpath(device), []).append(mount)
    return mounts


def usage(mount):
    try:
        stat = os.statvfs(mount)
        total = stat.f_blocks * stat.f_frsize
        used = (stat.f_blocks - stat.f_bfree) * stat.f_frsize
        free = stat.f_bavail * stat.f_frsize
        return {"total": total, "used": used, "free": free, "usage": used / total if total else 0}
    except OSError:
        return {"total": None, "used": None, "free": None, "usage": 0}


def parse_drives(data, mounts):
    drives = []
    for disk in data.get("blockdevices", []):
        if disk.get("type") != "disk":
            continue
        if re.fullmatch(r"(?:zram|ram)\d+", disk.get("name", "")):
            continue
        device = disk.get("path")
        if not isinstance(device, str) or not device.startswith("/dev/"):
            continue
        removable = bool(disk.get("rm") or disk.get("hotplug") or disk.get("tran") == "usb")
        partitions = []

        def walk(node):
            path = node.get("path", "")
            fallback = node.get("mountpoint") or ""
            points = mounts.get(os.path.realpath(path), []) or ([fallback] if fallback.startswith("/") else [])
            if path and (node.get("type") == "part" or node.get("fstype") or points):
                mount = points[0] if points else ""
                partitions.append({"device": path, "label": node.get("label") or node.get("name") or path,
                    "size": int(node.get("size") or 0), "filesystem": node.get("fstype") or "",
                    "mountPoint": mount, "mountPoints": points, "readOnly": bool(node.get("ro")),
                    **(usage(mount) if mount else {"total": None, "used": None, "free": None, "usage": 0})})
            for child in node.get("children", []):
                walk(child)

        walk(disk)
        drives.append({"device": device, "name": disk.get("name") or device,
            "model": (disk.get("model") or "").strip(), "size": int(disk.get("size") or 0),
            "bus": (disk.get("tran") or "").upper(), "removable": removable,
            "rotational": bool(disk.get("rota")), "partitions": partitions})
    return {"allDrives": drives, "removableDrives": [disk for disk in drives if disk["removable"]]}


def discover():
    result = subprocess.run(["lsblk", "-J", "-b", "-o",
        "NAME,PATH,SIZE,TYPE,MOUNTPOINT,FSTYPE,LABEL,MODEL,HOTPLUG,RM,RO,ROTA,STATE,TRAN"],
        capture_output=True, text=True, timeout=10, check=True)
    data = parse_drives(json.loads(result.stdout), mount_points())
    phones = discover_mtp()
    data["allDrives"].extend(phones)
    data["removableDrives"].extend(phones)
    return data


def parse_mtp(volumes, mounts):
    devices = {}
    for volume in volumes:
        root = volume.get_activation_root()
        if root and root.get_uri().startswith("mtp://"):
            devices[root.get_uri()] = (volume.get_name(), volume.get_mount())
    for mount in mounts:
        uri = mount.get_root().get_uri()
        if uri.startswith("mtp://"):
            name = devices[uri][0] if uri in devices else mount.get_name()
            # GVfs can expose the mount before the volume's get_mount() catches up.
            devices[uri] = (name, mount)
    phones = []
    for uri, (name, mount) in devices.items():
        mount_uri = mount.get_root().get_uri() if mount else ""
        phones.append({"device": uri, "kind": "mtp", "name": name, "model": name,
            "size": None, "bus": "MTP", "removable": True, "rotational": False,
            "partitions": [{"device": uri, "kind": "mtp", "label": name, "size": None,
                "filesystem": "MTP", "mountPoint": mount_uri,
                "mountPoints": [mount_uri] if mount_uri else [], "readOnly": False,
                "total": None, "used": None, "free": None, "usage": 0}]})
    return phones


def discover_mtp():
    try:
        import gi
        gi.require_version("Gio", "2.0")
        from gi.repository import Gio
    except (ImportError, ValueError):
        return []
    monitor = Gio.VolumeMonitor.get()
    return parse_mtp(monitor.get_volumes(), monitor.get_mounts())


def parse_smart(data):
    health = data.get("smart_status", {}).get("passed")
    nvme = data.get("nvme_smart_health_information_log", {})
    temperature = data.get("temperature", {}).get("current", nvme.get("temperature"))
    hours = data.get("power_on_time", {}).get("hours", nvme.get("power_on_hours"))
    wear = nvme.get("percentage_used")
    for attribute in data.get("ata_smart_attributes", {}).get("table", []):
        if attribute.get("id") == 9 and hours is None:
            hours = attribute.get("raw", {}).get("value")
        if attribute.get("id") in (190, 194) and temperature is None:
            temperature = attribute.get("raw", {}).get("value")
        if attribute.get("name", "").lower() in ("percent_lifetime_remain", "media_wearout_indicator") and wear is None:
            wear = max(0, 100 - attribute.get("value", 100))
    critical = health is False or bool(nvme.get("critical_warning"))
    warning = (wear is not None and wear >= 80) or (temperature is not None and temperature >= 60)
    status = "critical" if critical else "warning" if warning else "ok" if health is True else "unknown"
    return {"status": status, "temperature": temperature, "wear": wear, "powerOnHours": hours}


def smart(device):
    if not device.startswith("/dev/") or not any(disk["device"] == device for disk in discover()["allDrives"]):
        raise ValueError("unknown-device")
    result = subprocess.run(["smartctl", "-j", "-H", "-A", device], capture_output=True, text=True, timeout=20)
    data = json.loads(result.stdout)
    # SMART's high exit bits report failing health, not a failed command.
    if result.returncode & 7:
        raise ValueError("smart-unavailable")
    return dict(parse_smart(data), device=device)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--smart", metavar="DEVICE")
    args = parser.parse_args()
    try:
        result = smart(args.smart) if args.smart else discover()
    except FileNotFoundError:
        result = {"error": "missing-tool"}
    except ValueError as error:
        result = {"error": str(error) if str(error) in ("unknown-device", "smart-unavailable") else "invalid-data"}
    except (OSError, subprocess.SubprocessError):
        result = {"error": "operation-failed"}
    print(json.dumps(result))
    return int("error" in result)


if __name__ == "__main__":
    raise SystemExit(main())
