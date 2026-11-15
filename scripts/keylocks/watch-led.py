#!/usr/bin/env python3
import glob
import os
import select
import struct
import sys
import time

EV_LED = 0x11
LED_NUML = 0x00
LED_CAPSL = 0x01

# native struct input_event: timeval (2 longs) + type + code + value
_EVENT_FORMAT = "@llHHi"
_EVENT_SIZE = struct.calcsize(_EVENT_FORMAT)


def emit(name, value):
    print(f"{name} {value}", flush=True)


def read_sysfs(kind):
    for path in glob.glob(f"/sys/class/leds/*::{kind}/brightness"):
        try:
            with open(path) as f:
                return 1 if int(f.read().strip() or "0") > 0 else 0
        except (OSError, ValueError):
            continue
    return None


def led_capable_event_paths():
    paths = []
    try:
        with open("/proc/bus/input/devices") as f:
            blocks = f.read().split("\n\n")
    except OSError:
        return paths
    for block in blocks:
        handlers = ""
        led_mask = 0
        for line in block.splitlines():
            if line.startswith("H: Handlers="):
                handlers = line
            elif line.startswith("B: LED="):
                try:
                    led_mask = int(line.split("=", 1)[1].split()[0], 16)
                except (ValueError, IndexError):
                    led_mask = 0
        if not (led_mask & ((1 << LED_NUML) | (1 << LED_CAPSL))):
            continue
        for token in handlers.split():
            if token.startswith("event"):
                paths.append(f"/dev/input/{token}")
    return paths


def poll_sysfs_fallback(last_caps, last_num, ppid):
    # Fall back to polling sysfs if evdev nodes under /dev/input are unreadable.
    while True:
        if os.getppid() != ppid:
            return 0
        time.sleep(0.06)
        caps = read_sysfs("capslock")
        num = read_sysfs("numlock")
        if caps is not None and caps != last_caps:
            last_caps = caps
            emit("caps", caps)
        if num is not None and num != last_num:
            last_num = num
            emit("num", num)


def main():
    caps = read_sysfs("capslock")
    num = read_sysfs("numlock")
    if caps is not None:
        emit("caps", caps)
    if num is not None:
        emit("num", num)
    # Sentinel: lines before this are the startup snapshot; lines after are live changes.
    print("ready", flush=True)

    ppid = os.getppid()
    fds = {}
    for path in led_capable_event_paths():
        try:
            fds[os.open(path, os.O_RDONLY)] = path
        except OSError:
            continue

    if not fds:
        return poll_sysfs_fallback(caps, num, ppid)

    poller = select.poll()
    for fd in fds:
        poller.register(fd, select.POLLIN)

    while True:
        events = poller.poll(5000)
        if os.getppid() != ppid:
            return 0
        for fd, _ in events:
            try:
                data = os.read(fd, _EVENT_SIZE * 64)
            except OSError:
                poller.unregister(fd)
                os.close(fd)
                del fds[fd]
                continue
            for i in range(0, len(data) - _EVENT_SIZE + 1, _EVENT_SIZE):
                _, _, etype, code, value = struct.unpack(
                    _EVENT_FORMAT, data[i:i + _EVENT_SIZE]
                )
                if etype != EV_LED:
                    continue
                if code == LED_CAPSL:
                    emit("caps", 1 if value else 0)
                elif code == LED_NUML:
                    emit("num", 1 if value else 0)
        if not fds:
            return poll_sysfs_fallback(caps, num, ppid)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        pass
