#!/usr/bin/env python3
"""Track active niri usage with private, atomic daily history."""

import argparse
import datetime as dt
import fcntl
import json
import math
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time


RETENTION_DAYS = 92
INTERVAL = 2


def seconds(value):
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value) or value < 0:
        raise ValueError("invalid usage duration")
    return float(value)


def prune(days, today):
    cutoff = (today - dt.timedelta(days=RETENTION_DAYS - 1)).isoformat()
    return {date: day for date, day in days.items() if cutoff <= date <= today.isoformat()}


def load_history(path, today, legacy=None):
    if path.exists():
        with path.open() as source:
            data = json.load(source)
        if isinstance(data, dict) and data.get("version", 1) != 1:
            raise ValueError("unsupported screen time history version")
        entries = data.get("days") if isinstance(data, dict) else data
        if not isinstance(entries, list):
            raise ValueError("invalid screen time history")
        days = {}
        for entry in entries:
            if not isinstance(entry, dict) or not isinstance(entry.get("hours", {}), dict):
                raise ValueError("invalid screen time day")
            date = dt.date.fromisoformat(entry["date"]).isoformat()
            if date in days or not isinstance(entry.get("apps"), dict):
                raise ValueError("invalid screen time day")
            days[date] = {"date": date, "active": seconds(entry["active"]),
                "apps": {app: seconds(value) for app, value in entry["apps"].items()},
                "hours": {hour: seconds(value) for hour, value in entry.get("hours", {}).items()}}
        return prune(days, today)
    days = {}
    if legacy and legacy.exists():
        try:
            with legacy.open() as source:
                old = json.load(source)
            boot = dt.datetime.fromtimestamp(old["btime"]).date()
            # A per-boot aggregate spanning several days cannot be assigned to today.
            if boot == today:
                date = today.isoformat()
                days[date] = {"date": date, "active": seconds(old["total_screentime"]),
                    "apps": {app: seconds(value) for app, value in old.get("apps", {}).items()},
                    "hours": {hour: seconds(value) for hour, value in old.get("hourly_usage", {}).items()}}
        except (OSError, ValueError, KeyError, TypeError, AttributeError, OverflowError):
            pass
    return days


def record_usage(days, start, end, app_id):
    while start < end:
        moment = dt.datetime.fromtimestamp(start)
        boundary = moment.replace(minute=0, second=0, microsecond=0) + dt.timedelta(hours=1)
        stop = min(end, boundary.timestamp())
        if stop <= start:
            stop = end
        elapsed = stop - start
        date = moment.date().isoformat()
        day = days.setdefault(date, {"date": date, "active": 0, "apps": {}, "hours": {}})
        day["active"] += elapsed
        hour = str(moment.hour)
        day["hours"][hour] = day["hours"].get(hour, 0) + elapsed
        if app_id:
            day["apps"][app_id] = day["apps"].get(app_id, 0) + elapsed
        start = stop


def save_history(path, days):
    fd, temporary = tempfile.mkstemp(prefix=".screentime-", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as output:
            json.dump({"version": 1, "days": [days[date] for date in sorted(days)]}, output)
            output.flush()
            os.fsync(output.fileno())
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def reached_limits(day, options, alerted):
    limits = options.get("appLimits", {})
    if not isinstance(limits, dict):
        limits = {}
    candidates = [("daily", "", day["active"], options.get("dailyLimit", 0))]
    candidates += [("app", app, used, limits.get(app, 0)) for app, used in day["apps"].items()]
    events = []
    for kind, app, used, minutes in candidates:
        if isinstance(minutes, bool) or not isinstance(minutes, (int, float)) or not math.isfinite(minutes) or minutes <= 0:
            continue
        key = (day["date"], kind, app)
        if used >= minutes * 60 and key not in alerted:
            alerted.add(key)
            events.append({"kind": kind, "appId": app, "used": used})
    return events


def focused_app():
    try:
        result = subprocess.run(["niri", "msg", "-j", "focused-window"],
            capture_output=True, text=True, timeout=1, check=True)
        window = json.loads(result.stdout)
        return (window.get("app_id") or "") if isinstance(window, dict) else ""
    except (OSError, ValueError, subprocess.SubprocessError):
        return None


def session_active():
    session = os.environ.get("XDG_SESSION_ID")
    if not session:
        return True
    try:
        result = subprocess.run(["loginctl", "show-session", session, "-p", "LockedHint", "-p", "IdleHint"],
            capture_output=True, text=True, timeout=1, check=True)
        return "LockedHint=yes" not in result.stdout and "IdleHint=yes" not in result.stdout
    except (OSError, subprocess.SubprocessError):
        return True


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--state-stdin", action="store_true")
    args = parser.parse_args()
    config = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))) / "qssettings"
    cache = Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache")))
    config.mkdir(parents=True, exist_ok=True)
    path = config / "screentime.json"
    lock = (config / ".screentime.lock").open("a")
    os.chmod(lock.name, 0o600)
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        return 0
    try:
        days = load_history(path, dt.date.today(), cache / "screentime.json")
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(json.dumps({"error": "history", "message": str(error)}), flush=True)
        return 1

    stopping = False

    def stop(_signum, _frame):
        nonlocal stopping
        stopping = True

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    active = not args.state_stdin
    buffer = ""
    if args.state_stdin:
        os.set_blocking(sys.stdin.fileno(), False)
    options = {}
    alerted = set()
    last_config_mtime = None
    last_login_check = -10
    login_active = True
    previous = time.monotonic()
    previous_app = None
    previous_active = False
    last_save = 0
    dirty = not path.exists()
    try:
        while not stopping:
            now = time.monotonic()
            if args.state_stdin:
                try:
                    chunk = os.read(sys.stdin.fileno(), 65536)
                    if not chunk:
                        break
                    buffer += chunk.decode("utf-8")
                    while "\n" in buffer:
                        line, buffer = buffer.split("\n", 1)
                        try:
                            state = json.loads(line)
                            active = state.get("active") is True
                        except (ValueError, AttributeError):
                            active = False
                except BlockingIOError:
                    pass
            try:
                settings = config / "config.json"
                mtime = settings.stat().st_mtime_ns
                if mtime != last_config_mtime:
                    with settings.open() as source:
                        loaded = json.load(source).get("wellbeing", {})
                    options = loaded if isinstance(loaded, dict) else {}
                    last_config_mtime = mtime
            except (OSError, ValueError, AttributeError):
                pass
            if now - last_login_check >= 10:
                login_active = session_active()
                last_login_check = now
            app = focused_app() if active and login_active else None
            if previous_active and active and login_active and app is not None:
                elapsed = min(max(0, now - previous), INTERVAL * 2)
                end = time.time()
                record_usage(days, end - elapsed, end, previous_app)
                dirty = True
            previous, previous_app = now, app
            previous_active = active and login_active and app is not None
            today = dt.date.today()
            pruned = prune(days, today)
            dirty = dirty or len(pruned) != len(days)
            days = pruned
            day = days.get(today.isoformat())
            if day:
                for event in reached_limits(day, options, alerted):
                    print(json.dumps({"limit": event}), flush=True)
            if dirty and now - last_save >= 10:
                save_history(path, days)
                dirty = False
                last_save = now
            time.sleep(INTERVAL)
        if dirty:
            save_history(path, days)
    except OSError as error:
        print(json.dumps({"error": "write", "message": str(error)}), flush=True)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
