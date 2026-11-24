#!/usr/bin/env python3
import argparse
import configparser
import copy
import fcntl
from io import StringIO
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import tomllib


DEFAULTS = Path(__file__).with_name("matugen")
TERMINALS = {"terminal", "kitty", "ghostty", "foot", "alacritty", "wezterm"}
QT = {"qt5ct", "qt6ct", "kcolorscheme"}
LEGACY_NAMES = {
    "end4-ghostty.conf": "ghostty.conf",
    "end4-gtk-main.css": "gtk-main.css",
    "end4-gtk.css": "gtk4-colors.css",
    "end4-gtk3.css": "gtk3-colors.css",
    "end4-kde.colors": "kde.colors",
    "end4-kitty.conf": "kitty.conf",
    "end4-qtct.conf": "qt-colors.conf",
    "end4-seed.txt": "source-color.txt",
    "end4-terminal.json": "terminal-colors.json",
}


def xdg(name, fallback):
    return Path(os.environ.get(name) or Path.home() / fallback)


def toml_value(value):
    if isinstance(value, dict):
        return "{ " + ", ".join(f"{json.dumps(k)} = {toml_value(v)}" for k, v in value.items()) + " }"
    if isinstance(value, list):
        return "[" + ", ".join(map(toml_value, value)) + "]"
    if isinstance(value, (str, bool, int, float)):
        return json.dumps(value, ensure_ascii=False, allow_nan=False)
    raise ValueError(f"Unsupported TOML value: {value!r}")


def dump_config(config):
    lines = [f"{json.dumps(key)} = {toml_value(value)}" for key, value in config.items()
             if not isinstance(value, dict)]
    for section, values in config.items():
        if not isinstance(values, dict):
            continue
        header = section if re.fullmatch(r"[A-Za-z0-9_-]+", section) else json.dumps(section)
        if section == "templates":
            for name, template in values.items():
                lines += ["", f"[{header}.{json.dumps(name)}]"]
                lines += [f"{json.dumps(key)} = {toml_value(value)}" for key, value in template.items()]
        else:
            lines += ["", f"[{header}]"]
            lines += [f"{json.dumps(key)} = {toml_value(value)}" for key, value in values.items()]
    return "\n".join(lines).strip() + "\n"


def atomic_write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as stream:
        temporary = Path(stream.name)
        try:
            stream.write(text)
            stream.close()
            temporary.replace(path)
        finally:
            temporary.unlink(missing_ok=True)


def config_files(config_path):
    directory = config_path.parent
    defaults = directory / "configs/defaults.toml"
    return ([defaults] if defaults.is_file() else []) + ([config_path] if config_path.is_file() else []) + [
        path for path in sorted(directory.glob("*.toml")) if path != config_path and not path.name.startswith(".")
    ] + [path for path in sorted((directory / "configs").glob("*.toml"))
         if path != defaults and not path.name.startswith(".")]


def merge_config(target, source):
    for key, value in source.items():
        if isinstance(value, dict) and isinstance(target.get(key), dict):
            merge_config(target[key], value)
        else:
            target[key] = copy.deepcopy(value)


def load_config(config_path, defaults=None):
    result = copy.deepcopy(defaults) if defaults is not None else {"config": {}, "templates": {}}
    for path in config_files(config_path):
        try:
            config = tomllib.loads(path.read_text())
        except ValueError as error:
            raise ValueError(f"{path}: {error}") from error
        if not isinstance(config.get("config", {}), dict) or not isinstance(config.get("templates", {}), dict):
            raise ValueError(f"{path}: config and templates must be TOML tables")
        for name, template in config.get("templates", {}).items():
            if not isinstance(template, dict):
                raise ValueError(f"{path}: template {name!r} must be a TOML table")
            if "output_path" in template and not isinstance(template["output_path"], str):
                raise ValueError(f"{path}: template {name!r} has an invalid output_path")
        merge_config(result, config)
    for name, template in result["templates"].items():
        if not isinstance(template.get("input_path"), str):
            raise ValueError(f"Template {name!r} needs an input_path")
    return result


def migrate_templates(template_dir, sources):
    for old_name, name in LEGACY_NAMES.items():
        old = template_dir / old_name
        target = template_dir / name
        referenced = any(old_name in text for text in sources.values())
        if old.is_file():
            if target.exists() and old.read_bytes() != target.read_bytes() and referenced:
                target = target.with_name(f"{target.stem}-custom{target.suffix}")
                if target.exists() and old.read_bytes() != target.read_bytes():
                    raise ValueError(f"Cannot migrate {old}: {target} already exists with different content")
            if not target.exists():
                old.rename(target)
            else:
                backup = template_dir / "backups" / old_name
                backup.parent.mkdir(exist_ok=True)
                if not backup.exists():
                    old.rename(backup)
        for path, text in sources.items():
            sources[path] = text.replace("/" + old_name, "/" + target.name)


def install(config_path):
    config_path.parent.mkdir(parents=True, exist_ok=True)
    source = config_path.read_text() if config_path.exists() else "[config]\n"
    original = config_path.with_suffix(".toml.orig")
    if source.startswith("# ! AUTO-GENERATED by the shell settings app") and original.exists():
        backup = config_path.with_suffix(".toml.pre-matugen-only")
        if not backup.exists():
            shutil.copyfile(config_path, backup)
        source = original.read_text()
    config = tomllib.loads(source)
    defaults = tomllib.loads((DEFAULTS / "config.toml").read_text())
    for template in defaults["templates"].values():
        for key in ("input_path", "output_path"):
            for token, path in (("@CONFIG@", xdg("XDG_CONFIG_HOME", ".config")),
                                ("@STATE@", xdg("XDG_STATE_HOME", ".local/state")),
                                ("@DATA@", xdg("XDG_DATA_HOME", ".local/share"))):
                template[key] = template[key].replace(token, str(path))
    load_config(config_path, defaults)
    template_dir = config_path.parent / "templates"
    template_dir.mkdir(exist_ok=True)
    (config_path.parent / "configs").mkdir(exist_ok=True)
    sources = {path: path.read_text() for path in config_files(config_path)}
    sources[config_path] = source
    migrate_templates(template_dir, sources)
    for path in DEFAULTS.iterdir():
        if path.name == "config.toml":
            continue
        target = template_dir / path.name
        if not target.exists():
            shutil.copyfile(path, target)
    # Only migrate the shell-owned path; hand-written app templates stay untouched.
    legacy = config.get("templates", {}).get("quickshell", {}).get("input_path", "")
    if "/scripts/colors/matugen/quickshell-colors.json" in legacy:
        sources[config_path] = sources[config_path].replace(legacy, defaults["templates"]["quickshell"]["input_path"])
    for path, text in sources.items():
        tomllib.loads(text)
        if not path.exists() or text != path.read_text():
            atomic_write(path, text)
    defaults_path = config_path.parent / "configs/defaults.toml"
    header = "# Default templates. Override these in config.toml or another TOML file.\n"
    legacy_defaults = header + "\n".join(f"{json.dumps(k)} = {toml_value(v)}" for k, v in defaults.items()) + "\n"
    if not defaults_path.exists() or defaults_path.read_text() == legacy_defaults:
        atomic_write(defaults_path, header + dump_config(defaults))


def ensure_flatpak_styles():
    if not shutil.which("flatpak"):
        return
    required = {"xdg-config/gtk-3.0:ro", "xdg-config/gtk-4.0:ro"}
    try:
        result = subprocess.run(["flatpak", "override", "--user", "--show"],
                                check=True, capture_output=True, text=True)
        config = configparser.ConfigParser(interpolation=None)
        config.read_string(result.stdout)
        permissions = set(config.get("Context", "filesystems", fallback="").split(";"))
        if not required <= permissions:
            subprocess.run(["flatpak", "override", "--user", *("--filesystem=" + path for path in sorted(required))],
                           check=True, capture_output=True, text=True)
    except (OSError, configparser.Error, subprocess.CalledProcessError) as error:
        print(f"[matugen] Could not grant Flatpak stylesheet access: {error}", file=sys.stderr)


def settings():
    path = xdg("XDG_CONFIG_HOME", ".config") / "qssettings/config.json"
    preferences = json.loads(path.read_text()) if path.exists() else {}
    if not isinstance(preferences, dict):
        raise ValueError("Shell settings must be a JSON object")
    appearance = preferences.get("appearance", {})
    if not isinstance(appearance, dict) or not isinstance(appearance.get("wallpaperTheming", {}), dict):
        raise ValueError("Invalid appearance settings")
    theming = appearance.get("wallpaperTheming", {})
    if not isinstance(theming.get("terminalGenerationProps", {}), dict):
        raise ValueError("Invalid terminal settings")
    if not isinstance(appearance.get("matugenDisabled", []), list):
        raise ValueError("Disabled Matugen templates must be a list")
    return preferences


def template_enabled(name, template, preferences, lock):
    appearance = preferences.get("appearance", {})
    theming = appearance.get("wallpaperTheming", {})
    if lock:
        return name == "quickshell"
    if name in ("quickshell", "quickshell-seed"):
        return True
    if name in appearance.get("matugenDisabled", []):
        return False
    output = template.get("output_path", "")
    if name in TERMINALS or "/terminal/" in output:
        return theming.get("enableTerminal", True)
    if name in QT:
        return theming.get("enableQtApps", True)
    return True


def configure_qt(preferences, templates):
    if not preferences.get("appearance", {}).get("wallpaperTheming", {}).get("enableQtApps", True):
        return
    config_home = xdg("XDG_CONFIG_HOME", ".config")
    for name in ("qt5ct", "qt6ct"):
        if name not in templates:
            continue
        path = config_home / name / f"{name}.conf"
        config = configparser.ConfigParser(interpolation=None)
        config.optionxform = str
        if path.exists():
            config.read_string(path.read_text())
        if not config.has_section("Appearance"):
            config.add_section("Appearance")
        palette = Path(templates[name]["output_path"]).expanduser()
        if not palette.is_absolute():
            palette = config_home / "matugen" / palette
        config.set("Appearance", "color_scheme_path", str(palette))
        config.set("Appearance", "custom_palette", "true")
        if not config.has_option("Appearance", "style"):
            config.set("Appearance", "style", "Fusion")
        stream = StringIO()
        config.write(stream, space_around_delimiters=False)
        atomic_write(path, stream.getvalue())


def generate(config_path, args):
    preferences = settings()
    theming = preferences.get("appearance", {}).get("wallpaperTheming", {})
    if not theming.get("enableAppsAndShell", True):
        return
    config = load_config(config_path)
    active = {name: copy.deepcopy(template) for name, template in config.get("templates", {}).items()
              if template_enabled(name, template, preferences, args.lock)}
    if "quickshell" not in active:
        raise ValueError("The quickshell template is required to generate shell colors")
    generated = xdg("XDG_STATE_HOME", ".local/state") / "quickshell/user/generated"
    generated.mkdir(parents=True, exist_ok=True)
    # Staged shell output avoids partial reloads; lock generation never runs app hooks.
    with tempfile.TemporaryDirectory(prefix=".palette-", dir=config_path.parent) as directory:
        stage = Path(directory)
        publish = []
        force_dark = theming.get("terminalGenerationProps", {}).get("forceDarkMode", False)
        for name, template in active.items():
            if name in ("quickshell", "quickshell-seed", "terminal", "kitty"):
                target = Path(template["output_path"]).expanduser()
                if not target.is_absolute():
                    target = config_path.parent / target
                if args.lock:
                    target = generated / "colors-lock.json"
                staged = stage / f"{name}-{target.name}"
                template["output_path"] = str(staged)
                publish.append((staged, target))
            if force_dark and (name in TERMINALS or "/terminal/" in template.get("output_path", "")):
                source = Path(template["input_path"]).expanduser()
                if not source.is_absolute():
                    source = config_path.parent / source
                dark = stage / f"{name}.template"
                dark.write_text(source.read_text().replace(".default.", ".dark."))
                template["input_path"] = str(dark)
        config["templates"] = active
        if args.lock:
            config["config"].pop("wallpaper", None)
            for template in active.values():
                template.pop("pre_hook", None)
                template.pop("post_hook", None)
        # Keep the invocation config next to config.toml so relative user paths still resolve.
        with tempfile.NamedTemporaryFile(mode="w", prefix=".render-", suffix=".toml", dir=config_path.parent) as stream:
            stream.write(dump_config(config))
            stream.flush()
            scheme = "scheme-smart" if args.scheme == "auto" else args.scheme
            command = ["matugen", "--config", stream.name, "--source-color-index", "0",
                       "--mode", args.mode, "--type", scheme]
            command += ["image", args.image] if args.image else ["color", "hex", args.color]
            subprocess.run(command, check=True)
        for staged, target in publish:
            if target.suffix == ".json":
                palette = json.loads(staged.read_text())
                if not isinstance(palette, dict) or not palette or any(
                        not isinstance(value, str) or not re.fullmatch(r"#[0-9a-fA-F]{6}", value)
                        for value in palette.values()):
                    raise ValueError(f"Invalid palette from {staged.name}")
                required = {"background", "on_surface", "primary"} if staged.name.startswith("quickshell-") else {
                    "background", "foreground", "cursor", "selection_background", "selection_foreground",
                    *(f"term{i}" for i in range(16))}
                if not required <= palette.keys():
                    raise ValueError(f"Incomplete palette from {staged.name}")
        for staged, target in publish:
            atomic_write(target, staged.read_text())
    if not args.lock:
        atomic_write(config_path.parent / "current_mode", args.mode + "\n")
        configure_qt(preferences, active)


def main():
    parser = argparse.ArgumentParser(description="Install and run user Matugen templates")
    parser.add_argument("--install", action="store_true")
    parser.add_argument("--list", action="store_true")
    parser.add_argument("--mode", choices=("dark", "light"), default="dark")
    parser.add_argument("--scheme", default="scheme-tonal-spot")
    parser.add_argument("--lock", action="store_true")
    source = parser.add_mutually_exclusive_group()
    source.add_argument("--image")
    source.add_argument("--color")
    args = parser.parse_args()
    config_path = xdg("XDG_CONFIG_HOME", ".config") / "matugen/config.toml"
    if args.list:
        config = load_config(config_path)
        print(json.dumps([{"name": name} for name in config.get("templates", {})]))
        return
    if not args.install and not args.image and not args.color:
        parser.error("--image or --color is required")
    if args.color and not re.fullmatch(r"#?[0-9a-fA-F]{6}", args.color):
        parser.error("Color must be a six-digit hex value")
    if args.color:
        args.color = "#" + args.color.lstrip("#")
    if args.image and not Path(args.image).is_file():
        parser.error("Image does not exist")
    config_path.parent.mkdir(parents=True, exist_ok=True)
    with (config_path.parent / ".setup.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        preferences = settings()
        if not args.lock:
            install(config_path)
            if preferences.get("appearance", {}).get("wallpaperTheming", {}).get("enableAppsAndShell", True):
                ensure_flatpak_styles()
        if not args.install:
            generate(config_path, args)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f"[matugen] {error}", file=sys.stderr)
        sys.exit(1)
