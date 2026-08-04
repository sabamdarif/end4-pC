#!/usr/bin/env bash

set -o pipefail

notify_error() {
    notify-send "Color picker" "$1" -u critical -a "Shell" --hint=int:transient:1
}

if command -v hyprpicker >/dev/null 2>&1; then
    exec hyprpicker -a
fi

for dependency in slurp grim magick wl-copy; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
        notify_error "Missing dependency: $dependency"
        exit 1
    fi
done

point="$(slurp -p -f '%x,%y')" || exit 0
color="$(grim -g "${point} 1x1" -t ppm - | magick ppm:- -depth 8 -format '#%[hex:p{0,0}]' info:-)" || {
    notify_error "Could not sample the selected pixel"
    exit 1
}
printf '%s' "$color" | wl-copy
notify-send "Color copied" "$color" -a "Shell" --hint=int:transient:1
