#!/usr/bin/env python3
"""
List and edit autostart entries that the shell settings app does NOT own.

Two sources:

  niri  — `spawn-at-startup` / `spawn-sh-at-startup` nodes in the user's
          config.kdl and every `include`d file. qssettings/autostart.kdl is
          skipped: that file is generated from NiriConfig.options.autostart
          and already has its own editor in the settings app.
  xdg   — .desktop files in ~/.config/autostart (user) and
          /etc/xdg/autostart + $XDG_CONFIG_DIRS/autostart (system).
          A user file shadows a system file with the same basename.

    list                                  -> {"niri": [...], "xdg": [...]}
    niri-toggle --file F --line N --expect TEXT   comment/uncomment the line
    niri-remove --file F --line N --expect TEXT   delete the line
    xdg-set     --id NAME --enabled 0|1           Hidden= in the user copy
    xdg-remove  --id NAME                         delete user file, or mask

`--expect` is the exact current text of the line and is verified before any
write: line numbers go stale as soon as the file changes on disk.

Stdlib only. Writes are atomic (tmp file + rename).
"""

import argparse
import glob
import json
import os
import re
import shutil
import sys

INCLUDE_RE = re.compile(r'^\s*include\s+(?:optional=(?:true|#true)\s+)?"((?:[^"\\]|\\.)*)"')
SPAWN_RE = re.compile(r'^(\s*)(//\s*|/-\s*)?(spawn-at-startup|spawn-sh-at-startup)\s+(\S.*?)\s*$')
DESKTOP = [d for d in os.environ.get('XDG_CURRENT_DESKTOP', '').split(':') if d]


def user_autostart_dir():
    base = os.environ.get('XDG_CONFIG_HOME') or os.path.expanduser('~/.config')
    return os.path.join(base, 'autostart')


def system_autostart_dirs():
    dirs = os.environ.get('XDG_CONFIG_DIRS') or '/etc/xdg'
    return [os.path.join(d, 'autostart') for d in dirs.split(':') if d]


# ── niri config ──────────────────────────────────────────────────────────

def kdl_files(path, seen):
    """config.kdl + every included file, in include order."""
    path = os.path.realpath(os.path.expanduser(path))
    if path in seen or not os.path.isfile(path):
        return []
    seen.add(path)
    files = [path]
    base = os.path.dirname(path)
    try:
        with open(path, encoding='utf-8', errors='replace') as f:
            lines = f.readlines()
    except OSError as e:
        print(f'autostart-entries: cannot read {path}: {e}', file=sys.stderr)
        return files
    # ponytail: line-based include scan. Misses includes written inside a
    # /* */ block comment or after a `;` — neither happens in real configs.
    for line in lines:
        stripped = line.lstrip()
        if stripped.startswith('//') or stripped.startswith('/-'):
            continue
        m = INCLUDE_RE.match(line)
        if not m:
            continue
        pattern = os.path.expanduser(m.group(1).replace('\\"', '"'))
        if not os.path.isabs(pattern):
            pattern = os.path.join(base, pattern)
        for inc in sorted(glob.glob(pattern)):
            files += kdl_files(inc, seen)
    return files


def list_niri(config):
    owned = os.path.realpath(os.path.join(
        os.path.dirname(os.path.realpath(os.path.expanduser(config))),
        'qssettings', 'autostart.kdl'))
    entries = []
    for path in kdl_files(config, set()):
        if os.path.realpath(path) == owned:
            continue
        with open(path, encoding='utf-8', errors='replace') as f:
            for n, line in enumerate(f, start=1):
                m = SPAWN_RE.match(line.rstrip('\n'))
                if not m:
                    continue
                entries.append({
                    'file': path,
                    'line': n,
                    'raw': line.rstrip('\n'),
                    'node': m.group(3),
                    # args verbatim, minus the surrounding quotes of each token
                    'command': ' '.join(
                        t[1:-1] if len(t) > 1 and t.startswith('"') and t.endswith('"') else t
                        for t in re.findall(r'"(?:[^"\\]|\\.)*"|\S+', m.group(4))),
                    'enabled': m.group(2) is None,
                })
    return entries


def read_lines(path):
    with open(path, encoding='utf-8', errors='replace') as f:
        return f.readlines()


def write_lines(path, lines):
    tmp = path + '.qstmp'
    with open(tmp, 'w', encoding='utf-8') as f:
        f.writelines(lines)
    os.replace(tmp, path)


def edit_niri_line(path, line_no, expect, remove):
    path = os.path.expanduser(path)
    lines = read_lines(path)
    if line_no < 1 or line_no > len(lines):
        return f'line {line_no} is out of range in {path}'
    current = lines[line_no - 1].rstrip('\n')
    if current != expect:
        return f'{path}:{line_no} changed on disk — reload and try again'
    if remove:
        del lines[line_no - 1]
    else:
        m = SPAWN_RE.match(current)
        if not m:
            return f'{path}:{line_no} is not a spawn-at-startup line'
        indent, comment = m.group(1), m.group(2)
        body = current.lstrip()[len(comment):].lstrip() if comment else current.lstrip()
        lines[line_no - 1] = f'{indent}{"" if comment else "// "}{body}\n'
    write_lines(path, lines)
    return None


# ── xdg autostart ────────────────────────────────────────────────────────

def parse_desktop(path):
    """Keys of the [Desktop Entry] group (unlocalized, last one wins)."""
    keys = {}
    in_group = False
    try:
        for line in read_lines(path):
            s = line.strip()
            if s.startswith('['):
                in_group = s == '[Desktop Entry]'
                continue
            if not in_group or not s or s.startswith('#') or '=' not in s:
                continue
            k, _, v = s.partition('=')
            k = k.strip()
            if '[' not in k:
                keys[k] = v.strip()
    except OSError as e:
        print(f'autostart-entries: cannot read {path}: {e}', file=sys.stderr)
    return keys


def list_xdg():
    user_dir = user_autostart_dir()
    found = {}  # basename -> {...}
    for d in system_autostart_dirs() + [user_dir]:
        if not os.path.isdir(d):
            continue
        is_user = os.path.realpath(d) == os.path.realpath(user_dir)
        for name in sorted(os.listdir(d)):
            if not name.endswith('.desktop'):
                continue
            path = os.path.join(d, name)
            keys = parse_desktop(path)
            prev = found.get(name, {})
            note = ''
            enabled = True
            if keys.get('Hidden', '').lower() == 'true':
                enabled, note = False, 'Hidden'
            only = [s for s in keys.get('OnlyShowIn', '').split(';') if s]
            never = [s for s in keys.get('NotShowIn', '').split(';') if s]
            if enabled and only and not any(d_ in DESKTOP for d_ in only):
                enabled, note = False, 'Only starts in: ' + ', '.join(only)
            elif enabled and any(d_ in DESKTOP for d_ in never):
                enabled, note = False, 'Excluded from this desktop'
            found[name] = {
                'id': name,
                'path': path,
                'name': keys.get('Name') or name[:-len('.desktop')],
                'command': keys.get('Exec', ''),
                'enabled': enabled,
                'note': note,
                'hasUser': is_user or prev.get('hasUser', False),
                'hasSystem': (not is_user) or prev.get('hasSystem', False),
            }
    return sorted(found.values(), key=lambda e: e['name'].lower())


def find_xdg(entry_id):
    for e in list_xdg():
        if e['id'] == entry_id:
            return e
    return None


def set_hidden(path, hidden):
    lines = read_lines(path)
    out = []
    in_group = False
    done = False
    for line in lines:
        s = line.strip()
        if s.startswith('['):
            if in_group and not done:
                out.append(f'Hidden={"true" if hidden else "false"}\n')
                done = True
            in_group = s == '[Desktop Entry]'
        elif in_group and re.match(r'^\s*Hidden\s*=', line):
            if done:
                continue  # drop duplicates
            out.append(f'Hidden={"true" if hidden else "false"}\n')
            done = True
            continue
        out.append(line)
    if not done:
        out.append(f'Hidden={"true" if hidden else "false"}\n')
    write_lines(path, out)


def xdg_set_enabled(entry_id, enabled):
    entry = find_xdg(entry_id)
    if entry is None:
        return f'no autostart entry named {entry_id}'
    user_path = os.path.join(user_autostart_dir(), entry_id)
    if not os.path.isfile(user_path):
        os.makedirs(user_autostart_dir(), exist_ok=True)
        shutil.copyfile(entry['path'], user_path)
    set_hidden(user_path, not enabled)
    return None


def xdg_remove(entry_id):
    entry = find_xdg(entry_id)
    if entry is None:
        return f'no autostart entry named {entry_id}'
    # A system copy would come back if we just deleted the user file, so
    # mask it with Hidden=true instead — same thing GNOME Tweaks does.
    if entry['hasSystem']:
        return xdg_set_enabled(entry_id, False)
    user_path = os.path.join(user_autostart_dir(), entry_id)
    try:
        os.remove(user_path)
    except OSError as e:
        return f'cannot remove {user_path}: {e}'
    return None


# ── cli ──────────────────────────────────────────────────────────────────

def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[1])
    ap.add_argument('action', choices=['list', 'niri-toggle', 'niri-remove',
                                       'xdg-set', 'xdg-remove'])
    ap.add_argument('--path', default='~/.config/niri/config.kdl')
    ap.add_argument('--file')
    ap.add_argument('--line', type=int)
    ap.add_argument('--expect')
    ap.add_argument('--id')
    ap.add_argument('--enabled', type=int)
    args = ap.parse_args()

    if args.action == 'list':
        json.dump({'niri': list_niri(args.path), 'xdg': list_xdg()}, sys.stdout)
        print()
        return 0

    if args.action in ('niri-toggle', 'niri-remove'):
        if not args.file or args.line is None or args.expect is None:
            print('autostart-entries: --file, --line and --expect are required',
                  file=sys.stderr)
            return 2
        err = edit_niri_line(args.file, args.line, args.expect,
                             args.action == 'niri-remove')
    elif args.action == 'xdg-set':
        if not args.id or args.enabled is None:
            print('autostart-entries: --id and --enabled are required', file=sys.stderr)
            return 2
        err = xdg_set_enabled(args.id, bool(args.enabled))
    else:
        if not args.id:
            print('autostart-entries: --id is required', file=sys.stderr)
            return 2
        err = xdg_remove(args.id)

    if err:
        print(f'autostart-entries: {err}', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
