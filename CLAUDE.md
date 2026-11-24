# end4-pC

A personal fork of [pctrade/end4-pC](https://github.com/pctrade/end4-pC), itself a fork of end-4's illogical-impulse desktop shell. This fork targets niri only, and adds personal features. Its design follows Android's Material 3 Expressive guidelines, continuing the visual direction of pctrade/end4-pC. It is a live-reloaded Quickshell/QML application for Wayland. `shell.qml` is the entry point; there is no conventional compile step.

## Hard requirements

- **niri only.** There is no Hyprland support and no compositor abstraction layer. Talk to the compositor through `services/NiriData.qml`, `services/NiriConfig.qml` and `niri msg`; never add `hyprctl`, `Quickshell.Hyprland` or a second compositor branch.
- **Preserve the visual language.** Reuse existing Material 3 Expressive components, `Appearance` values, symbols, and responsive patterns.
- **Translate user-visible text.** Route it through `Translation.tr()`.
- **Register top-level panels.** Import and register them in `panelFamilies/IllogicalImpulseFamily.qml`.
- **Never hardcode settings page indexes.** Use stable keys or names.
- **Keep this file accurate and below 1000 lines.** Update it when architecture or workflow changes.

## How to Work Here

### Output style

- Use a casual, brief tone. Do not repeat the request.
- Work silently. Speak only for a blocking question, a useful finding, or the final result.
- Never expose reasoning traces or narrate tool calls.
- Never use an em dash, or `--` as punctuation, in replies, code comments, docs, or commit messages.
- Use Markdown. Prefer short sections and bullets for longer answers. Use tables first for comparisons, then give a recommendation.
- Explain unfamiliar concepts plainly when asked.

### Before implementing

For anything beyond a small fix, make and scrutinize a plan before editing. Check this repository's existing patterns and the idiomatic QML, JavaScript, Python, or shell solution. Prefer the smallest solution that meets this project's constraints, not the first generic pattern found.

### YAGNI

Stop at the first option that works:

1. Skip speculative work.
2. Reuse a repository helper or pattern.
3. Use the language or platform standard library.
4. Write the minimum new code.

Do not add one-use abstractions, future configuration, parallel infrastructure, or explanatory clutter. Never omit validation at trust boundaries, security checks, or error handling that prevents data loss.

### Comments

Write a comment only when a future reader could reasonably misunderstand an invariant or non-obvious constraint. Keep it to one or two lines above the relevant function or block. Do not restate code, describe the recent change, or reference local and ephemeral files.

### Coding rules

- Keep code cohesive and easy to locate. Do not split simple behavior across unnecessary files.
- Preserve unrelated local changes. Do not delete, overwrite, force-push, or otherwise perform destructive actions without explicit approval.
- Keep comments and documentation synchronized with behavior.
- Follow `.editorconfig`. If it is absent and indentation is unclear, follow neighboring files rather than reformatting unrelated code.
- Put shared state and actions in `services/` when multiple UI components use them.
- Use `Quickshell.execDetached()` for fire-and-forget commands. Use `Process` when output, exit state, or cancellation matters.
- Prefer desktop trash for user-data removal when practical.
- Add focused tests for verifiable new behavior. Do not add tests that only confirm deletion.

### Commit messages

Use Conventional Commits: `type(scope): subject`. Choose from `fix`, `feat`, `test`, `refactor`, `docs`, or `chore`. Add a body only when the subject cannot carry the reason, and keep it to two or three sentences. Never list the diff in the body.

## Build, Test, Lint

Run checks appropriate to the change:

```bash
python3 -m unittest discover -s tests -v
python3 scripts/niri/test_autostart_entries.py
git diff --check
timeout 15s qs -p .
```

The regression suite uses temporary data, offscreen Quickshell fixtures, and private D-Bus
sessions. Tests requiring `qs`, `dbus-run-session`, `notify-send`, `cliphist`, or Python
PyGObject (`gi`) skip when those dependencies are absent. Shell helper tests also need
Bash and the usual core utilities. Set `TMPDIR` to a writable scratch directory if needed.

For the Quickshell check, a timeout is expected if the shell remains running. Confirm the log reaches `Configuration Loaded` and inspect new QML errors. Existing environment warnings, such as a missing compositor connection or another notification server, may be unrelated.

Manually exercise affected UI. Test scripts and command integrations independently with non-destructive data. Never claim a check that was not run.

## Documentation

`README.md` is the source of truth for user-visible installation and usage. Update it with behavior changes. Keep contributor-only architecture, invariants, and workflow here.

## Architecture

```text
shell.qml -> panelFamilies/ -> modules/ii/ -> modules/common/ and services/ -> scripts/
```

- `shell.qml`: initializes services and loads the selected panel family.
- `panelFamilies/IllogicalImpulseFamily.qml`: registers top-level panels through `PanelLoader`.
- `modules/ii/`: feature UI, including the bar, settings, launchers, sidebars, lock screen, wallpaper picker, and toggles.
- `modules/common/`: shared configuration, functions, models, utilities, and widgets.
- `services/`: singleton state and system integrations.
- `scripts/`: Python and shell helpers for integrations unsuitable for QML.
- `defaults/`: default user-facing content.
- `translations/`: translation catalogs and tooling.

### Settings storage

- `Directories.shellConfig` is `$XDG_CONFIG_HOME/qssettings`, with `config.json`,
  `actions/`, and `sounds/`. UI links use `Directories.shellConfigPath`, not a literal path.
- Shell helper scripts read `$XDG_CONFIG_HOME/qssettings/config.json`, with the normal
  `$HOME/.config` fallback. Niri settings stay under `$XDG_CONFIG_HOME/niri/qssettings`.

### Settings navigation

`modules/ii/settings/SettingsPages.qml` is the single registry for the settings window's
two-level nav rail: collapsible groups of leaf pages, ordered after Android's Settings.
`modules/ii/settings/SettingsContent.qml` renders it and `services/LauncherSearch.qml`
reuses it for the launcher's `settings:` search, so neither keeps its own page list.

- One leaf page is one `ContentPage` holding only its own sections, under
  `modules/ii/settings/pages/<group>/`.
- Every leaf has a stable, untranslated `key`. `GlobalStates.settingsPage` takes
  `"<leafKey>[:<sectionTitle>]"` for deep links.
- Leaf pages build on first visit and stay alive afterwards. `ContentPage.goTo(term)`
  scrolls to a matching section or subsection; leaf pages do not define their own copy.
- The rail collapses to group icons below 900 px and closes after selecting a leaf;
  clicking a group icon reopens the rail on that group.

### Adding a setting

1. Add the default to the appropriate `JsonObject` in `modules/common/Config.qml`.
2. Bind it on the leaf page that owns it under `modules/ii/settings/pages/<group>/`.
3. Reuse `ContentSection`, `GroupedList`, `ConfigRow`, `ConfigSwitch`, `ConfigComboBox`, or neighboring components.
4. Gate the feature where it is created or activated, not only in settings UI.
5. For a whole new page, add the `ContentPage` and register it as a leaf in `SettingsPages.qml`.
6. Ensure translated section titles work with `ContentPage.goTo(term)` settings search.

Dynamic lists commonly use `Rectangle`, `ColumnLayout`, and `Repeater`. `GroupedList` is mainly for static children.

### Compositor blur

niri blurs a layer surface only when the surface asks for it through
`ext-background-effect-v1` and is translucent; the generated `blur {}` block in
`qssettings/shell.kdl` only sets strength. Both halves are shell-side:

- `Appearance.blurActive` follows `NiriConfig.options.decoration.blur.enable`.
- `Appearance.panelOpacity` and `colLayer0Blurred`/`colLayer1Blurred` make panel
  backgrounds translucent while blur is on and restore full opacity when it is off.
  `Config.options.appearance.transparency.blurOpacity` is the panel alpha.
- A window opts in with `BackgroundEffect.blurRegion: <region>`. Build the region
  from the painted background item, not the window, so transparent areas and
  hidden pills never blur the wallpaper behind them.

`BackgroundEffect` comes from `Quickshell.Wayland`; a window only needs that one
binding because Quickshell re-publishes the region when the surface remaps.

### Sidebar dialogs

Every sheet the right sidebar opens is a `DialogSheet` (`modules/common/widgets/`), so
they all share one height, position, title rule and footer. Declare only the body:

```qml
DialogSheet {
    title: Translation.tr("Connect to Wi-Fi")
    busy: Network.wifiScanning     // swaps the title rule for a progress bar
    edgeToEdge: true               // lists and rows reach the sheet edges
    settingsPage: "wifi"           // adds a Details button that deep links there
    leadingActions: DialogButton {} // footer left; trailingActions sits before Done
    ListView {}
}
```

`WindowDialog` freezes its height when it opens, so a sheet cannot grow past
`backgroundHeight`; keep the body within it rather than raising the shared value.
Register a new sheet as a `ToggleDialog` in `SidebarRightContent.qml`, and reach it from
a quick toggle through `AbstractQuickPanel`'s `open<Name>Dialog` signal.

### Window rules, drives and wellbeing

- `NiriConfig.options.windowRules` holds `{name, enabled, match, properties}` rules.
  All matcher attributes belong to one `match` node, so niri ANDs them. UI saves
  validate a candidate fragment with `niri validate` before updating settings;
  the debounced writer generates `windowrules.kdl`. Never write raw property KDL
  from text fields. The active-window menu hands a draft to the stable
  `window-rules` settings page through `NiriConfig.pendingWindowRule`.
- Click-open bar popups use `StyledPopup.dismissOnOutsideClick`. Their dismiss
  catcher is a transparent niri layer surface, not a compositor focus grab.
- `GlobalStates.openSidebarDialog("drives" | "screentime")` retains its request
  until the lazy `SidebarRightContent` exists. Do not replace this with a signal
  emitted only to the unloaded sidebar.
- `Drives` polls only while a drive widget is configured or a storage sheet
  subscribes. `scripts/system/drives_info.py` owns discovery and SMART parsing.
  Ejection queues ordinary unmounts before power-off and stops on any failure;
  health checks never escalate privileges automatically.
  MTP phones come from Gio's GVfs volume monitor, not lsblk. Their identifiers and
  mount points are `mtp://` URIs; use `gio mount` to connect/disconnect them, never
  udisksctl or smartctl. Do not report virtual filesystem capacity as phone storage.
- `ScreenTime` is initialized by `shell.qml`, independently of widget visibility.
  Its tracker receives shell lock/idle state on stdin and also checks loginctl.
  Private, atomic `qssettings/screentime.json` stores a versioned `days` array,
  retaining 92 local calendar days with optional hourly totals. Invalid history
  must stop tracking rather than reset it. Limits live in `Config.options.wellbeing`
  and emit once-per-app/day session reminders, never app-blocking actions.
- `services/Wellbeing.js` adapts dux-shell date/chart helpers. Keep the upstream
  MIT notice in `assets/licenses/dux-shell.txt`. Shared wellbeing UI lives in
  `modules/ii/sidebarRight/screentime/` and is reused by the settings leaf.
- Wi-Fi QR images contain credentials. `scripts/network/wifi_qr.py` sends their
  payload to qrencode on stdin, uses private runtime files, and atomically saves
  exported images with mode 0600. Never put passwords or Wi-Fi payloads in argv.
