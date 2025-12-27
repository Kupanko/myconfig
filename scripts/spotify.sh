#!/bin/bash

OUTPUT_FILE="/tmp/spotify_status.txt"

playerctl --player="spotify" metadata --follow --format '{{playerName}};{{status}};{{artist}} - {{title}}' | while read -r line; do
    PLAYER=$(echo "$line" | cut -d';' -f1)
    STATUS=$(echo "$line" | cut -d';' -f2)
    METADATA=$(echo "$line" | cut -d';' -f3-)

    if [ "$PLAYER" = "spotify" ]; then
        if [ "$STATUS" = "Playing" ]; then
            echo "$METADATA" > "$OUTPUT_FILE"
        else
            echo "Empty" > "$OUTPUT_FILE"
        fi
    fi
done
