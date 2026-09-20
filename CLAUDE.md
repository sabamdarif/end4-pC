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
git diff --check
timeout 15s qs -p .
```

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
- The rail collapses to group icons below 900 px; clicking one reopens the rail on that group.

### Adding a setting

1. Add the default to the appropriate `JsonObject` in `modules/common/Config.qml`.
2. Bind it on the leaf page that owns it under `modules/ii/settings/pages/<group>/`.
3. Reuse `ContentSection`, `GroupedList`, `ConfigRow`, `ConfigSwitch`, `ConfigComboBox`, or neighboring components.
4. Gate the feature where it is created or activated, not only in settings UI.
5. For a whole new page, add the `ContentPage` and register it as a leaf in `SettingsPages.qml`.
6. Ensure translated section titles work with `ContentPage.goTo(term)` settings search.

Dynamic lists commonly use `Rectangle`, `ColumnLayout`, and `Repeater`. `GroupedList` is mainly for static children.

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
