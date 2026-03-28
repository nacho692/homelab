#!/usr/bin/env bash
# Open a new kitty OS window with cwd of the focused kitty window,
# or launch a new kitty instance if no socket is available.

socket=$(find /tmp -maxdepth 1 -name 'kitty-*' -type s 2>/dev/null | head -1)

if [ -n "$socket" ]; then
    cwd=$(kitty @ --to "unix:$socket" ls 2>/dev/null \
        | jq -r '[.[].tabs[].windows[] | select(.is_focused == true and .is_self == false)] | .[0].cwd // empty')

    if [ -n "$cwd" ]; then
        kitty @ --to "unix:$socket" launch --type=os-window --cwd="$cwd"
        exit 0
    fi
fi

exec kitty
