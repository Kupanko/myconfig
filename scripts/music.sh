#!/bin/bash

OUTPUT_FILE="/tmp/i3status/spotify.txt"

get_playback_status() {
    local player="$1"
    local status=$(dbus-send --print-reply --dest="$player" \
                             /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get \
                             string:"org.mpris.MediaPlayer2.Player" string:"PlaybackStatus" 2>/dev/null | \
                       grep "string" | awk -F'"' '{print $2}')
    echo "$status"
}

spotify_status=$(get_playback_status "org.mpris.MediaPlayer2.spotify")

if [ -n "$spotify_status" ]; then
    if [ "$spotify_status" = "Playing" ]; then
        spotify_metadata=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
                                     /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get \
                                     string:"org.mpris.MediaPlayer2.Player" string:"Metadata" 2>/dev/null)

        if [ $? -eq 0 ] && [ -n "$spotify_metadata" ]; then
            title=$(echo "$spotify_metadata" | grep -A 1 "xesam:title" | tail -1 | cut -d '"' -f 2)
            artist=$(echo "$spotify_metadata" | grep -A 2 "xesam:artist" | tail -1 | cut -d '"' -f 2)

            if [ -n "$title" ]; then
                echo "$artist - $title" > "$OUTPUT_FILE"
                exit 0
            fi
        fi
    elif [ "$spotify_status" = "Paused" ]; then
        echo "Empty" > "$OUTPUT_FILE"
        exit 0
    fi
fi

vlc_status=$(get_playback_status "org.mpris.MediaPlayer2.vlc")

if [ -n "$vlc_status" ]; then
    if [ "$vlc_status" = "Playing" ]; then
        vlc_metadata=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.vlc \
                                 /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get \
                                 string:"org.mpris.MediaPlayer2.Player" string:"Metadata" 2>/dev/null)

        if [ $? -eq 0 ] && [ -n "$vlc_metadata" ]; then
            title=$(echo "$vlc_metadata" | grep -A 1 "xesam:title" | tail -1 | cut -d '"' -f 2)
            artist=$(echo "$vlc_metadata" | grep -A 2 "xesam:artist" | tail -1 | cut -d '"' -f 2)

            if [ -n "$title" ]; then
                if [ -n "$artist" ]; then
                    echo "$artist - $title" > "$OUTPUT_FILE"
                else
                    echo "$title" > "$OUTPUT_FILE"
                fi
                exit 0
            fi
        fi
    elif [ "$vlc_status" = "Paused" ]; then
        echo "Empty" > "$OUTPUT_FILE"
        exit 0
    fi
fi

echo "Empty" > "$OUTPUT_FILE"
