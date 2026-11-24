import datetime as dt
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import unittest
from unittest.mock import patch


REPOSITORY = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("tracker", REPOSITORY / "scripts/screentime/screentime_tracker.py")
tracker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tracker)


class ScreenTimeTrackerTests(unittest.TestCase):
    def test_midnight_and_hour_rollover(self):
        start = dt.datetime(2026, 11, 23, 23, 59, 59).timestamp()
        days = {}
        tracker.record_usage(days, start, start + 3, "kitty")
        self.assertEqual(days["2026-11-23"]["active"], 1)
        self.assertEqual(days["2026-11-24"]["apps"], {"kitty": 2})
        self.assertEqual(days["2026-11-24"]["hours"], {"0": 2})

    def test_retention_is_92_calendar_days(self):
        today = dt.date(2026, 11, 24)
        days = {(today - dt.timedelta(days=index)).isoformat(): {} for index in range(100)}
        days[(today + dt.timedelta(days=1)).isoformat()] = {}
        self.assertEqual(len(tracker.prune(days, today)), 92)

    def test_atomic_private_history_roundtrip(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "history.json"
            days = {}
            now = dt.datetime.now().timestamp()
            tracker.record_usage(days, now - 2, now, "kitty")
            tracker.save_history(path, days)
            self.assertEqual(tracker.load_history(path, dt.date.today()), days)
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)
            with patch.object(tracker.os, "replace", side_effect=OSError):
                with self.assertRaises(OSError):
                    tracker.save_history(path, {})
            self.assertEqual(tracker.load_history(path, dt.date.today()), days)
            self.assertEqual(list(Path(directory).iterdir()), [path])

    def test_bad_history_is_not_silently_reset(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "history.json"
            for data in ("broken", '{"days": 3}', json.dumps({"days": [{"date": "2026-11-24", "active": -1, "apps": {}}]})):
                path.write_text(data)
                with self.assertRaises(ValueError):
                    tracker.load_history(path, dt.date.today())
                self.assertEqual(path.read_text(), data)

    def test_limits_notify_once_per_app_per_day_and_session(self):
        day = {"date": "2026-11-24", "active": 3600, "apps": {"kitty": 1800, "code": 100}}
        settings = {"dailyLimit": 60, "appLimits": {"kitty": 30, "code": 30}}
        alerted = set()
        self.assertEqual(len(tracker.reached_limits(day, settings, alerted)), 2)
        self.assertEqual(tracker.reached_limits(day, settings, alerted), [])
        day["date"] = "2026-11-25"
        self.assertEqual(len(tracker.reached_limits(day, settings, alerted)), 2)
        self.assertEqual(tracker.reached_limits(day, {"dailyLimit": "bad", "appLimits": []}, set()), [])

    def test_legacy_import_only_accepts_same_day_boot(self):
        with tempfile.TemporaryDirectory() as directory:
            path, legacy = Path(directory) / "new", Path(directory) / "old"
            today = dt.date.today()
            old = {"btime": dt.datetime.combine(today, dt.time()).timestamp(), "total_screentime": 20, "apps": {"kitty": 20}}
            legacy.write_text(json.dumps(old))
            self.assertEqual(tracker.load_history(path, today, legacy)[today.isoformat()]["active"], 20)
            old["btime"] -= 86400
            legacy.write_text(json.dumps(old))
            self.assertEqual(tracker.load_history(path, today, legacy), {})
            self.assertEqual(json.loads(legacy.read_text()), old)

    def test_daemon_pauses_for_stdin_idle_and_saves_on_shutdown(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config = root / "qssettings"
            config.mkdir()
            (config / "config.json").write_text('{"wellbeing": {"dailyLimit": 0}}')
            binary = root / "niri"
            binary.write_text('#!/bin/sh\necho \'{"app_id":"kitty"}\'\n')
            binary.chmod(0o700)
            env = dict(os.environ, XDG_CONFIG_HOME=str(root), XDG_CACHE_HOME=str(root / "cache"),
                       XDG_SESSION_ID="", PATH=str(root) + os.pathsep + os.environ["PATH"])
            process = subprocess.Popen(["python3", str(REPOSITORY / "scripts/screentime/screentime_tracker.py"), "--state-stdin"],
                stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, env=env)
            try:
                process.stdin.write('{"active":false}\n')
                process.stdin.flush()
                time.sleep(2.2)
                data = json.loads((config / "screentime.json").read_text())
                self.assertEqual(data["days"], [])
                process.stdin.write('{"active":true}\n')
                process.stdin.flush()
                time.sleep(4.2)
                process.terminate()
                stdout, stderr = process.communicate(timeout=5)
                self.assertEqual(process.returncode, 0, stdout + stderr)
                days = json.loads((config / "screentime.json").read_text())["days"]
                self.assertGreater(days[0]["apps"]["kitty"], 0)
                self.assertLess(days[0]["active"], 5)
            finally:
                if process.poll() is None:
                    process.kill()
                    process.communicate()


@unittest.skipUnless(shutil.which("node"), "Node.js is required")
class WellbeingHelpersTests(unittest.TestCase):
    def test_weeks_dates_sparse_months_and_top_apps(self):
        source = (REPOSITORY / "services/Wellbeing.js").read_text().replace(".pragma library", "")
        script = source + '''
const assert = require("node:assert/strict");
const today = new Date(2026, 10, 24);
const days = [{date:"2026-11-24",active:3600,apps:{kitty:1800,code:1800}},
              {date:"2026-10-01",active:3600,apps:{kitty:3600}}];
const week = weekDays(days, today, 1, today);
assert.equal(week.length, 7);
assert.equal(week[0].date, "2026-11-23");
assert.equal(week[1].today, true);
assert.equal(week[2].future, true);
assert.equal(weeksBack(days, today, 1).length, 14);
assert.equal(periodDays(days, today, 1, "month", today).length, 1);
assert.equal(topApps(days)[0].appId, "kitty");
assert.deepEqual(splitDuration(3660), {hours:1,minutes:1});
assert.equal(axis(28801).top, 43200);
assert.equal(dateKey(addDays(new Date(2026, 11, 31), 1)), "2027-01-01");
'''
        result = subprocess.run(["node", "-e", script], capture_output=True, text=True,
                                env=dict(os.environ, TZ="America/New_York"))
        self.assertEqual(result.returncode, 0, result.stderr)
