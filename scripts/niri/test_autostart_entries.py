#!/usr/bin/env python3
"""Self-check for autostart-entries.py. Run: python3 test_autostart_entries.py"""

import importlib.util
import os
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
os.environ['XDG_CURRENT_DESKTOP'] = 'niri'

spec = importlib.util.spec_from_file_location(
    'autostart_entries', os.path.join(HERE, 'autostart-entries.py'))
ae = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ae)


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write(text)


def test_niri():
    with tempfile.TemporaryDirectory() as tmp:
        cfg = os.path.join(tmp, 'config.kdl')
        inc = os.path.join(tmp, 'config.d', 'autostart.kdl')
        write(cfg, 'include "config.d/autostart.kdl"\n'
                   'include optional=true "qssettings/autostart.kdl"\n')
        write(inc, 'spawn-sh-at-startup "waybar"\n'
                   '// spawn-at-startup "off-app"\n'
                   'spawn-at-startup "sh" "-c" "echo hi"\n')
        write(os.path.join(tmp, 'qssettings', 'autostart.kdl'),
              'spawn-at-startup "sh" "-c" "shell-owned"\n')

        e = ae.list_niri(cfg)
        assert [x['command'] for x in e] == ['waybar', 'off-app', 'sh -c echo hi'], e
        assert [x['enabled'] for x in e] == [True, False, True]
        assert all('qssettings' not in x['file'] for x in e), 'own file must be skipped'

        # stale line number must not clobber anything
        assert ae.edit_niri_line(inc, 1, 'something else', False)
        assert open(inc).read().startswith('spawn-sh-at-startup "waybar"')

        assert ae.edit_niri_line(inc, 1, e[0]['raw'], False) is None
        assert ae.list_niri(cfg)[0] == dict(e[0], enabled=False,
                                            raw='// spawn-sh-at-startup "waybar"')
        assert ae.edit_niri_line(inc, 1, '// spawn-sh-at-startup "waybar"', False) is None
        assert ae.list_niri(cfg)[0]['enabled'] is True

        assert ae.edit_niri_line(inc, 1, e[0]['raw'], True) is None
        assert [x['command'] for x in ae.list_niri(cfg)] == ['off-app', 'sh -c echo hi']


def test_xdg():
    with tempfile.TemporaryDirectory() as tmp:
        os.environ['XDG_CONFIG_HOME'] = os.path.join(tmp, 'config')
        os.environ['XDG_CONFIG_DIRS'] = os.path.join(tmp, 'etc')
        write(os.path.join(tmp, 'etc', 'autostart', 'sys.desktop'),
              '[Desktop Entry]\nName=Sys\nExec=sysd\n')
        write(os.path.join(tmp, 'etc', 'autostart', 'gnomeonly.desktop'),
              '[Desktop Entry]\nName=G\nExec=g\nOnlyShowIn=GNOME;\n')
        write(os.path.join(tmp, 'config', 'autostart', 'mine.desktop'),
              '[Desktop Entry]\nName=Mine\nExec=mine\n')

        by_id = {e['id']: e for e in ae.list_xdg()}
        assert by_id['sys.desktop']['enabled'] and by_id['sys.desktop']['hasSystem']
        assert not by_id['sys.desktop']['hasUser']
        assert not by_id['gnomeonly.desktop']['enabled']
        assert by_id['mine.desktop']['hasUser'] and not by_id['mine.desktop']['hasSystem']

        # disabling a system entry masks it with a user copy
        assert ae.xdg_set_enabled('sys.desktop', False) is None
        e = {x['id']: x for x in ae.list_xdg()}['sys.desktop']
        assert e['enabled'] is False and e['hasUser'] and e['note'] == 'Hidden'
        assert ae.xdg_set_enabled('sys.desktop', True) is None
        assert {x['id']: x for x in ae.list_xdg()}['sys.desktop']['enabled'] is True

        # removing a system-backed entry masks; removing a user-only one deletes
        assert ae.xdg_remove('sys.desktop') is None
        assert {x['id']: x for x in ae.list_xdg()}['sys.desktop']['enabled'] is False
        assert ae.xdg_remove('mine.desktop') is None
        assert 'mine.desktop' not in {x['id'] for x in ae.list_xdg()}


test_niri()
test_xdg()
print('ok')
