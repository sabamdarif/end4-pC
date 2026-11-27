.pragma library

// Key capture and grouped shortcut UX adapted from dux-shell (MIT).
// The upstream notice is in assets/licenses/dux-shell.txt.
const KEY_NAMES = {
    16777216: "Escape", 16777217: "Tab", 16777218: "Tab", 16777219: "BackSpace",
    16777220: "Return", 16777221: "Return", 16777222: "Insert", 16777223: "Delete",
    16777224: "Pause", 16777225: "Print", 16777226: "Print", 16777232: "Home",
    16777233: "End", 16777234: "Left", 16777235: "Up", 16777236: "Right",
    16777237: "Down", 16777238: "Page_Up", 16777239: "Page_Down",
    16777252: "Caps_Lock", 16777253: "Num_Lock", 16777254: "Scroll_Lock",
    32: "space", 44: "comma", 46: "period", 47: "slash", 59: "semicolon",
    39: "apostrophe", 91: "bracketleft", 93: "bracketright", 92: "backslash",
    45: "minus", 61: "equal", 96: "grave",
    16777330: "XF86AudioRaiseVolume", 16777328: "XF86AudioLowerVolume",
    16777329: "XF86AudioMute", 16842808: "XF86AudioMicMute",
    16777344: "XF86AudioPlay", 16777345: "XF86AudioStop",
    16777346: "XF86AudioPrev", 16777347: "XF86AudioNext", 16777348: "XF86AudioPause",
    16842798: "XF86MonBrightnessUp", 16777394: "XF86MonBrightnessUp",
    16842797: "XF86MonBrightnessDown", 16777395: "XF86MonBrightnessDown",
    16777488: "XF86TouchpadToggle", 16842796: "XF86PowerOff", 16842803: "XF86Sleep"
};
const KEYPAD_NAMES = {
    16777220: "KP_Enter", 16777221: "KP_Enter", 16777232: "KP_Home",
    16777235: "KP_Up", 16777238: "KP_Prior", 16777234: "KP_Left",
    16777227: "KP_Begin", 16777236: "KP_Right", 16777233: "KP_End",
    16777237: "KP_Down", 16777239: "KP_Next", 16777222: "KP_Insert",
    16777223: "KP_Delete", 43: "KP_Add", 45: "KP_Subtract", 42: "KP_Multiply",
    47: "KP_Divide", 46: "KP_Decimal"
};
const SHIFTED_SYMBOLS = {
    33: "1", 34: "apostrophe", 35: "3", 36: "4", 37: "5", 38: "7", 40: "9",
    41: "0", 42: "8", 43: "equal", 58: "semicolon", 60: "comma", 62: "period",
    63: "slash", 64: "2", 94: "6", 95: "minus", 123: "bracketleft",
    124: "backslash", 125: "bracketright", 126: "grave"
};

const COMPOSITOR_ACTIONS = [
    ["close-window", "Close window"], ["fullscreen-window", "Fullscreen"],
    ["maximize-column", "Maximize column"], ["center-column", "Center column"],
    ["center-visible-columns", "Center visible columns"], ["toggle-window-floating", "Toggle floating"],
    ["switch-focus-between-floating-and-tiling", "Switch floating/tiling focus"],
    ["switch-preset-column-width", "Cycle column width"], ["switch-preset-window-height", "Cycle window height"],
    ['set-column-width "50%"', "Set column width"], ['set-window-height "50%"', "Set window height"],
    ["reset-window-height", "Reset window height"], ["expand-column-to-available-width", "Expand to available width"],
    ["consume-or-expel-window-left", "Consume/expel left"], ["consume-or-expel-window-right", "Consume/expel right"],
    ["toggle-column-tabbed-display", "Toggle tabbed display"],
    ["focus-column-left", "Focus left"], ["focus-column-right", "Focus right"],
    ["focus-window-up", "Focus up"], ["focus-window-down", "Focus down"],
    ["move-column-left", "Move left"], ["move-column-right", "Move right"],
    ["move-window-up", "Move up"], ["move-window-down", "Move down"],
    ["focus-workspace 1", "Focus workspace"], ["focus-workspace-up", "Focus workspace up"],
    ["focus-workspace-down", "Focus workspace down"], ["focus-workspace-previous", "Focus previous workspace"],
    ["move-column-to-workspace 1", "Move to workspace"], ["move-column-to-workspace-up", "Move to workspace up"],
    ["move-column-to-workspace-down", "Move to workspace down"],
    ["focus-monitor-left", "Focus monitor left"], ["focus-monitor-right", "Focus monitor right"],
    ["move-column-to-monitor-left", "Move column to monitor left"], ["move-column-to-monitor-right", "Move column to monitor right"],
    ["screenshot", "Screenshot (interactive)"], ["screenshot-screen", "Screenshot screen"],
    ["screenshot-window", "Screenshot window"], ["toggle-overview", "Toggle overview"],
    ["show-hotkey-overlay", "Show hotkey overlay"], ["power-off-monitors", "Power off monitors"],
    ["toggle-keyboard-shortcuts-inhibit", "Toggle shortcuts inhibit"], ["quit", "Quit niri"]
];

function keyFromEvent(event) {
    const k = event.key;
    if (event.modifiers & 0x20000000) {
        if (k >= 48 && k <= 57) return "KP_" + (k - 48);
        if (KEYPAD_NAMES[k]) return KEYPAD_NAMES[k];
    }
    if (event.modifiers & 0x02000000) {
        if (event.nativeScanCode >= 10 && event.nativeScanCode <= 19)
            return String((event.nativeScanCode - 9) % 10);
        if (SHIFTED_SYMBOLS[k]) return SHIFTED_SYMBOLS[k];
    }
    if (k >= 65 && k <= 90) return String.fromCharCode(k);
    if (k >= 48 && k <= 57) return String.fromCharCode(k);
    if (k >= 16777264 && k <= 16777298) return "F" + (k - 16777264 + 1);
    return KEY_NAMES[k] || "";
}

function eventCombo(event, modKey) {
    const key = keyFromEvent(event);
    if (!key) return "";
    const parts = [];
    for (const [mask, name] of [[0x10000000, "Super"], [0x04000000, "Ctrl"],
        [0x08000000, "Alt"], [0x02000000, "Shift"]]) {
        if (event.modifiers & mask) parts.push(name.toLowerCase() === String(modKey).toLowerCase() ? "Mod" : name);
    }
    if (event.key === 16777218 && !parts.includes("Shift")) parts.push("Shift");
    return parts.concat(key).join("+");
}

function searchCombo(event, modKey) {
    if (!(event.modifiers & (0x10000000 | 0x08000000)) &&
        (event.text || (event.modifiers & 0x04000000) ||
         [16777216, 16777217, 16777218, 16777219, 16777220, 16777221, 16777222,
          16777223, 16777232, 16777233, 16777234, 16777235, 16777236, 16777237,
          16777238, 16777239].includes(event.key))) return "";
    return eventCombo(event, modKey);
}

function normalizeKey(key, modKey) {
    const aliases = { control: "ctrl", meta: "super", win: "super", mod4: "super", mod1: "alt" };
    const parts = String(key || "").toLowerCase().split("+").map(p => p.trim());
    const trigger = parts.pop();
    const modifiers = parts.map(p => p === "mod" ? String(modKey || "Super").toLowerCase() : (aliases[p] || p));
    return Array.from(new Set(modifiers)).sort().concat(trigger).join("+");
}

function categoryOf(bind) {
    const action = String(bind.action || "");
    if (/^spawn\b/.test(action) && /"ipc"\s+"call"/.test(action)) return "shell";
    if (/^spawn(?:-sh)?\b/.test(action)) return "apps";
    if (/workspace/.test(action)) return "workspace";
    if (/monitor/.test(action)) return "monitor";
    if (/screenshot/.test(action)) return "screenshot";
    if (/window|column|focus|move|fullscreen|maximize/.test(action)) return "window";
    return "other";
}

function effectiveBinds(rawBinds, modKey) {
    const result = [];
    const byKey = new Map();
    for (const bind of rawBinds) {
        const normalized = normalizeKey(bind.key, modKey);
        const index = byKey.get(normalized);
        const previous = index === undefined ? null : result[index];
        const entry = Object.assign({}, bind, {
            isOverride: String(bind.source || "").endsWith("/qssettings/binds.kdl"),
            conflict: false, shadowedTitle: "", shadowedSource: "", overriddenByConfig: false
        });
        if (previous) {
            entry.conflict = entry.isOverride && !previous.isOverride;
            entry.shadowedTitle = previous.title;
            entry.shadowedSource = previous.source;
            entry.overriddenByConfig = !entry.isOverride && (previous.isOverride || previous.overriddenByConfig);
            result[index] = entry;
        } else {
            byKey.set(normalized, result.length);
            result.push(entry);
        }
    }
    return result;
}

function groupedBinds(binds) {
    const groups = [];
    const byAction = new Map();
    for (const bind of binds) {
        let group = byAction.get(bind.action);
        if (!group) {
            group = { action: bind.action, title: bind.title, category: categoryOf(bind), keys: [] };
            byAction.set(bind.action, group);
            groups.push(group);
        }
        group.keys.push(bind);
    }
    return groups;
}

function matchesSearch(group, query, modKey) {
    const q = String(query || "").toLowerCase().trim();
    if (!q) return true;
    if (group.keys.some(b => normalizeKey(b.key, modKey).includes(normalizeKey(q, modKey)))) return true;
    return q.split(/\s+/).every(word => `${group.title} ${group.action} ${group.keys.map(b => b.title).join(" ")}`.toLowerCase().includes(word));
}

function updatedOverrides(overrides, originalKey, entry, modKey) {
    const newKey = normalizeKey(entry.key, modKey);
    const oldKey = originalKey ? normalizeKey(originalKey, modKey) : "";
    return overrides.filter(b => {
        const key = normalizeKey(b.key, modKey);
        return key !== newKey && key !== oldKey;
    }).concat(entry);
}

function spawnTokens(action) {
    if (!/^spawn\s/.test(action)) return null;
    const tokens = action.slice(5).match(/"(?:\\.|[^"\\])*"|[^\s;]+/g) || [];
    try { return tokens.map(t => t.startsWith('"') ? JSON.parse(t) : t); }
    catch (error) { return null; }
}

function shellAction(command) {
    return 'spawn "sh" "-c" ' + JSON.stringify(command);
}

function commandAction(command) {
    const tokens = spawnTokens("spawn " + command);
    return tokens && tokens.length ? "spawn " + tokens.map(t => JSON.stringify(t)).join(" ") : "";
}

function actionForm(action) {
    const tokens = spawnTokens(action);
    if (!tokens) return { type: "compositor", text: action };
    if (tokens.length === 3 && tokens[0] === "sh" && tokens[1] === "-c")
        return { type: "shell", text: tokens[2] };
    if (tokens.includes("ipc") && tokens.includes("call")) return { type: "shell-action", text: action };
    return { type: "command", text: tokens.map(t => /\s|["\\]/.test(t) ? JSON.stringify(t) : t).join(" ") };
}
