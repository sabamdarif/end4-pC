#!/usr/bin/env python3
"""Read niri shortcuts, preserving actions, properties and include order."""

import argparse
import glob
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile


SPEC = importlib.util.spec_from_file_location("niri_settings", Path(__file__).with_name("config-settings.py"))
KDL = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = KDL
SPEC.loader.exec_module(KDL)
KEY_RE = re.compile(r"^[A-Za-z0-9_]+(\+[A-Za-z0-9_]+)*$")


def parse_file(path, binds, visited, stack=(), state=None):
    path = Path(path).resolve()
    if path in stack or len(stack) >= 10:
        raise ValueError(f"Recursive or too deeply nested include: {path}")
    visited.add(str(path))
    for node in KDL.parse(path.read_text()):
        name = KDL.scalar(node.name)
        if name == "include":
            include = node.argument()
            if not isinstance(include, str):
                raise ValueError(f"Invalid include in {path}")
            pattern = os.path.expanduser(include)
            if not os.path.isabs(pattern):
                pattern = str(path.parent / pattern)
            matches = sorted(glob.glob(pattern))
            if not glob.has_magic(pattern):
                visited.add(str(Path(pattern).resolve()))
            if not matches and node.property("optional", False) is not True:
                raise FileNotFoundError(pattern)
            for included in matches:
                parse_file(included, binds, visited, (*stack, path), state)
            continue
        if name == "input" and state is not None:
            mod = KDL.find(node.children or [], "mod-key")
            if mod is not None:
                state["modKey"] = mod.argument("Super")
        if name != "binds":
            continue
        for bind in node.children or []:
            key = KDL.scalar(bind.name)
            if not isinstance(key, str) or not KEY_RE.fullmatch(key):
                continue
            properties = {}
            for index in range(len(bind.entries) - 2):
                if bind.entries[index + 1] == "=":
                    properties[KDL.scalar(bind.entries[index])] = KDL.scalar(bind.entries[index + 2])
            action = "".join(child.render() for child in bind.children or []).strip()
            title = properties.pop("hotkey-overlay-title", "")
            binds.append({"key": key, "action": action, "title": title or action.split("\n")[0] or key,
                          "source": str(path), "properties": properties})


def read_binds(config):
    config = Path(config).expanduser()
    binds, visited = [], set()
    state = {"modKey": "Super"}
    parse_file(config, binds, visited, state=state)
    overrides = config.parent / "qssettings/binds.kdl"
    included = str(overrides.resolve()) in visited
    if not included and overrides.is_file():
        parse_file(overrides, binds, visited)
    return {"binds": binds, "included": included, "modKey": state["modKey"]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--path", default=os.path.join(os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config")), "niri/config.kdl"))
    parser.add_argument("--validate", action="store_true")
    args = parser.parse_args()
    try:
        if args.validate:
            candidate = json.load(sys.stdin)
            validate_binds(candidate["kdl"], candidate["actions"])
            return 0
        print(json.dumps(read_binds(args.path)))
    except (OSError, ValueError, IndexError, KeyError, TypeError, subprocess.SubprocessError) as error:
        print(f"list-binds: {error}", file=sys.stderr)
        return 1
    return 0


def validate_binds(text, actions=None):
    for action in actions or []:
        if len(KDL.parse(action)) != 1:
            raise ValueError("Each shortcut needs exactly one action")
    nodes = KDL.parse(text)
    if len(nodes) != 1 or KDL.scalar(nodes[0].name) != "binds" or nodes[0].entries or nodes[0].children is None:
        raise ValueError("Only a binds block is allowed")
    for bind in nodes[0].children:
        if not KEY_RE.fullmatch(str(KDL.scalar(bind.name))) or len(bind.children or []) != 1:
            raise ValueError("Each shortcut needs one key and one action")
    with tempfile.NamedTemporaryFile(mode="w", suffix=".kdl", encoding="utf-8") as candidate:
        candidate.write(text)
        candidate.flush()
        result = subprocess.run(["niri", "validate", "-c", candidate.name], capture_output=True, text=True, timeout=10)
        if result.returncode:
            raise ValueError(re.sub(r"\x1b\[[0-9;]*m", "", result.stderr).strip())


if __name__ == "__main__":
    sys.exit(main())
