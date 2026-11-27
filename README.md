



<div align="center">

# 💠 end4-pC

**A niri-only personal fork of [pctrade/end4-pC](https://github.com/pctrade/end4-pC), based on [illogical-impulse](https://github.com/end-4/dots-hyprland)**

Customized and maintained by **[sabamdarif](https://github.com/sabamdarif)**

[English](README.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md)

</div>

---

## 🎬 Showcase

<p align="center">
  <a href="https://www.youtube.com/watch?v=o0Vsh7eVchs">
    <img src="https://img.youtube.com/vi/o0Vsh7eVchs/maxresdefault.jpg" alt="Material 3 Expressive x Linux" width="85%" style="border-radius: 12px; box-shadow: 0px 10px 30px rgba(0,0,0,0.5);"/>
  </a>
</p>

</div>

---

## 📸 Screenshots
<div align="center">

| 🎵 Lyrics | 🖼️ Online Wallpapers |
|:---:|:---:|
| ![Screenshot 1](screenshots/1.png) | ![Screenshot 2](screenshots/2.png) |
| 🪟 Desktop Widgets | 🔧 Niri Configs |
| ![Screenshot 5](screenshots/5.png) | ![Screenshot 6](screenshots/6.png) |
| ⚙️ Configurable Bar | ✨ And More |
| ![Screenshot 3](screenshots/3.png) | ![Screenshot 4](screenshots/4.png) |

</div>

---

## ⚡ Installation

> [!NOTE]
> This fork runs on [niri](https://github.com/YaLTeR/niri) only. Shell preferences are stored separately. Enabling wallpaper theming writes the configured app palettes and selects them in Qt settings.

```bash
cd ~/.config/quickshell/
git clone https://github.com/sabamdarif/end4-pC.git
killall qs 2>/dev/null; qs -c end4-pC > /dev/null 2>&1 & disown
```

### 🔧 Start it with niri (optional)

To load it on login, add this to `~/.config/niri/config.kdl`:

```kdl
spawn-sh-at-startup "MALLOC_CONF=background_thread:true,dirty_decay_ms:10000,muzzy_decay_ms:10000 qs -c end4-pC"
```

The `MALLOC_CONF` prefix is optional but recommended: quickshell links jemalloc, which never returns freed memory to the OS while the shell sits idle. These options make it purge in the background, which keeps idle RSS low after heavy panels (settings, wallpaper selector) have been closed.

> [!TIP]
> niri picks up config changes as you save them, so only the shell itself needs restarting: `killall qs; qs -c end4-pC & disown`.

---

### ⚙️ Settings keybind

The shell has no global shortcuts of its own — niri owns the keymap and the shell is driven over IPC. To open the settings panel, add this to your niri binds:

```kdl
Mod+Escape { spawn "qs" "-c" "end4-pC" "ipc" "call" "settings" "toggle"; }
```

> **Note:** Settings is an overlay panel, not a regular window — `Mod + Q` won't close it. Use the same keybind to toggle it or press `Escape`.

### Updating this fork

The old **Update Dots** button has been removed because it deleted the checkout and replaced it with a different fork. Update through Git instead, after preserving any local changes and commits:

```bash
cd ~/.config/quickshell/end4-pC
git status --short
git pull --ff-only
```

Only pull when the working tree is clean and there are no unpushed local commits. If Git cannot fast-forward, stop and reconcile your branch rather than resetting or recloning over it.

### Usage and migration notes

- **Fresh setups:** The shell starts directly without a welcome screen. Customize it through Settings using the keybind above.
- **Settings:** Below 900 px, the navigation rail collapses after selecting a page. Click a group icon to reopen it. Keyboard selection scrolls search results into view, and searchable dropdowns select the highlighted filtered item.
- **Keyboard shortcuts:** **Input → Shortcuts** uses dux-shell's grouped shortcut layout, category filters, shortcut-aware search and popup editor. Add shell actions, compositor actions, application commands or shell commands, and use **New key** to add another key for an action. Edits preserve niri bind options and are validated before saving to `~/.config/niri/qssettings/binds.kdl`. Your own config files stay untouched. Removing or resetting an override restores any original shortcut; changing its key does not remove an original config bind. If setup is missing, **Copy includes** provides the lines to add at the end of `config.kdl`.
- **Colors and Theme:** The wallpaper preview and compact scheme selector stack on narrow windows. Light and dark mode labels stay inside their buttons.
- **Network speed:** The detail popup uses compact rows and hides unavailable network details without leaving empty space.
- **Clipboard history:** In **Apps → Clipboard**, use **Update autostart entry** to correct existing watchers, then restart those watchers or your session. The supported command is `wl-paste --type text --watch cliphist -max-items N store`, with flags before `store`. This also applies to image watchers. Updating the command cannot restore history already discarded under the old limit.
- **Audio mixer:** The default now prefers `pavucontrol-qt`, then `pavucontrol`. Existing saved `apps.volumeMixer` commands are not migrated. If yours still points into a Hyprland checkout, replace it in `~/.config/qssettings/config.json` with an installed mixer command.
- **Saved data:** Unreadable desktop notes and task files are preserved, and edits are blocked until the data is repaired and the shell reloaded. Unreadable notification history is also preserved; new notifications still work, but history writes stay disabled until reload. Notification images supplied as process-local Quickshell handles are not saved across restarts.
- **Dynamic Island:** Link downloads, fallback chat replies, file-download tracking, and per-process traffic attribution require helpers under `scripts/island/`, which are not included in this checkout. Unavailable actions and watchers stay disabled; total network traffic display remains available. A failed download watcher is not immediately relaunched.
- **Wallpaper colors:** Matugen generates shell, terminal, GTK/libadwaita and Qt palettes. Templates live in `~/.config/matugen/templates/`, with `config.toml` as the editable source of truth. Auto uses Matugen's smart scheme. Python's color generator and OpenCV scheme detection are no longer used.

### Wallpaper theming

Install Matugen with `scheme-smart` support (4.2 or newer). The shell sets up Matugen automatically at startup and before normal color generation, including existing installations. No manual `--install` step is required. To regenerate the current wallpaper's colors:

```bash
bash scripts/colors/switchwall.sh --noswitch
```

Existing app templates and edits are preserved. Default declarations live in `~/.config/matugen/configs/defaults.toml`, below your own configuration in priority. Template filenames are generic, such as `kitty.conf`, `gtk4-colors.css` and `terminal-colors.json`. Previous prefixed files are migrated without overwriting existing generic files. The old auto-generated `config.toml` setup is migrated from `config.toml.orig`, keeping backups. Afterwards, edit **`~/.config/matugen/config.toml` directly**, not `.orig`. Template toggles filter each invocation without rewriting your configuration. The shell template cannot be disabled individually; use **Shell & utilities** instead.

You can also drop additional `*.toml` configurations directly into `~/.config/matugen/` or `~/.config/matugen/configs/`, without registering them anywhere. For example, `~/.config/matugen/my-app.toml`:

```toml
[templates.my_app]
input_path = "./templates/my-app.conf"
output_path = "~/.config/my-app/colors.conf"
```

The input file must contain a Matugen template. A raw template alone cannot specify where its generated output belongs.

Configurations merge in this order: `configs/defaults.toml`, `config.toml`, root-level TOML files alphabetically, then other `configs/` TOML files alphabetically. Later values override earlier ones, including individual template fields. Relative paths resolve from the **Matugen directory**, even for files in `configs/`. Added, edited and removed configs update the settings template list automatically; their colors apply on the next wallpaper change or **Regenerate now**. Hidden temporary files and `.orig`/backup files are ignored. Invalid configs are reported instead of replacing the last working shell palette.

- **Terminals:** Kitty uses `~/.local/state/quickshell/user/generated/terminal/kitty-theme.conf`. Include that file in Kitty's config. Ghostty uses `theme = Matugen`. ANSI colors come from Matugen's built-in filters, not the old Python harmonization settings. **Force dark mode in terminal** also applies to the configured Ghostty, Foot, Alacritty and WezTerm templates. Existing open terminals receive color escape sequences.
- **Qt:** Install `qt6ct` for Qt 6 and `qt5ct` for Qt 5. The shell selects `Matugen.colors` and enables the custom palette in both configuration files, without changing an existing widget style. Launch Qt 6 apps with `QT_QPA_PLATFORMTHEME=qt6ct` and Qt 5 apps with `QT_QPA_PLATFORMTHEME=qt5ct`. Restart apps after changing the platform theme. KDE apps also get a native `MatugenKDE.colors` scheme selected through `kwriteconfig6`, when installed.
- **GTK/libadwaita:** The default templates install `colors.css` and an importing `gtk.css` in both GTK configuration directories. GTK 4 output includes modern libadwaita CSS variables and legacy named colors. GTK 3 uses `adw-gtk3` when installed, otherwise built-in Adwaita. Existing apps may need restarting. If you already have a custom stylesheet, keep it and add `@import "colors.css";` instead of enabling the corresponding `gtk3-css` or `gtk4-css` template.
- **Flatpak:** With **Shell & utilities** enabled, automatic setup grants all your Flatpak apps read-only access to the two GTK stylesheet directories. This is a persistent user-wide override, so future installs are covered too. It does not grant access to the rest of your configuration. The equivalent manual command is:

  ```bash
  flatpak override --user --filesystem=xdg-config/gtk-3.0:ro --filesystem=xdg-config/gtk-4.0:ro
  ```

  Restart running apps to load the stylesheets. Existing app-specific filesystem denials remain respected. You can opt an app out with `flatpak override --user --nofilesystem=xdg-config/gtk-3.0 --nofilesystem=xdg-config/gtk-4.0 APP_ID`. Disabling wallpaper theming does not revoke already granted permissions. Host Qt plugins do not automatically become available inside Flatpak runtimes, and apps with hardcoded styles may ignore platform palettes.

All configuration and output paths follow the corresponding XDG directories. Lock-screen colors are rendered separately, without updating app palettes or running their hooks.

### Settings storage

Shell settings now live in **`~/.config/qssettings/`**:

- `config.json`: shell preferences edited in Settings.
- `actions/`: custom action files.
- `sounds/`: custom sound overrides.

Niri settings remain separate in **`~/.config/niri/qssettings/`**, including `settings.json` and the generated KDL files. Both locations follow `XDG_CONFIG_HOME` when it is set. Runtime state and caches remain in their existing XDG state/cache locations.

The shell and its helper scripts use only this new folder. There is no automatic migration or fallback to `illogical-impulse/`.

### Niri configuration in Settings

Settings reads `~/.config/niri/config.kdl` and follows its includes in order,
including nested files and symlinked dotfiles. Supported input, keyboard, layout,
decoration, blur, animation and cursor controls show the effective KDL values,
not stale values from the shell's JSON. Changes to included files refresh the UI.

Opening Settings does not generate niri overrides. Changing a control updates
only its override, preserving unrelated settings and additional pointing-device
or XKB fields. Niri validates generated shell fragments before they are saved.
Existing generated overrides remain in force: when `qssettings` is included last,
its conflicting values still take precedence over earlier user files, just as in niri.

The Window rules page also lists rules from your own files under **From your niri
config**, with their full configuration and an **Edit source** button. These rules
are not imported into the simpler rule editor, so multiple match groups, exclusions
and advanced properties remain intact. Rules added in Settings retain their own editor.

---

## Feature usage

### Wi-Fi sharing

In Settings → Wi-Fi, use the QR button beside a saved network or **Share via QR**
in its profile editor. Personal WPA/WPA3, WEP and open networks are supported;
enterprise and Enhanced Open networks cannot be shared this way. Install
`qrencode` for QR generation. NetworkManager must allow reading the saved secret.
Temporary images are private and removed when the dialog closes. Saved images
contain the password, so share them carefully. Sharing uses the saved profile,
not unsaved edits.

### Window rules

Settings → Windows and Workspaces → Window rules manages niri rules. Pick an
open window or enter app ID/title regular expressions, then set opening mode,
opacity, column width, capture blocking, clipping or scroll factor. Match fields
must all match the same window. Niri validates rules before they are saved.
Right-click the active window title in either bar to start a rule for that app.
Use **Setup** if prompted to add the generated includes to your niri config;
your original config is backed up. Rules are stored in
`$XDG_CONFIG_HOME/niri/qssettings/settings.json` and generated as `windowrules.kdl`.

### Removable drives and storage

Add **Removable drives** to a bar layout in Settings → Shell → Bar. It appears
only while a removable drive is connected unless **Show even when no drives are
connected** is enabled. New configurations include it by default. Click a volume
to mount it or open its folder, unmount it with its eject button, or safely eject
the whole drive after all its volumes have been unmounted. Failed unmounts stop
ejection; nothing is forcibly unmounted.

Detected volumes appear even when they are not mounted, just as in Files.
**Mount** connects an unmounted volume; its eject icon then unmounts it. The
drive-level **Safely eject** action disconnects the whole USB device.
The dropdown closes automatically when you switch workspaces.

The popup's **Storage manager** switches to a detailed view in the same dropdown,
without opening Quick Settings. **Back** returns to the removable-device list.
It shows internal and removable disks, partition
capacity and optional SMART health, temperature, lifetime usage and power-on
hours. Install `udisks2` for mount/eject actions and `smartmontools` for health
checks. SMART access needs device permissions and may not work through USB
bridges. The shell does not automatically request elevated privileges.

MTP phones also appear in the drive menu, including phones that are not mounted
yet. Opening one mounts it or opens it in your file manager; **Disconnect** safely
unmounts its GVfs connection, without powering off the phone. Install Python
PyGObject and the GVfs MTP backend, and enable file transfer on the unlocked phone.
Disk capacity and SMART diagnostics are not available for MTP devices.

### Digital wellbeing

The screen time desktop widget has the same detailed weekly chart, app usage
list, and limit controls as the wellbeing sheet. Use them directly on the desktop;
clicking the widget no longer opens Quick Settings. Drag its header to reposition it.
The portrait and wide sizes fit their content, with a scrollable app list to keep
the desktop card compact.
You can also open Settings → System → Digital wellbeing. Browse previous weeks, select a
day, or switch the app list between day, week and the last 30 calendar days.
Set a daily screen time limit or an app limit with the duration steppers.
Reminders notify once per app/day in a tracker session and respect notification
sound settings. Limits never block apps.

Tracking can be disabled independently of the desktop widget. Existing
configurations initially inherit the widget's tracking choice. Usage pauses
while locked or idle for five minutes, and rolls over at local midnight.
Up to 92 days are stored privately in `$XDG_CONFIG_HOME/qssettings/screentime.json`.
Old cache data is imported only if its boot date is today; the old file is left
untouched. Invalid history stops the tracker instead of overwriting your data.
Date/chart helpers are adapted from dux-shell under its MIT license.

## 📦 Runtime dependencies

> [!NOTE]
> The install steps above only assume [niri](https://github.com/YaLTeR/niri) and quickshell. Everything in the tables below is a program the shell itself spawns at runtime; Arch package names are given. Packages marked (AUR) are not in the official repositories.

Only the core list is needed for the shell to start and work. Feature-gated packages are only spawned when you actually use that feature, so install them as needed.

### Core

| Programs | Arch package | Used for |
| --- | --- | --- |
| `niri msg` | niri | compositor control: workspaces, windows, outputs, keybinds, event stream |
| `systemctl`, `loginctl`, `busctl`, `hostnamectl` | systemd | suspend, reboot, lock session, system info |
| `pkexec` | polkit | admin actions (user management, per-host daemon toggles) |
| `nmcli` | networkmanager | Wi-Fi and ethernet state |
| `curl` | curl | public IP, weather, media cover art, online wallpapers |
| `jq` | jq | JSON parsing |
| `gsettings`, `gio` | glib2 | sound, GTK, icon and cursor themes; trash operations (trash needs `gvfs`) |
| `xdg-open`, `xdg-mime`, `xdg-settings` | xdg-utils | opening files and links, default app handling |
| `wl-copy`, `wl-paste` | wl-clipboard | clipboard panel |
| `cliphist` | cliphist | clipboard history |
| `notify-send` | libnotify | system notifications |
| `magick`, `convert`, `identify` | imagemagick | thumbnails, image cropping and conversion |
| `ffmpeg` | ffmpeg | video thumbnails, live wallpaper processing |
| `python3` | python | helper scripts (screen time, keybind list, autostart entries, lyrics) |
| `bash`, `pkill`, `pidof`, `killall`, `kill`, `free`, `lscpu`, `nice` | bash, procps-ng, psmisc, util-linux | console snippets, process checks, system info |
| `cat`, `grep`, `sed`, `awk`, `find`, `xargs`, `df`, `stat`, `touch`, `file`, `which` | coreutils, grep, sed, gawk, findutils, file, which | shell snippets for system info and config checks |
| `sensors` | lm_sensors | CPU and GPU temperatures |
| `secret-tool` | libsecret | keyring storage on lock screens (needs `gnome-keyring`) |

### Feature-gated

| Feature | Programs | Arch packages |
| --- | --- | --- |
| Screenshot | `grim`, `satty` | grim, satty |
| Color picker | `slurp` | slurp |
| Wi-Fi QR sharing | `qrencode` | qrencode |
| Drive discovery and events | `lsblk`, `udevadm` | util-linux, systemd |
| Mount and safely eject drives | `udisksctl` | udisks2 |
| SMART drive health | `smartctl` | smartmontools |
| MTP phones | `gio`, Python `gi`, GVfs MTP backend | glib2, python-gobject, gvfs-mtp |
| Audio visualizer | `cava` | cava |
| Stop an existing screen recording | `wf-recorder` | wf-recorder |
| System sound fallbacks | `paplay`, `pw-play`, `canberra-gtk-play` (first available wins) | libpulse, pipewire-audio, libcanberra |
| Mic mute quick toggle | `wpctl` | wireplumber |
| Brightness control | `brightnessctl`, `ddcutil` | brightnessctl, ddcutil |
| Night light | `wlsunset` | wlsunset |
| Live wallpaper | `mpvpaper`, `socat`, `swaybg` | mpvpaper, socat, swaybg |
| Theming from wallpaper | `matugen` 4.2+ and Python 3.11+ (standard library only); optional Qt platform themes | matugen, python, qt6ct, qt5ct |
| File pickers | `kdialog` or `yad` | kdialog, yad |
| File search | `fd` | fd |
| GPU detection (System info) | `glxinfo`, `lspci` | mesa-utils, pciutils |
| FPS limiter overlay | `mangohud` | mangohud |
| Fingerprint availability | `fprintd-list` | fprintd |
| Keyboard layout test | `wtype` | wtype |
| Update checks | `checkupdates`, `paru` or `yay`, `flatpak` | pacman-contrib, paru or yay, flatpak |
| Cloudflare WARP toggle | `warp-cli` | cloudflare-warp-bin (AUR) |
| Optional wallpaper upscale | `upscayl` | upscayl-bin (AUR) |

A few programs are user-configurable app defaults in the settings rather than hardcoded dependencies: the terminal emulator (chosen from installed terminals), `fish`, `dolphin`, `pavucontrol` (or `pavucontrol-qt`), `plasma-systemmonitor` and the `kcmshell6` Plasma settings modules (packages `fish`, `dolphin`, `pavucontrol`, `pavucontrol-qt`, `plasma-systemmonitor`, `kcmutils`), which open system monitors, mixer, user and Bluetooth settings. Gnome keyring sync (`gnome-keyring`) and `gvfs` are strictly optional.

## 🙏 Credits

Huge thanks to the people who made this possible:

- **[@end-4](https://github.com/end-4)** — for creating the original [dots-hyprland](https://github.com/end-4/dots-hyprland) / illogical-impulse shell. An absolute masterpiece of a dotfiles project 🫡
- **[@pctrade](https://github.com/pctrade)** for the Material 3 Expressive fork this checkout builds on.
- **[@gh0stzk](https://github.com/gh0stzk)** — for providing the weather API integration that made the weather widget possible 🙌
- **[@StarS2112](https://github.com/StarS2112)** — for showcasing this fork 🙌

---

<div align="center">

Made with ❤️ — feel free to fork and make it your own

</div>
