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
The shortcuts page loading check uses an isolated config on a running Wayland compositor
and skips when no compositor is available.

For the Quickshell check, a timeout is expected if the shell remains running. Confirm the log reaches `Configuration Loaded` and inspect new QML errors. Existing environment warnings, such as a missing compositor connection or another notification server, may be unrelated.

Manually exercise affected UI. Test scripts and command integrations independently with non-destructive data. Never claim a check that was not run.

## Documentation

`README.md` is the source of truth for user-visible installation and usage. Update it with behavior changes. Keep contributor-only architecture, invariants, and workflow here.

## Material 3 Expressive UI/UX

Follow Android Material 3 Expressive principles using `Appearance` (`modules/common/Appearance.qml`) and `modules/common/widgets/`. Apply expression selectively by hierarchy:

- **Quiet (default)**: settings forms, dense lists, utility rows, static containers.
- **Clear**: navigation selection, active tabs, secondary containers, toggle states.
- **Expressive (sparingly)**: at most 1 primary CTA per action group, key state transitions, media/progress focal points, and hero indicators.

### Core Rules & Anti-Patterns

- **No raw clickable rectangles**: never build buttons or interactive rows out of bare `Rectangle` + `MouseArea`. Use `RippleButton`, `GroupButton`, `DialogListItem`, `ToolbarButton`, or `StateOverlay`/`StateLayer` with `PointingHandCursor`.
- **No hardcoded tokens**: bind `Appearance.colors.*`, `Appearance.rounding.*`, `Appearance.font.*`, and `Appearance.animation.*`. Never hardcode hex colors, pixel radii, font sizes, or custom easing durations when a token fits.
- **Tonal elevation first**: express hierarchy with `colLayer0`..`colLayer4` (`m3surfaceContainer*`) before borders or shadows. Reserve `StyledRectangularShadow` for floating layers (`StyledPopup`, `Toolbar`, `FloatingActionButton`, `WindowDialog`).
- **Compositor blur boundary**: only top-level shell surfaces (`colLayer0Blurred`/`colLayer1Blurred` + `BackgroundEffect.blurRegion`) and `WindowGlass` use translucency. Keep inner cards, settings rows, forms, and dialogs solid tonal surfaces, never ad-hoc frosted glass.
- **Containment discipline**: avoid nested cards (max 2 containment levels from surface to content). Prefer `GroupedList` or `ContentSection` spacing over wrapping every item in individual boxes, and never stack modals.
- **Stable geometry**: render borders, focus rings, and selection highlights inside fixed bounds (`outline` / `colPrimary`) so hover, focus, or error states never shift adjacent items.

### Motion Physics (`Appearance.animation` & `Appearance.animationCurves`)

Split motion strictly into **Spatial** (position, size, scale, corner radius, rotation; overshoots) and **Effects** (color, opacity, ripple fade; zero overshoot):

| Role | Token | Curve / Timing | Use For |
|---|---|---|---|
| Small spatial | `elementMoveSmall` | `expressiveFastSpatial` `[0.42, 1.67, 0.21, 0.90]`, 350 ms | Switches, small buttons, `ShapeCanvas` morphs, `Carousel` item resize |
| Default spatial | `elementMove` | `expressiveDefaultSpatial` `[0.38, 1.21, 0.22, 1.00]`, 500 ms | List `add`/`remove`/`displaced`, drawers, sheets, radio dot scale |
| Slow spatial | `expressiveSlowSpatial` | `[0.39, 1.29, 0.35, 0.98]`, 650 ms | Full-panel or large layout transitions |
| Click bounce | `clickBounce` | `expressiveDefaultSpatial`, 400 ms (`alwaysRunToEnd`) | `GroupButton` press/release width & scale bounce |
| Effects | `elementMoveFast` | `expressiveEffects` `[0.34, 0.80, 0.34, 1.00]`, 200 ms | Color, opacity, state layers, wave amplitude toggles (150 ms for micro fades) |
| Enter / Exit | `elementMoveEnter` / `Exit` | `emphasizedDecel` 400 ms / `emphasizedAccel` 200 ms | Entering/exiting elements, progress value smoothing |
| Resize / Scroll | `elementResize` / `scroll` | `emphasized` 300 ms / `standardDecel` 200 ms | Container resizing, smooth wheel scrolling |
| Utilitarian | `menuDecel` | `Easing.OutExpo`, 350 ms | Dropdown/split-chevron `180` deg rotation, dense utility transitions (no bounce) |

- All animations must be interruptible (`Behavior` or state-driven) and converge to the current state.
- Never run perpetual idle animations (only active loading/playback waves), never hover-lift cards, and never move a hit target away from the pointer on hover.

### Click, Press, Hover & Focus Feedback

- **Required states**: cover `default`, `hovered` (`0.08` state layer), `focused` (`0.10`), `pressed` (`0.10`), `dragged` (`0.16`), `selected`/`toggled`, `disabled` (`opacity: 0.4` or `colLayer2Disabled`/`colOnLayer2Disabled`), `loading`, and `error` (`colError*`).
- **Press morph & ripple**: standard buttons (`RippleButton`) show radial press ripple + `colLayer*Hover`/`Active` color transitions (`elementMoveFast`) and can tighten `buttonRadiusPressed < buttonRadius`.
- **Hover & focus**: hover is supplementary only; never hide essential actions behind hover. Keyboard-focusable controls must show a distinct focus border/ring in all themes (`colOutline` / `colPrimary`, `>= 3:1` contrast).

### Shapes & Corner Morphing (`Appearance.rounding` & `shapes/`)

- **Radius scale**: `unsharpen` (2), `unsharpenmore` (6), `verysmall` (8), `small` (12), `normal` (17), `large` (23), `verylarge` (30), `full` (9999). Match role-mates; do not make every element a capsule.
- **Optical concentricity**: nested items use `innerRadius = Math.max(Appearance.rounding.unsharpen, outerRadius - padding)`.
- **State morphing**: pill/round buttons (`full`) morph toward `small`/`verysmall` while pressed; toggle buttons swap between `full` (round) and `small`/`normal` (square) on selection.
- **Connected button groups**: `2` px spacing, outer ends `full` (or container radius), shared inner corners `unsharpen`..`unsharpenmore`, morphing only the active/pressed item to `full` without pushing neighbors.
- **35-shape library (`MaterialShape` / `ShapeCanvas`)**: use polygons/cookies/clovers for section badges (`MaterialShapeWrappedMaterialSymbol`), avatars, cover masks, and `MaterialLoadingIndicator`. Never crop readable text inside novelty shapes.

### Colors & Typography (`Appearance.colors` & `Appearance.font`)

- **Color hierarchy**: `colPrimary`/`colOnPrimary` for primary emphasis (max 1 filled CTA per group); `colSecondaryContainer`/`colOnSecondaryContainer` for active pills, tabs, and toggles; `colTertiaryContainer` for paired accent actions (`ToolbarPairedFab`); `colError*` strictly for errors/destructive states. Maintain `>= 4.5:1` text contrast and `>= 3:1` UI/icon/track contrast (`colOutline` for interactive bounds, `colOutlineVariant` only for subtle dividers).
- **Fonts & variable axes**: use `StyledText` with `Appearance.font.pixelSize.*` (`smallest` 10 .. `hugeass` 23) and `Appearance.font.family.*` (`main`/`title`/`numbers`: `"Google Sans Flex"`, `iconMaterial`: `"Material Symbols Rounded"`, `monospace`/`iconNerd`: `"JetBrains Mono NF"`, `reading`: `"Readex Pro"`, `expressive`: `"Space Grotesk"`).
- **Dynamic weight/width & numerals**: apply `Appearance.font.variableAxes` (`main` `wght: 450, wdth: 100`; `title` `wght: 550`), bump `wght` on active/emphasized headers, badges, or unread counts, and use tabular figures (`font.features: { "tnum": 1 }` / `numbers` family) on clocks, timers, and updating counters to stop jitter. Use `StyledText.animateChange: true` for dynamic status swaps. Never clip wrapped or scaled text in fixed-height boxes.

### Component Implementation Rules

| Element | Canonical Widget(s) | Required M3 Expressive Behavior |
|---|---|---|
| **Buttons / Icon Buttons** | `RippleButton`, `ToolbarButton`, `IconToolbarButton`, `DialogButton` | `PointingHandCursor`, ripple + hover/active color mix, `buttonRadiusPressed` morph on press, `StyledToolTip` for icon-only controls, `fill` `0 -> 1` (outlined -> filled icon) when toggled. Keep touch/click target `>= 40..48` px where layout allows. |
| **Standard Button Groups** | `ButtonGroup`, `VerticalButtonGroup` + `GroupButton` | `clickBounce` width/height spring + `buttonRadiusPressed` morph on press; adjacent siblings expand/compress cleanly (`clickIndex` neighbor push). Avoid text-only/borderless buttons inside groups. |
| **Connected / Segmented Groups** | `ConfigSelectionArray`, `SelectionGroupButton` | `2` px inner gap, outer corners `full`, inner corners `unsharpenmore`, active item morphs to `full` + `colSecondaryContainer` (or `colPrimary`) without shifting neighbors. |
| **FAB & Split Actions** | `FloatingActionButton` (56 px, `16` px radius, `colPrimaryContainer`), `ToolbarPairedFab` (48 px, `colTertiaryContainer`) | Max 1 FAB per view for primary creation/action (never destructive/minor). Split button pairs use `2` px gap, `4..8` px inner corners that morph on press, and `180` deg chevron rotation via standard easing (`menuDecel`/`elementMoveFast`). Avoid legacy `Fab.qml`. |
| **Switches & Radios** | `StyledSwitch` (`ConfigSwitch`), `StyledRadioButton` | Switches act immediately (never add a Save button): ON uses `colPrimary` track + `colOnPrimary` thumb with `check` icon; OFF uses `m3surfaceContainerHighest` track + `2` px `colOutline` border + `colOutline` thumb with `close` icon; thumb stretches on press and slides with `expressiveFastSpatial`. Radios animate inner dot scale with `elementMove` and show hover/focus halo. |
| **Sliders** | `StyledSlider` (`ConfigSlider`) | Use `Configuration` (`S` default in settings, `Wavy`, `XS`..`XL`), full pill outer track ends (`trackWidth / 2`) + `unsharpen` (`2` px) inner corners with clear gaps on both sides of the tall `4` px vertical handle (narrows and grows slightly on press), `stopIndicatorValues` dots for discrete/end contrast, `StyledToolTip` value bubble on drag, and `WavyLine` active track for media/expressive sliders. |
| **Progress & Loading** | `MaterialLoadingIndicator`, `ConnectingWave`, `StyledProgressBar`, `CircularProgress`, `WaterWaveProgress`, `ClippedProgressBar` | Wait `< 200 ms`: no indicator. Wait `200 ms..5 s` or indeterminate refresh: `MaterialLoadingIndicator` (7 morphing shapes; contained `colPrimaryContainer` over media/content) or `ConnectingWave`. Determinate / `> 5 s`: `StyledProgressBar` (`wavy: true` for media, flat `4` px for compact slots, `valueBarGap`, end stop dot) or `CircularProgress`/`WaterWaveProgress` (wavy when active, smooth flat ring when paused). Never block whole screens for local ops. |
| **Toolbars & Tabs** | `Toolbar`, `ToolbarTabBar`, `IconAndTextToolbarButton` | Pill container (`56` px height, `colLayer1Blurred`, `StyledRectangularShadow`), staggered stretch-and-settle `colSecondaryContainer` tab pill indicator, rounded icons inside rounded toolbars (no square icon buttons inside floating pill toolbars). Never show bottom toolbar alongside a bottom dock/nav bar on the same edge. |
| **Lists, Cards & Settings** | `ContentPage`, `ContentSection`, `GroupedList`, `StyledListView`, `StyledFlickable`, `DialogListItem` | Settings use `ContentPage` + `ContentSection` + `GroupedList` (`colLayer1` cards, `normal` outer / `unsharpenmore` inner radii, `2` px gap) + `Config*` controls. Dynamic lists use `StyledListView` (`elementMove` transitions, `scroll` wheel behavior) and `DialogListItem` / `RippleButton` rows. Never leave hidden items as blank `GroupedList` slots. |
| **Dialogs, Sheets & Popups** | `DialogSheet`, `WindowDialog`, `StyledPopup`, `StyledComboBox`, `StyledComboBoxSearch` | Sidebar sheets use `DialogSheet` (`600` px max height, `busy` bar, `DialogButton` footer). Anchored bar popups use `StyledPopup` (`dismissOnOutsideClick`, `BackgroundEffect.blurRegion`, `WindowGlass`). Dropdowns use `StyledComboBox*` (pill trigger, rotating chevron, `StyledListView`). |
| **Text Fields & SpinBoxes** | `MaterialTextField`, `MaterialTextArea`, `ToolbarTextField`, `StyledSpinBox` (`ConfigSpinBox`) | Keep persistent labels/placeholders and `IBeamCursor`; highlight errors with `colError` without clearing user text; save SpinBox changes via `valueModified` only. |
| **Carousels & Edge-Hugging UI** | `Carousel`, `AndroidClock`, circular gauges | `Carousel` resizes items via `elementMoveSmall` on focus/hover. Circular/pill edge widgets maintain concentric spacing (`innerRadius = outerRadius - padding`) without clipping at high font scales. |

Do not introduce new dependencies on legacy widget duplicates (`SettingsPage`, `SettingsSection`, `Setting*Row`, `Fab`, `FlowButtonGroup`, `StyledPopupMenu`, `ListRow`); migrate touched UI to the canonical widgets above.

## Architecture

```text
shell.qml -> panelFamilies/ -> modules/ii/ -> modules/common/ and services/ -> scripts/
```

- `shell.qml`: initializes services and loads the selected panel family.
- `panelFamilies/IllogicalImpulseFamily.qml`: registers top-level panels through `PanelLoader`.
- `modules/ii/`: feature UI, including the bar, settings, launchers, sidebars, lock screen, wallpaper picker, and toggles.
- Desktop widgets live under `modules/ii/background/`. The separate gaming/tool overlay and its IPC target are removed; keep the shared widget canvas for desktop widgets.
- Desktop and lock-screen clocks share `modules/ii/background/widgets/clock/ClockContent.qml`. The lock surface renders it directly, without desktop dragging or placement logic. `clock.disableOnLock` gates only the lock clock; `clock.enable` gates both.
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
- URL-loaded leaf pages must explicitly import `"."` to use sibling QML components.
- The rail collapses to group icons below 900 px and closes after selecting a leaf;
  clicking a group icon reopens the rail on that group.

### Niri settings synchronization

- `NiriConfig` reads effective scalar settings from `config.kdl` and its includes through
  `scripts/niri/config-settings.py`. The helper follows include order and niri's merge rules,
  validates with `niri validate`, and reports both symlink paths and targets for `FileView`
  watchers. It never writes user files. JSON remains the store for shell-managed lists,
  not the authority for scalar compositor values.
- Loading or refreshing settings must not generate overrides. Scalar edits update only
  changed KDL nodes; pointing-device and XKB edits retain their complete effective blocks
  because niri replaces those sections. Existing generated overrides are preserved.
  `configReloaded` refreshes shortcuts, autostart and connected-output views.
- Niri number controls save through `ConfigSpinBox.valueModified`, not `valueChanged`.
  Binding updates and UI range clamping must never rewrite compositor settings.
  `StyledSpinBox` uses a direct text-input content item so Qt handles user editing.
- `externalWindowRules` lists full rules and their source files separately from the
  shell-managed editor. Never flatten multiple match groups or drop unknown properties
  when displaying user rules; source-file editing preserves those constructs.

### Keyboard shortcuts

- `NiriKeybinds` reads included shortcuts through `scripts/niri/list-binds.py`.
  `services/NiriShortcuts.js` normalizes keys using niri's configured Mod key,
  groups actions, filters search and converts capture events. The settings leaf
  keeps dux-shell's grouped rows and lazy modal editor with local Material widgets.
- Shortcut edits retain bind properties and go through `NiriConfig` validation
  before updating `bindOverrides`. The helper checks the candidate's structure
  and runs `niri validate` on a temporary file. Never persist raw action text
  without this validation, or modify user-owned bind files.
- Removing an override restores any original config bind. Moving an override
  changes only shell-managed entries; `New key` adds a separate key for the action.
  Keep the dux-shell MIT notice in `assets/licenses/dux-shell.txt`.

### Wallpaper colors

- `scripts/colors/switchwall.sh` owns wallpaper changes and invokes `scripts/colors/matugen.py`.
  Matugen is the only palette generator; Python only installs, filters and publishes templates.
- `$XDG_CONFIG_HOME/matugen/config.toml` is the single user-editable Matugen configuration.
  `SystemTheming` watches `config.toml` directly without polling or rewriting it, and
  `load_config()` falls back in memory only for `quickshell` and `quickshell-seed` when an
  existing `config.toml` omits them. `appearance.matugenDisabled` filters invocations;
  wallpaper theming flags gate terminal and Qt templates.
- Default templates and initial `config.toml` in `scripts/colors/matugen/` install into
  the user's Matugen directory when missing. `shell.qml` initializes `SystemTheming`, which
  runs setup after `Config.ready`. Normal generation also ensures setup. Generic filenames
  preserve existing custom files during prefixed-name migration. Existing `config.toml`
  edits and templates are never replaced by bundled defaults. Old generated configurations
  migrate from `.orig` once, retaining backups.
- Setup grants a persistent user-wide Flatpak override for read-only GTK 3/4 config access while
  shell/app theming is enabled. It checks existing permissions before writing and leaves app-specific
  denials alone. Lock generation never runs setup or changes sandbox permissions.
- Shell and terminal JSON are validated and atomically published. Lock generation selects only
  the shell template, strips hooks and writes `colors-lock.json`, never live app state.
- Terminal force-dark copies templates with `.default.` changed to `.dark.` for that invocation.
  Qt palette selection preserves existing style settings. GTK 3 and GTK 4 have separate templates
  because modern libadwaita CSS variables are not valid GTK 3 properties.

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
  The bar's Storage manager switches views inside `RemovableDrivePopup`; shared
  storage content is in `modules/ii/sidebarRight/drives/DriveList.qml`.
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
