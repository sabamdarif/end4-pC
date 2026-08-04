# Tasks — live progress

Legend: ⬜ todo · 🟨 in progress · ✅ done · ❌ blocked/skipped
Details for each task: see [plan.md](plan.md).

## Phase 0 — Docs

| ID | Task | Status | Notes |
|----|------|--------|-------|
| T01 | Add CLAUDE.md + AGENTS.md | ✅ | CLAUDE.md imports AGENTS.md (single source) |

## Phase 1 — Small fixes

| ID | Task | Status | Notes |
|----|------|--------|-------|
| T02 | Bluetooth connect feedback | ✅ | notifications + optional device sounds (9ad9f17) |
| T03 | rfkill bluetooth block fix | ✅ | unblock before enabling adapter (1bcfb94) |
| T04 | Low battery sounds at 20% / 15% | ✅ | defaults now use existing low/critical handlers at 20% and 15% |
| T05 | Battery popup Health shows N/A | ✅ | health now shows Good/Fair/Poor/Unknown, with cycles when available |
| T06 | Android-like battery icon | ✅ | existing ClippedProgressBar is a One UI 7 battery with fill, tip, percentage, and charging state |
| T07 | Auto-close popups in control center | ✅ | opening one closes siblings; sidebar close resets all dialogs and edit mode |
| T08 | Fix color picker | ⬜ | reproduce first |
| T09 | Settings first-load text/icon layout jump | ⬜ | |
| T10 | Update indicator: + flatpak | ⬜ | one-liner in Updates.qml |
| T11 | Screenshot: fullscreen default, Alt = area | ⬜ | |

## Phase 2 — Settings app

| ID | Task | Status | Notes |
|----|------|--------|-------|
| T12 | Rearrange settings pages (+ fix About index) | ⬜ | do before T13 |
| T13 | Settings search | ⬜ | reuse goTo() deep-linking |
| T14 | DNS dropdown + custom provider | ⬜ | |
| T15 | Add matugen theme from settings | ⬜ | |
| T16 | Option to disable left sidebar | ⬜ | |
| T17 | Change system sounds (Android-style) | ⬜ | |
| T18 | Wallpaper-based scheme combinations | ⬜ | |
| T19 | All Apps page (list/uninstall/storage) | ⬜ | permissions = follow-up |

## Phase 3 — Bigger features

| ID | Task | Status | Notes |
|----|------|--------|-------|
| T20 | Screenshot annotation editor | ⬜ | check swappy/satty first |
| T21 | Launcher: Google-style, overlay layer | ⬜ | |
| T22 | Noctalia-style lock screen | ⬜ | |
| T23 | Android 12 quick toggles | ⬜ | likely already done — verify |
| T24 | AI system prompt sync | ⬜ | Config.qml:89 + ii-Default.md |
