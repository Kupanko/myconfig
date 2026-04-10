#!/bin/bash
mkdir -p "$HOME/Pictures/Screenshots"

tmp_png="/tmp/freeze_$$.png"
import -window root "$tmp_png"

if [ ! -f "$tmp_png" ]; then
    exit 1
fi

if command -v feh >/dev/null 2>&1; then
    feh -FZY "$tmp_png" &
    FEH_PID=$!
    sleep 0.5
fi

filename="$HOME/Pictures/Screenshots/screenshot_$(date +%Y%m%d_%H%M%S).png"
import "$filename"

if [ ! -f "$filename" ]; then
    [ ! -z "$FEH_PID" ] && kill $FEH_PID 2>/dev/null
    rm "$tmp_png"
    exit 1
fi

[ ! -z "$FEH_PID" ] && kill $FEH_PID 2>/dev/null

rm "$tmp_png" 2>/dev/null

if command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard -t image/png -i "$filename"
    echo -n "$filename" | xclip -selection primary
fi
