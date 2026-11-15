#!/usr/bin/env python3
import fcntl
import glob
import os
import struct
import subprocess
import sys
import time

UI_SET_EVBIT = 0x40045564
UI_SET_KEYBIT = 0x40045565
UI_DEV_CREATE = 0x5501
UI_DEV_DESTROY = 0x5502
UI_DEV_SETUP = 0x405c5503
EV_KEY = 0x01
EV_SYN = 0x00
SYN_REPORT = 0x00
KEY_CAPSLOCK = 58
KEY_NUMLOCK = 69


def read_sysfs(kind):
    for path in glob.glob(f"/sys/class/leds/*::{kind}lock/brightness"):
        try:
            with open(path) as f:
                return 1 if int(f.read().strip() or "0") > 0 else 0
        except (OSError, ValueError):
            continue
    return None


def toggle_via_uinput(code):
    fd = os.open("/dev/uinput", os.O_WRONLY | os.O_NONBLOCK)
    try:
        fcntl.ioctl(fd, UI_SET_EVBIT, EV_KEY)
        fcntl.ioctl(fd, UI_SET_KEYBIT, code)
        setup_data = struct.pack("HHHH80sI", 0x03, 0x1234, 0x5678, 1, b"qs-toggle", 0)
        fcntl.ioctl(fd, UI_DEV_SETUP, setup_data)
        fcntl.ioctl(fd, UI_DEV_CREATE)
        time.sleep(0.1)

        ev_press = struct.pack("llHHi", 0, 0, EV_KEY, code, 1)
        ev_syn = struct.pack("llHHi", 0, 0, EV_SYN, SYN_REPORT, 0)
        os.write(fd, ev_press)
        os.write(fd, ev_syn)

        time.sleep(0.02)

        ev_release = struct.pack("llHHi", 0, 0, EV_KEY, code, 0)
        os.write(fd, ev_release)
        os.write(fd, ev_syn)

        time.sleep(0.03)
        fcntl.ioctl(fd, UI_DEV_DESTROY)
    finally:
        os.close(fd)


def toggle_via_wtype(key_name):
    subprocess.run(["wtype", "-k", key_name], check=True)


def main():
    kind = "caps" if len(sys.argv) > 1 and sys.argv[1] == "caps" else "num"
    code = KEY_CAPSLOCK if kind == "caps" else KEY_NUMLOCK
    key_name = "Caps_Lock" if kind == "caps" else "Num_Lock"

    try:
        toggle_via_uinput(code)
    except OSError:
        try:
            toggle_via_wtype(key_name)
        except (OSError, subprocess.SubprocessError):
            pass

    time.sleep(0.02)
    state = read_sysfs(kind)
    if state is not None:
        print(state, flush=True)
    else:
        print(0, flush=True)


if __name__ == "__main__":
    main()
