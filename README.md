



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
> This fork runs on [niri](https://github.com/YaLTeR/niri) only. It manages its own configuration folder independently — it does **not** overwrite or modify any existing setup.

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

- **Settings:** Below 900 px, the navigation rail collapses after selecting a page. Click a group icon to reopen it. Keyboard selection scrolls search results into view, and searchable dropdowns select the highlighted filtered item.
- **Clipboard history:** In **Apps → Clipboard**, use **Update autostart entry** to correct existing watchers, then restart those watchers or your session. The supported command is `wl-paste --type text --watch cliphist -max-items N store`, with flags before `store`. This also applies to image watchers. Updating the command cannot restore history already discarded under the old limit.
- **Audio mixer:** The default now prefers `pavucontrol-qt`, then `pavucontrol`. Existing saved `apps.volumeMixer` commands are not migrated. If yours still points into a Hyprland checkout, replace it in `~/.config/illogical-impulse/config.json` with an installed mixer command.
- **Saved data:** Unreadable desktop notes and task files are preserved, and edits are blocked until the data is repaired and the shell reloaded. Unreadable notification history is also preserved; new notifications still work, but history writes stay disabled until reload. Notification images supplied as process-local Quickshell handles are not saved across restarts.
- **Dynamic Island:** Link downloads, fallback chat replies, file-download tracking, and per-process traffic attribution require helpers under `scripts/island/`, which are not included in this checkout. Unavailable actions and watchers stay disabled; total network traffic display remains available. A failed download watcher is not immediately relaunched.
- **Terminal colors:** Wallpaper-based terminal theming uses this checkout's templates and no longer requires a separate `quickshell/ii` directory.

---

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
| Audio visualizer | `cava` | cava |
| Stop an existing screen recording | `wf-recorder` | wf-recorder |
| System sound fallbacks | `paplay`, `pw-play`, `canberra-gtk-play` (first available wins) | libpulse, pipewire-audio, libcanberra |
| Mic mute quick toggle | `wpctl` | wireplumber |
| Brightness control | `brightnessctl`, `ddcutil` | brightnessctl, ddcutil |
| Night light | `wlsunset` | wlsunset |
| Live wallpaper | `mpvpaper`, `socat`, `swaybg` | mpvpaper, socat, swaybg |
| Theming from wallpaper | `matugen` plus Python `PIL` / `materialyoucolor` / `numpy` / `cv2` | matugen, python-pillow, python-numpy, python-opencv, python-materialyoucolor (AUR) |
| File pickers | `kdialog` or `yad` | kdialog, yad |
| File search | `fd` | fd |
| GPU detection (System info) | `glxinfo`, `lspci` | mesa-utils, pciutils |
| FPS limiter overlay | `mangohud` | mangohud |
| Fingerprint availability | `fprintd-list` | fprintd |
| Keyboard layout test | `wtype` | wtype |
| Update checks | `checkupdates`, `paru` or `yay`, `flatpak` | pacman-contrib, paru or yay, flatpak |
| Cloudflare WARP toggle | `warp-cli` | cloudflare-warp-bin (AUR) |
| Optional wallpaper upscale | `upscayl` | upscayl-bin (AUR) |

A few programs are user-configurable app defaults in the settings rather than hardcoded dependencies: `kitty`, `fish`, `dolphin`, `pavucontrol` (or `pavucontrol-qt`), `plasma-systemmonitor` and the `kcmshell6` Plasma settings modules (packages `kitty`, `fish`, `dolphin`, `pavucontrol`, `pavucontrol-qt`, `plasma-systemmonitor`, `kcmutils`), which open system monitors, mixer, user and Bluetooth settings. Gnome keyring sync (`gnome-keyring`) and `gvfs` are strictly optional.

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
