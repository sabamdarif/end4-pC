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
| T08 | Fix color picker | ✅ | shared picker script uses hyprpicker or grim/slurp/ImageMagick fallback |
| T09 | Settings first-load text/icon layout jump | ✅ | suppress initial collapsed-to-expanded label animation |
| T10 | Update indicator: + flatpak | ✅ | total in pill; hover breakdown for pacman, AUR, and Flatpak |
| T11 | Screenshot: fullscreen default, Alt = area | ✅ | default UI/IPC action is fullscreen; Alt and areaScreenshot retain region selection |

## Phase 2 — Settings app

| ID | Task | Status | Notes |
|----|------|--------|-------|
| T12 | Rearrange settings pages (+ fix About index) | ✅ | reordered navigation; About refresh now uses a stable page key |
| T13 | Settings search | ✅ | searches translated page and section titles with keyboard navigation and deep links |
| T14 | DNS dropdown + custom provider | ✅ | provider dropdown includes presets, DHCP, and conditional custom fields |
| T15 | Add matugen theme from settings | ✅ | saved named schemes with type/accent and apply/remove controls |
| T16 | Option to disable left sidebar | ✅ | Config switch gates panel, triggers, and corner interaction |
| T17 | Change system sounds (Android-style) select to play and check as well then set it| ✅ | Per-event enable, play, pick-to-safe-folder, and reset controls |
| T18 | Wallpaper-based scheme combinations, just like how it works on android 13+ devices where it generate lot of combination of a single wallaper| ✅ | Existing wallpaper scheme picker exposes Auto plus eight matugen variants and regenerates colors |
| T19 | All Apps page (list/uninstall/storage) | ✅ | merged system/Flatpak list with search, open, uninstall, size, data clearing, notification controls, and Flatseal deep links |

## Phase 3 — Bigger features

| ID | Task | Status | Notes |
|----|------|--------|-------|
| T20 | Screenshot annotation editor | ✅ | Fullscreen and area captures open satty/swappy when available, then copy/save the edited result; normal fallback retained |
| T21 | Launcher: Google-style, overlay layer | ✅ | Overlay layer with a compact centered launcher inspired by Caelestia |
| T22 | Noctalia-style lock screen | ✅ | Noctalia-inspired bottom login card with compact info/session rows; existing auth and actions preserved |
| T23 | Android 12 quick toggles | ✅ | Verified default Android style, configurable grid, edit mode, and 17 toggle delegates |
| T24 | AI system prompt sync | ✅ | Verified Config.qml and ii-Default.md match the requested prompt byte-for-byte |
