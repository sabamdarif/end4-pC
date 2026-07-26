#!/usr/bin/env python3
"""
List niri keybinds as JSON.

Parses a niri config.kdl, follows `include` lines (quoted paths, glob
patterns, relative to the including file's directory, `optional=true`
supported), collects every bind inside `binds { }` sections and prints a
JSON array:

    [{"key": "Mod+Return", "action": "spawn \"ghostty\"",
      "title": "Open Terminal (Ghostty)", "source": "/path/to/file.kdl"}]

- title: hotkey-overlay-title="..." if present, else a cleaned first
  action token (same heuristic as the rofi settings-menu script:
  drop spawn/exec, strip quotes, keep the first word).
- Repeated keys are ALL kept, in file traversal order (includes expanded
  in place). The consumer decides the effective one (in niri the last
  bind for a key wins).
- qssettings/binds.kdl (the settings app's override file) is parsed even
  when its include line is missing from config.kdl, appended last, so
  overrides are always visible.

Usage: list-binds.py [--path ~/.config/niri/config.kdl]
Stdlib only. Read-only: never writes any config file.
"""

import argparse
import glob
import json
import os
import re
import sys

# First token of a bind node: modifiers/key joined with '+'
# (letters, digits, underscore — niri key names never contain '-')
KEY_RE = re.compile(r'^[A-Za-z0-9_]+(\+[A-Za-z0-9_]+)*$')
TITLE_RE = re.compile(r'hotkey-overlay-title="((?:[^"\\]|\\.)*)"')
INCLUDE_RE = re.compile(r'^include\s+(?:optional=(?:true|#true)\s+)?"((?:[^"\\]|\\.)*)"')


def strip_comments(text):
    """Remove // line comments and /* */ block comments (string-aware)."""
    out = []
    i, n = 0, len(text)
    in_string = False
    while i < n:
        c = text[i]
        if in_string:
            out.append(c)
            if c == '\\' and i + 1 < n:
                out.append(text[i + 1])
                i += 2
                continue
            if c == '"':
                in_string = False
            i += 1
        elif c == '"':
            in_string = True
            out.append(c)
            i += 1
        elif text.startswith('//', i):
            while i < n and text[i] != '\n':
                i += 1
        elif text.startswith('/*', i):
            depth = 1
            i += 2
            while i < n and depth:
                if text.startswith('/*', i):
                    depth += 1
                    i += 2
                elif text.startswith('*/', i):
                    depth -= 1
                    i += 2
                else:
                    i += 1
        else:
            out.append(c)
            i += 1
    return ''.join(out)


def split_nodes(body):
    """Split the inside of a KDL block into top-level nodes.

    A node is everything up to and including its balanced { } block,
    or up to a newline/; if it has no block. String-aware.
    """
    nodes = []
    cur = []
    depth = 0
    in_string = False
    i, n = 0, len(body)
    while i < n:
        c = body[i]
        cur.append(c)
        if in_string:
            if c == '\\' and i + 1 < n:
                cur.append(body[i + 1])
                i += 2
                continue
            if c == '"':
                in_string = False
        elif c == '"':
            in_string = True
        elif c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                nodes.append(''.join(cur))
                cur = []
        elif (c == '\n' or c == ';') and depth == 0:
            chunk = ''.join(cur).strip(' \t\n;')
            if chunk:
                nodes.append(chunk)
            cur = []
        i += 1
    tail = ''.join(cur).strip(' \t\n;')
    if tail:
        nodes.append(tail)
    return nodes


def clean_action_title(action):
    """Rofi settings-menu fallback: first meaningful token of the action."""
    a = re.sub(r'\b(spawn-sh|spawn|exec)\b', ' ', action)
    a = a.replace('"', ' ').strip()
    return a.split()[0] if a.split() else action.strip()


def parse_binds_body(body, source, binds):
    for node in split_nodes(body):
        stripped = node.strip()
        if not stripped or stripped.startswith('/-'):
            continue  # node commented out
        head, brace, block = stripped.partition('{')
        head_tokens = head.split()
        if not head_tokens or not KEY_RE.match(head_tokens[0]):
            continue
        key = head_tokens[0]
        m = TITLE_RE.search(head)
        title = m.group(1).replace('\\"', '"') if m else ''
        action = ''
        if brace:
            action = ' '.join(block.rsplit('}', 1)[0].split()).strip(' ;')
        if not title:
            title = clean_action_title(action) if action else key
        binds.append({
            'key': key,
            'action': action,
            'title': title,
            'source': source,
        })


def parse_file(path, binds, visited):
    path = os.path.realpath(path)
    if path in visited or not os.path.isfile(path):
        return
    visited.add(path)
    try:
        with open(path, encoding='utf-8', errors='replace') as f:
            raw = f.read()
    except OSError as e:
        print(f'list-binds: cannot read {path}: {e}', file=sys.stderr)
        return
    text = strip_comments(raw)
    base = os.path.dirname(path)

    # Walk top-level nodes in document order so includes expand in place
    # and "last bind for a key wins" matches what niri actually applies.
    for node in split_nodes(text):
        stripped = node.strip()
        if stripped.startswith('/-'):
            continue  # commented-out node
        m = INCLUDE_RE.match(stripped)
        if m:
            pattern = os.path.expanduser(m.group(1).replace('\\"', '"'))
            if not os.path.isabs(pattern):
                pattern = os.path.join(base, pattern)
            for inc in sorted(glob.glob(pattern)):
                parse_file(inc, binds, visited)
            continue
        head, brace, body = stripped.partition('{')
        if brace and head.split() and head.split()[0] == 'binds':
            parse_binds_body(body.rsplit('}', 1)[0], path, binds)


def main():
    ap = argparse.ArgumentParser(description='List niri keybinds as JSON')
    ap.add_argument('--path',
                    default=os.path.expanduser('~/.config/niri/config.kdl'),
                    help='niri config file (default: ~/.config/niri/config.kdl)')
    args = ap.parse_args()

    binds = []
    visited = set()
    config = os.path.expanduser(args.path)
    parse_file(config, binds, visited)

    # Always include the settings app's override file, even if its include
    # line hasn't been added to config.kdl yet. It's included at the END of
    # config.kdl, so appending keeps "last occurrence wins" correct.
    overrides = os.path.join(os.path.dirname(config), 'qssettings', 'binds.kdl')
    if os.path.realpath(overrides) not in visited:
        parse_file(overrides, binds, visited)

    json.dump(binds, sys.stdout)
    print()


if __name__ == '__main__':
    main()
