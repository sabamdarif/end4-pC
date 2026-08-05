# Repository Guide

## Project

This repository is a personal fork of end-4's illogical-impulse desktop shell. It is a live-reloaded Quickshell/QML application for Wayland, with support for both Hyprland and niri.

There is no conventional compile step. `shell.qml` is the entry point, and Quickshell loads the QML tree directly.

## Architecture

- `shell.qml`: initializes shared services and loads the selected panel family.
- `panelFamilies/IllogicalImpulseFamily.qml`: registers top-level panels through `PanelLoader`.
- `modules/ii/`: shell UI organized by feature, including bar, settings, launchers, sidebars, lock screen, wallpaper picker, and quick toggles.
- `modules/common/`: shared configuration, functions, models, utilities, and reusable widgets.
- `services/`: singleton state and system integrations. Prefer putting shared behavior here instead of duplicating shell commands in multiple delegates.
- `scripts/`: Python and shell helpers for integrations that are impractical in QML.
- `defaults/`: default user-facing content copied or loaded by the shell.
- `translations/`: translation catalogs and tooling.

## Configuration and settings

`modules/common/Config.qml` is the persisted configuration schema. For a new option:

1. Add its default to the appropriate `JsonObject` in `Config.qml`.
2. Bind the setting in the relevant file under `modules/ii/settings/pages/`.
3. Reuse the existing settings widgets and structure: `ContentSection`, `GroupedList`, `ConfigRow`, `ConfigSwitch`, `ConfigComboBox`, and related components.
4. Gate the feature at the point where it is created or activated, not only in the settings UI.

Settings search navigates by translated page and section titles. New user-visible section titles should work with the page's `goTo(term)` behavior.

## Platform behavior

- Any window-manager-specific behavior must branch on `NiriData.isNiri`.
- Keep shared system state and actions in a service when multiple UI components use them.
- Use `Quickshell.execDetached()` for fire-and-forget commands and `Process` when output, exit state, or cancellation matters.
- Prefer safe file handling. User data removal should use the desktop trash mechanism where practical.

## UI conventions

- Route user-visible strings through `Translation.tr()`.
- Reuse `Appearance` colors, typography, spacing, and rounding instead of hardcoded styling.
- Reuse existing Material symbols and shell widgets before introducing a new component.
- Dynamic lists commonly use `Rectangle` + `ColumnLayout` + `Repeater`; `GroupedList` is intended primarily for static children.
- Preserve the existing Material 3 Expressive visual language and responsive layout behavior.

## Important synchronization points

- The default AI prompt exists in both `modules/common/Config.qml` and `defaults/ai/prompts/ii-Default.md`. Keep them byte-for-byte equivalent when changing it.
- Top-level panels must be imported and registered in `panelFamilies/IllogicalImpulseFamily.qml`.
- Avoid hardcoded settings page indexes. Use stable page keys or names because navigation order changes.

## Workflow

- Implement tasks sequentially.
- Keep each completed task in its own focused commit before starting the next task.
- Preserve unrelated local and untracked files.
- Update `tasks.md` when a tracked task changes state.
- Do not claim verification that was not run.

## Verification

For QML changes, use the checks appropriate to the task:

```bash
git diff --check
timeout 15s qs -p .
```

A timeout from the second command is expected when the shell remains running. Confirm that the log reaches `Configuration Loaded` and inspect any new QML errors. Existing environment warnings, such as a missing compositor connection or another notification server already running, are not necessarily regressions.

Also exercise the affected UI manually. For window-manager-specific behavior, check both Hyprland and niri when available. For scripts or command integrations, run the underlying command independently with non-destructive test data.

## Current work areas

Recent changes concentrate on settings search and page organization, DNS and matugen controls, sidebar gating, system sound overrides, app inventory and Flatpak permissions, screenshots and annotation handoff, launcher layering, the lock screen, quick toggles, and wallpaper color variants. Check nearby implementations and recent commits before adding parallel infrastructure.
