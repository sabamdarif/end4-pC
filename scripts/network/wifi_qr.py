#!/usr/bin/env python3
"""Share saved personal Wi-Fi profiles without putting secrets in argv."""

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import uuid


def escape(value):
    return "".join("\\" + char if char in '\\;,:"' else char for char in value)


def profile_payload(props):
    if props.get("connection.type") != "802-11-wireless":
        raise ValueError("not-wifi")
    ssid = props.get("802-11-wireless.ssid", "")
    if not ssid:
        raise ValueError("missing-ssid")
    mode = props.get("802-11-wireless-security.key-mgmt", "")
    password = ""
    if mode in ("wpa-psk", "sae"):
        security = "WPA"
        password = props.get("802-11-wireless-security.psk", "")
    elif mode == "none":
        security = "WEP"
        index = props.get("802-11-wireless-security.wep-tx-keyidx", "0")
        if index not in ("0", "1", "2", "3"):
            raise ValueError("missing-secret")
        password = props.get(f"802-11-wireless-security.wep-key{index}", "")
    elif not mode:
        security = "nopass"
    else:
        raise ValueError("unsupported-security")
    if security != "nopass" and password in ("", "<hidden>", "--"):
        raise ValueError("missing-secret")
    hidden = props.get("802-11-wireless.hidden") == "yes"
    payload = f"WIFI:S:{escape(ssid)};T:{security};P:{escape(password)};"
    if hidden:
        payload += "H:true;"
    return payload + ";", {"ssid": ssid, "security": security, "password": password}


def generate(connection_uuid):
    connection_uuid = str(uuid.UUID(connection_uuid))
    runtime = Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"))
    if not runtime.is_dir() or runtime.stat().st_uid != os.getuid() or runtime.stat().st_mode & 0o077:
        raise ValueError("unsafe-runtime")
    result = subprocess.run(
        ["nmcli", "--show-secrets", "--escape", "no", "-t", "connection", "show", "uuid", connection_uuid],
        capture_output=True, text=True, timeout=15, check=True,
    )
    props = dict(line.split(":", 1) for line in result.stdout.splitlines() if ":" in line)
    payload, details = profile_payload(props)
    fd, path = tempfile.mkstemp(prefix=f"wifi-qr-{connection_uuid}-", suffix=".png", dir=runtime)
    os.close(fd)
    try:
        subprocess.run(["qrencode", "-t", "PNG", "-s", "8", "-m", "4", "-o", path],
                       input=payload, text=True, capture_output=True, timeout=10, check=True)
    except Exception:
        os.unlink(path)
        raise
    return dict(details, path=path)


def save_image(source, destination):
    destination = Path(destination).expanduser()
    fd, temporary = tempfile.mkstemp(prefix=".wifi-qr-", dir=destination.parent)
    try:
        with os.fdopen(fd, "wb") as output, open(source, "rb") as image:
            shutil.copyfileobj(image, output)
            output.flush()
            os.fsync(output.fileno())
        os.replace(temporary, destination)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("uuid", nargs="?")
    parser.add_argument("--save", nargs=2, metavar=("SOURCE", "DESTINATION"))
    args = parser.parse_args()
    try:
        if args.save:
            save_image(*args.save)
            result = {"saved": True}
        elif args.uuid:
            result = generate(args.uuid)
        else:
            parser.error("a connection UUID is required")
    except ValueError as error:
        result = {"error": str(error) if str(error) in (
            "not-wifi", "missing-ssid", "missing-secret", "unsupported-security", "unsafe-runtime"
        ) else "invalid-uuid"}
    except FileNotFoundError:
        result = {"error": "missing-tool"}
    except (OSError, subprocess.SubprocessError):
        result = {"error": "operation-failed"}
    print(json.dumps(result))
    return int("error" in result)


if __name__ == "__main__":
    raise SystemExit(main())
