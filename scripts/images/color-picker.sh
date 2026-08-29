#!/usr/bin/env bash

set -o pipefail

print_only=0
if [[ "$1" == "--print" ]]; then
    print_only=1
fi

notify_error() {
    if (( print_only )); then
        echo "Color picker: $1" >&2
    else
        notify-send "Color picker" "$1" -u critical -a "Shell" --hint=int:transient:1
    fi
}

for dependency in slurp grim magick; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
        notify_error "Missing dependency: $dependency"
        exit 1
    fi
done

if (( !print_only )) && ! command -v wl-copy >/dev/null 2>&1; then
    notify_error "Missing dependency: wl-copy"
    exit 1
fi

point="$(slurp -p -f '%x,%y')" || exit 0
color="$(grim -g "${point} 1x1" -t ppm - | magick ppm:- -depth 8 -format '#%[hex:p{0,0}]' info:-)" || {
    notify_error "Could not sample the selected pixel"
    exit 1
}

if (( print_only )); then
    printf '%s' "$color"
    exit 0
fi

printf '%s' "$color" | wl-copy
notify-send "Color copied" "$color" -a "Shell" --hint=int:transient:1
