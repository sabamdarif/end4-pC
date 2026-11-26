#!/usr/bin/env python3
"""Read included niri settings and build focused shell overrides without editing user files."""

import argparse
import copy
from dataclasses import dataclass, field
import json
import math
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile


# UI path: (KDL path, default, optional numeric range).
SETTINGS = {
    "layout.gaps": ("layout/gaps", 16.0, (0, 65535)),
    "layout.centerFocusedColumn": ("layout/center-focused-column", "never", None),
    "layout.defaultColumnWidth": ("layout/default-column-width/proportion", 0.5, (0.01, 100)),
    "decoration.rounding": ("window-rule/geometry-corner-radius", 0.0, (0, 65535)),
    "decoration.border.enable": ("layout/border/@enabled", False, None),
    "decoration.border.width": ("layout/border/width", 4.0, (0, 65535)),
    "decoration.focusRing.enable": ("layout/focus-ring/@enabled", True, None),
    "decoration.focusRing.width": ("layout/focus-ring/width", 4.0, (0, 65535)),
    "decoration.shadow.enable": ("layout/shadow/@enabled", False, None),
    "decoration.shadow.softness": ("layout/shadow/softness", 30.0, (0, 1024)),
    "decoration.shadow.spread": ("layout/shadow/spread", 5.0, (-1024, 1024)),
    "decoration.blur.enable": ("blur/@enabled", True, None),
    "decoration.blur.passes": ("blur/passes", 3, (0, 255)),
    "decoration.blur.offset": ("blur/offset", 3.0, (0, 100)),
    "decoration.blur.noise": ("blur/noise", 0.02, (0, 1000)),
    "decoration.blur.saturation": ("blur/saturation", 1.5, (0, 1000)),
    "input.kbLayout": ("input/keyboard/xkb/layout", "", None),
    "input.numlock": ("input/keyboard/numlock", False, None),
    "input.repeatDelay": ("input/keyboard/repeat-delay", 600, (0, 65535)),
    "input.repeatRate": ("input/keyboard/repeat-rate", 25, (0, 255)),
    "input.focusFollowsMouse": ("input/focus-follows-mouse", False, None),
    "input.focusFollowsMouseMaxScroll": ("input/focus-follows-mouse/@max-scroll-amount", "", None),
    "input.touchpad.tap": ("input/touchpad/tap", False, None),
    "input.touchpad.naturalScroll": ("input/touchpad/natural-scroll", False, None),
    "input.touchpad.disableWhileTyping": ("input/touchpad/dwt", False, None),
    "input.touchpad.scrollFactor": ("input/touchpad/scroll-factor", 1.0, (0, 100)),
    "input.touchpad.accelSpeed": ("input/touchpad/accel-speed", 0.0, (-1, 1)),
    "input.mouse.naturalScroll": ("input/mouse/natural-scroll", False, None),
    "input.mouse.accelSpeed": ("input/mouse/accel-speed", 0.0, (-1, 1)),
    "animations.enable": ("animations/@enabled", True, None),
    "animations.slowdown": ("animations/slowdown", 1.0, (0, 100)),
    "cursor.theme": ("cursor/xcursor-theme", "default", None),
    "cursor.size": ("cursor/xcursor-size", 24, (1, 255)),
    "cursor.hideWhenTyping": ("cursor/hide-when-typing", False, None),
}
COPIED_SECTIONS = {"input/touchpad", "input/mouse", "input/keyboard/xkb"}
REPLACED = COPIED_SECTIONS | {"layout/default-column-width"}
TOKEN = re.compile(r'r(?P<hashes>\#*)".*?"(?P=hashes)|"(?:\\.|[^"\\])*"|/-|[{};=\n]|[^\s{};="\\]+', re.S)


def tokens(text):
    position = 0
    while position < len(text):
        if text.startswith("//", position):
            end = text.find("\n", position)
            position = len(text) if end < 0 else end
        elif text.startswith("/*", position):
            depth = 1
            position += 2
            while depth and position < len(text):
                if text.startswith("/*", position):
                    depth += 1
                    position += 2
                elif text.startswith("*/", position):
                    depth -= 1
                    position += 2
                else:
                    position += 1
            if depth:
                raise ValueError("Unterminated block comment")
        elif text[position] == "\\":
            match = re.match(r'\\[^\S\n]*(?://[^\n]*)?\n', text[position:])
            if not match:
                raise ValueError("Invalid line continuation")
            position += match.end()
        elif text[position].isspace() and text[position] != "\n":
            position += 1
        else:
            match = TOKEN.match(text, position)
            if not match:
                raise ValueError("Invalid KDL token")
            yield match.group()
            position = match.end()


def scalar(token):
    if token.startswith('r') and re.match(r'r\#*"', token):
        start = token.index('"')
        return token[start + 1:len(token) - start]
    if token.startswith('"'):
        token = re.sub(r'\\u\{([0-9a-fA-F]+)\}', lambda m: json.dumps(chr(int(m[1], 16)))[1:-1], token)
        return json.loads(token)
    if token in ("true", "#true", "false", "#false"):
        return token in ("true", "#true")
    if token in ("null", "#null"):
        return None
    try:
        return float(token.replace("_", ""))
    except ValueError:
        return token


@dataclass
class Node:
    name: str
    entries: list = field(default_factory=list)
    children: list | None = None
    source: str = ""

    def argument(self, default=None):
        for index, token in enumerate(self.entries):
            if token != "=" and (index == 0 or self.entries[index - 1] != "=") and (index + 1 == len(self.entries) or self.entries[index + 1] != "="):
                return scalar(token)
        return default

    def property(self, name, default=None):
        for index in range(len(self.entries) - 2):
            if scalar(self.entries[index]) == name and self.entries[index + 1] == "=":
                return scalar(self.entries[index + 2])
        return default

    def render(self, indent=0):
        head = " " * indent + self.name
        if self.entries:
            for index, token in enumerate(self.entries):
                separator = "" if token == "=" or (index and self.entries[index - 1] == "=") else " "
                head += separator + token
        if self.children is None:
            return head + "\n"
        return head + " {\n" + "".join(child.render(indent + 4) for child in self.children) + " " * indent + "}\n"


def parse(text):
    stream = list(tokens(text))
    position = 0

    def nodes(nested=False):
        nonlocal position
        result = []
        while position < len(stream):
            token = stream[position]
            position += 1
            if token in ("\n", ";"):
                continue
            if token == "}":
                if not nested:
                    raise ValueError("Unexpected closing brace")
                return result
            disabled = token == "/-"
            if disabled:
                token = stream[position]
                position += 1
            node = Node(token)
            while position < len(stream) and stream[position] not in ("{", "}", "\n", ";"):
                entry = stream[position]
                position += 1
                if entry == "/-":
                    position += 1
                    if position < len(stream) and stream[position] == "=":
                        position += 2
                else:
                    node.entries.append(entry)
            if position < len(stream) and stream[position] == "{":
                position += 1
                node.children = nodes(True)
            if not disabled:
                result.append(node)
        if nested:
            raise ValueError("Unclosed KDL block")
        return result

    return nodes()


def find(nodes, path):
    node = None
    for name in path.split("/"):
        node = next((n for n in reversed(nodes) if scalar(n.name) == name), None)
        if node is None:
            return None
        nodes = node.children or []
    return node


def replace(nodes, name, node):
    nodes[:] = [n for n in nodes if scalar(n.name) != name]
    if node is not None:
        nodes.append(node)


def merge(target, incoming, prefix=""):
    for node in incoming:
        name = scalar(node.name)
        path = f"{prefix}/{name}".strip("/")
        previous = find(target, name)
        if node.children is not None and previous is not None and path not in REPLACED:
            merge(previous.children, node.children, path)
        else:
            replace(target, name, copy.deepcopy(node))
        current = find(target, name)
        if node.children is not None:
            names = {scalar(child.name) for child in node.children}
            if "on" in names:
                replace(current.children, "off", None)
            elif "off" in names:
                replace(current.children, "on", None)


def load_config(path, files=None, stack=()):
    path = Path(path).absolute()
    real = path.resolve()
    if files is not None:
        files.update((str(path), str(real)))
    if real in stack or len(stack) >= 10:
        raise ValueError(f"Recursive or too deeply nested include: {path}")
    result = []
    for node in parse(path.read_text()):
        node.source = str(real)
        if scalar(node.name) != "include":
            if not stack and scalar(node.name) == "layout":
                border = find(node.children or [], "border")
                if border is not None and not find(border.children or [], "on") and not find(border.children or [], "off"):
                    border.children.append(Node("on"))
            result.append(node)
            continue
        include = node.argument()
        if not isinstance(include, str):
            raise ValueError(f"Invalid include in {path}")
        included = Path(os.path.expanduser(include))
        if not included.is_absolute():
            included = path.parent / included
        try:
            result.extend(load_config(included, files, (*stack, real)))
        except FileNotFoundError:
            if node.property("optional", False) is not True:
                raise
    return result


def effective(nodes):
    merged = []
    for node in nodes:
        name = scalar(node.name)
        if name == "window-rule":
            if any(scalar(child.name) in ("match", "exclude") for child in node.children or []):
                continue
        merge(merged, [node])
    return merged


def values(nodes):
    result = {}
    for key, (path, default, _) in SETTINGS.items():
        parent, _, leaf = path.rpartition("/")
        if leaf.startswith("@"):
            node = find(nodes, parent)
            if leaf == "@enabled":
                children = node.children or [] if node else []
                value = False if find(children, "off") else True if find(children, "on") else default
            else:
                value = node.property(leaf[1:], default) if node else default
        else:
            node = find(nodes, path)
            value = node.argument(True if isinstance(default, bool) else default) if node else default
            if key == "layout.defaultColumnWidth" and node is None and find(nodes, parent) is not None:
                value = -1
        result[key] = value
    return result


def ensure(nodes, path):
    for name in path.split("/"):
        node = find(nodes, name)
        if node is None:
            node = Node(name, children=[])
            nodes.append(node)
        if node.children is None:
            node.children = []
        nodes = node.children
    return nodes


def generate(managed, current, changes):
    managed = copy.deepcopy(managed)
    # Niri replaces these blocks, so a narrow edit must retain their other fields.
    for path in COPIED_SECTIONS:
        if any(SETTINGS[key][0].startswith(path + "/") for key in changes if key in SETTINGS):
            parent, _, name = path.rpartition("/")
            node = find(current, path)
            replace(ensure(managed, parent), name, copy.deepcopy(node) if node else Node(name, children=[]))
    for key, value in changes.items():
        if key not in SETTINGS:
            raise ValueError(f"Unknown setting: {key}")
        path, default, bounds = SETTINGS[key]
        if isinstance(default, bool):
            valid = isinstance(value, bool)
        elif isinstance(default, str):
            valid = isinstance(value, str) and not re.search(r'[\x00-\x08\x0b\x0c\x0e-\x1f]', value)
        else:
            valid = type(value) in (int, float) and math.isfinite(value) and bounds[0] <= value <= bounds[1]
            if isinstance(default, int):
                valid = valid and value == int(value)
        if not valid:
            raise ValueError(f"Invalid value for {key}")
        parent, _, leaf = path.rpartition("/")
        if leaf.startswith("@") and leaf != "@enabled":
            grandparent, _, name = parent.rpartition("/")
            siblings = ensure(managed, grandparent)
            if find(siblings, name) is None:
                siblings.append(copy.deepcopy(find(current, parent)) or Node(name))
            children = []
        else:
            children = ensure(managed, parent)
        if leaf == "@enabled":
            replace(children, "on", None)
            replace(children, "off", None)
            children.append(Node("on" if value else "off"))
        elif leaf.startswith("@"):
            node = find(managed, parent)
            prop = leaf[1:]
            entries = node.entries
            for index in range(len(entries) - 2, -1, -1):
                if scalar(entries[index]) == prop and entries[index + 1] == "=":
                    del entries[index:index + 3]
            if value != "":
                entries.extend([prop, "=", json.dumps(value)])
        elif isinstance(default, bool) and path.startswith(("input/touchpad/", "input/mouse/")):
            replace(children, leaf, Node(leaf) if value else None)
        elif key == "input.focusFollowsMouse":
            if not value and find(current, path) and not find(managed, path):
                raise ValueError("Focus follows mouse must be disabled in its original config file")
            replace(children, leaf, copy.deepcopy(find(managed, path) or find(current, path)) or Node(leaf) if value else None)
        else:
            replace(children, leaf, Node(leaf, [json.dumps(value, ensure_ascii=False)]))
        if key == "layout.defaultColumnWidth":
            replace(children, "fixed", None)
        if key == "decoration.rounding":
            replace(children, "clip-to-geometry", Node("clip-to-geometry", ["true" if value > 0 else "false"]))
    return "".join(node.render() for node in managed)


def validate(path):
    result = subprocess.run(["niri", "validate", "-c", str(path)], capture_output=True, text=True)
    if result.returncode:
        raise ValueError(re.sub(r'\x1b\[[0-9;]*m', '', result.stderr).strip())


def external_window_rules(nodes, managed_dir):
    owned = {str((managed_dir / name).resolve()) for name in ("shell.kdl", "windowrules.kdl")}
    return [{"source": node.source, "kdl": node.render().strip()}
            for node in nodes if scalar(node.name) == "window-rule" and node.source not in owned]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--path", default=os.path.join(os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config")), "niri/config.kdl"))
    parser.add_argument("--generate", action="store_true")
    args = parser.parse_args()
    path = Path(args.path).absolute()
    files = {str(path)}
    try:
        nodes = load_config(path, files) if path.exists() else []
        if path.exists():
            validate(path)
        current = effective(nodes)
        managed_path = path.parent / "qssettings/shell.kdl"
        if args.generate:
            changes = json.load(sys.stdin)
            if not isinstance(changes, dict):
                raise ValueError("Expected a settings object")
            managed = parse(managed_path.read_text()) if managed_path.exists() else []
            kdl = generate(managed, current, changes)
            with tempfile.TemporaryDirectory(prefix="niri-settings-") as directory:
                candidate = Path(directory) / "shell.kdl"
                candidate.write_text(kdl)
                validate(candidate)
            print(kdl, end="")
        else:
            user_nodes = [n for n in nodes if n.source != str(managed_path.resolve()) and scalar(n.name) == "input" and find(n.children or [], "focus-follows-mouse")]
            prefer_no_csd = find(current, "prefer-no-csd")
            column_width = find(current, "layout/default-column-width")
            print(json.dumps({"values": values(current), "files": sorted(files),
                              "focusFollowsMouseOwnedByConfig": bool(user_nodes),
                              "preferNoCsd": prefer_no_csd.argument(True) if prefer_no_csd else False,
                              "defaultColumnWidthKdl": column_width.render().strip() if column_width else "",
                              "windowRules": external_window_rules(nodes, managed_path.parent)}))
    except (OSError, ValueError, IndexError, TypeError) as error:
        if not args.generate:
            print(json.dumps({"files": sorted(files)}))
        print(str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
