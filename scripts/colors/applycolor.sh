#!/usr/bin/env bash

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_DIR="$XDG_STATE_HOME/quickshell"
CONFIG_FILE="$XDG_CONFIG_HOME/qssettings/config.json"
TERMINAL_DIR="$STATE_DIR/user/generated/terminal"

apply_kitty() {
    [[ -f "$TERMINAL_DIR/kitty-theme.conf" ]] || return 0
    local pids
    pids=$(pidof kitty) || return 0
    kill -SIGUSR1 $pids
}

write_sequences() {
    local palette
    palette=$(jq -er '
        [range(0;16) as $i | .["term" + ($i|tostring)]] +
        [.background, .foreground, .cursor, .selection_background, .selection_foreground] |
        if all(.[]; type == "string" and test("^#[0-9a-fA-F]{6}$")) then .[]
        else error("Invalid terminal palette") end
    ' "$TERMINAL_DIR/colors.json") || return 1
    local colors i
    mapfile -t colors <<< "$palette"
    for i in {0..15}; do
        printf '\033]4;%s;%s\033\\' "$i" "${colors[$i]}"
    done
    printf '\033]10;%s\033\\\033]11;%s\033\\\033]12;%s\033\\' "${colors[17]}" "${colors[16]}" "${colors[18]}"
    printf '\033]17;%s\033\\\033]19;%s\033\\' "${colors[19]}" "${colors[20]}"
}

apply_anyterm() {
    [[ -f "$TERMINAL_DIR/colors.json" ]] || return 0
    write_sequences > "$TERMINAL_DIR/sequences.txt.new" || {
        rm -f "$TERMINAL_DIR/sequences.txt.new"
        return 1
    }
    mv "$TERMINAL_DIR/sequences.txt.new" "$TERMINAL_DIR/sequences.txt"
    local file
    for file in /dev/pts/*; do
        [[ "$file" =~ ^/dev/pts/[0-9]+$ && -O "$file" && -w "$file" ]] || continue
        timeout 1s cat "$TERMINAL_DIR/sequences.txt" > "$file" 2>/dev/null || true
    done
}

main() {
    if [[ -f "$CONFIG_FILE" ]]; then
        [[ $(jq -r '.appearance.wallpaperTheming.enableTerminal' "$CONFIG_FILE") != "false" ]] || return 0
    fi
    apply_anyterm || return 1
    if [[ ! -f "$CONFIG_FILE" ]] || ! jq -e '.appearance.matugenDisabled // [] | index("kitty")' "$CONFIG_FILE" >/dev/null; then
        apply_kitty
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
