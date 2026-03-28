#!/usr/bin/env bash
# Open a new kitty OS window with cwd of the focused kitty window,
# or launch a new kitty instance if no socket is available.

for socket in /tmp/kitty-*; do
    [ -S "$socket" ] || continue

    cwd=$(kitty @ --to "unix:$socket" ls 2>/dev/null \
        | jq -r '[.[].tabs[].windows[] | select(.is_focused == true and .is_self == false)] | .[0].cwd // empty')

    if [ -n "$cwd" ]; then
        kitty @ --to "unix:$socket" launch --type=os-window --cwd="$cwd"
        exit 0
    fi
done

exec kitty
