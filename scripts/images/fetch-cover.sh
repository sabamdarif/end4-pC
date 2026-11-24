#!/usr/bin/env bash
set -eu

target=$1
url=$2

mkdir -p -- "$(dirname -- "$target")"
if [ -s "$target" ]; then
    exit 0
fi

temporary=$(mktemp "${target}.XXXXXX")
trap 'rm -f -- "$temporary"' EXIT
curl --fail --silent --show-error --location --max-time 30 \
    --proto '=http,https' --proto-redir '=http,https' \
    --output "$temporary" -- "$url"
test -s "$temporary"
mv -f -- "$temporary" "$target"
