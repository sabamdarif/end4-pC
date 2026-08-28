# Implementation Plan — todo.md

## Context

`todo.md` holds ~24 items for this Quickshell (QML) desktop shell — a fork of end-4's illogical-impulse dots, dual-WM (Hyprland/niri). Recent commits focused on the settings app rewrite, app launcher rewrite, and the wallpaper/matugen color pipeline. This plan turns the todo into ordered, scoped work. Progress is tracked live in `tasks.md`.

**Key discoveries that shrink the work:**
- Android 12-style quick toggles **already exist** (`modules/ii/sidebarRight/quickToggles/androidStyle/`, default `style: "android"` in `Config.qml:714`) — that todo item is done, just verify.
- Battery sound infra already exists (`services/Battery.qml` uses `Audio.playSystemSound()`, gated by `Config.options.sounds.battery`) — the 20%/15% item is just thresholds.
- `services/Updates.qml:51` already counts pacman+AUR — flatpak is a one-line addition.
- Screenshot infra exists (`modules/common/utils/ScreenshotAction.qml`, `modules/ii/regionSelector/RegionSelector.qml`).
- Settings deep-linking (`goTo(term)` per page, `GlobalStates.settingsPage`) exists — settings search can reuse it instead of new plumbing.

## Conventions (apply to every task)

- New options: declare default in `modules/common/Config.qml`, bind widget in the right `modules/ii/settings/pages/*.qml` (use `SoundConfig.qml` as template: `ContentSection` → `GroupedList` → `ConfigSwitch`/`ConfigRow`).
- New top-level windows register in `panelFamilies/IllogicalImpulseFamily.qml` via `PanelLoader`.
- Anything WM-facing must branch on `NiriData.isNiri`.
- User-visible strings go through `Translation.tr()`.
- Update `tasks.md` status when starting/finishing an item.

---

## Phase 0 — Docs (do first, informs everything)

### T01. Add CLAUDE.md + AGENTS.md
Write repo docs from the codebase map + last ~10 commits: stack (Quickshell/QML, no build system, live-reload), directory layout (`shell.qml` → `panelFamilies/` → `modules/ii/*`, `services/` singletons, `modules/common/Config.qml` as the options schema), the Config/settings-page pattern, dual-WM branching, and recent work areas (settings pages, launcher, wallpaper pipeline). AGENTS.md = same content, agent-oriented (conventions above + gotchas: hardcoded About index `SettingsContent.qml:58`, system prompt duplicated in `Config.qml:89` + `defaults/ai/prompts/ii-Default.md`).

---

## Phase 1 — Small fixes (each ≤ ~30 lines)

### T02. Bluetooth connect feedback
`services/BluetoothStatus.qml`: on device connected/disconnected, fire a notification (`NotificationUtils`) and/or `Audio.playSystemSound("device-added"/"device-removed")`.

### T03. rfkill bluetooth block fix
Bluetooth toggle (`androidStyle/AndroidBluetoothToggle.qml` + classic counterpart): when adapter is rfkill-blocked, toggle must `rfkill unblock bluetooth` before powering on. Reproduce first, fix in the shared service (`BluetoothStatus.qml`), not per-toggle.

### T04. Low battery sounds at 20% and 15%
`services/Battery.qml`: it already plays warning sounds — adjust/add thresholds so first warning fires at 20%, second at 15%. Check existing `Config.options.battery.low`-style options before adding new ones.

### T05. Battery popup Health shows N/A
`modules/ii/bar/BatteryPopup.qml:81` — `Battery.health` is unavailable on some hardware. Map to words: ≥80 "Good", ≥50 "Fair", else "Poor"; hide or show "Good" when UPower reports nothing (verify what `services/Battery.qml` exposes on this machine).

### T06. Android-like battery icon
`modules/ii/bar/BatteryIndicator.qml`: restyle to Android's vertical/rounded pill with percentage inside. Pure QML restyle, no service changes.

### T07. Auto-close popups in control center
Sidebar-right popup menus (network/bluetooth expandables in `modules/ii/sidebarRight/`): close on click-outside / when another opens / when sidebar hides. Find the open-state property and reset it centrally.

### T08. Fix color picker
Reproduce first: `modules/common/models/quickToggles/ColorPickerToggle.qml` + `AndroidColorPickerToggle.qml`. Likely hyprpicker-on-niri breakage — branch on `NiriData.isNiri` (niri has its own picker action) or missing binary fallback.

### T09. Settings first-load: text drops below icon
Nav rail items in `modules/ii/settings/SettingsContent.qml` mis-measure before fonts/icons load. Fix the layout binding (fixed height or anchor instead of implicit height race).

### T10. Update indicator: pacman + AUR + flatpak
`services/Updates.qml:51`: append `flatpak remote-ls --updates 2>/dev/null | wc -l` to the count command. Show a per-source breakdown in the indicator tooltip if it already has one; otherwise total only.

### T11. Screenshot: default fullscreen, Alt = area
`modules/common/utils/ScreenshotAction.qml` + `modules/ii/regionSelector/RegionSelector.qml` + bar `UtilButtons.qml`/`ScreenSnipToggle.qml`: default action captures full screen; holding Alt (or Alt+key variant in WM binds) opens region selector. Update Hyprland and niri keybinds.

---

## Phase 2 — Settings app improvements

### T12. Rearrange settings pages
Reorder the `pages` array (`SettingsContent.qml:64-79`) into a sensible order (Quick → General → Appearance-ish → Sound → Network → Apps → Services → WM → Shortcuts → About). **While there:** replace the hardcoded `currentPage === 11` About check (line ~57) with a name lookup so reordering can't break it again.

### T13. Settings search
Add a search field above the nav rail. Index = page name + each page's `ContentSection` titles (the duplicated `goTo(term)` already navigates+highlights). Selecting a result sets `GlobalStates.settingsPage = "Page:term"`. Skip full-text indexing of every widget — section titles are enough.

### T14. DNS providers as dropdown + custom
`modules/ii/settings/pages/NetworkConfig.qml`: replace provider list with a ComboBox (Cloudflare, Google, Quad9, AdGuard, ... , "Custom"). "Custom" reveals a text field. Wire to existing `NetworkExtras.readDns`/set logic.

### T15. Add matugen theme from settings app
Settings option to register a custom matugen scheme: a form writing a user template/config under `~/.config/illogical-impulse/`, picked up by `scripts/colors/switchwall.sh` + `scripts/colors/matugen/`. Scope: name + scheme-type + optional custom colors; not a full theme editor.

### T16. Option to fully disable left sidebar
New `Config.options.sidebar.leftEnabled` (check existing sidebar config group naming first); gate the `SidebarLeft` `PanelLoader` in `IllogicalImpulseFamily.qml` and its keybind/edge-trigger. Add switch in InterfaceConfig.

### T17. Change system sounds (Android-style)
Settings UI listing the shell's system-sound events; per-event "pick file" copies the chosen file to `~/.config/illogical-impulse/sounds/` (the "safe folder") and stores the path in Config. `Audio.playSystemSound()` checks the override map before falling back to the theme sound. Add a "reset to default" per event.

### T18. Wallpaper-based color scheme combinations (Android-like)
Matugen supports scheme variants (tonal-spot, expressive, vibrant, neutral, fidelity...). After wallpaper switch, generate/preview N variant combos and let the user pick — UI in the wallpaper picker (`modules/ii/wallpaperSelector/`), plumbing in `scripts/colors/switchwall.sh` + `services/Wallpapers.qml`. Check what scheme option already exists in the pipeline before adding.

### T19. All Apps page
New settings page (or section under Apps): merged list from pacman + flatpak (`services/AppSearch.qml` already lists desktop apps — reuse). Per app: Open, Uninstall (pkexec pacman -R / flatpak uninstall), storage used, clear-data where supported (flatpak per-app data dir). **Permissions sub-page (mic/camera/notifications) is flatpak-only realistically (`flatpak permission-*`)** — ship list+open+uninstall+storage first, permissions as follow-up.

---

## Phase 3 — Bigger features

### T20. Screenshot annotation editor
After capture, open image in a new panel window: crop, freehand/lines, rectangles/arrows, then save over original / copy to clipboard. Before building: check if reusing `swappy` or `satty` (spawn with the file) satisfies this — a proven annotator via one `Process` line beats a custom QML canvas editor. Build custom only if the user rejects external tools.

### T21. App launcher: Google-search style, always on top
`modules/ii/overview/Overview.qml`: switch `WlrLayer.Top` → `WlrLayer.Overlay` (always over any window, incl. fullscreen). Restyle `SearchWidget.qml`/`SearchBar.qml`: prominent centered pill search bar, results dropping below it, Google-ish spacing.

### T22. Noctalia-style lock screen
Study noctalia-shell's lock screen (github.com/noctalia-dev/noctalia-shell), reimplement look in `modules/ii/lock/{Lock,LockSurface}.qml` reusing existing auth plumbing (`PasswordChars.qml`, pam flow) and `LockWallpaperColorGen.qml`. Port the visuals, not their service layer.

### T23. Android 12 quick toggles — verify only
Already implemented (`AndroidQuickPanel.qml`, 19 android-style toggles, default style). Confirm it matches what was wanted, mark done, or note deltas.

### T24. Sidebar AI system prompt update
`todo.md` contains a prompt block — sync it into `Config.qml:89` (escaped default) **and** `defaults/ai/prompts/ii-Default.md` (they must not drift). If the block matches what's already there, item is done.

---

## Order of execution

Phase 0 → Phase 1 (any order, all independent) → Phase 2 (T12 before T13; rest independent) → Phase 3. Each task = its own commit.

## Verification

- Live-reload Quickshell (`qs` restarts on file save) after each change; check `qs log` for QML errors.
- Per-task manual checks: toggle the feature via its UI (settings switch, bar button, keybind) on **both** Hyprland and niri where WM-dependent (T08, T11, T16, T21, T22).
- T04/T05: `upower -i $(upower -e | grep BAT)` to compare reported values with UI.
- T10: run the count command manually with a pending flatpak update.
- T19: uninstall a throwaway package (e.g. a flatpak) end-to-end.
- Update `tasks.md` status (⬜ → 🟨 in progress → ✅ done) as each task moves.
