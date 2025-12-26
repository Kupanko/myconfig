#!/bin/bash

OUTPUT_FILE="/tmp/spotify_status.txt"

playerctl metadata --follow --format '{{status}};{{artist}} - {{title}}' | while read -r line; do
    STATUS=$(echo "$line" | cut -d';' -f1)
    METADATA=$(echo "$line" | cut -d';' -f2-)

    if [ "$STATUS" = "Playing" ]; then
        echo "$METADATA" > "$OUTPUT_FILE"
    else
        echo "Empty" > "$OUTPUT_FILE"
    fi
done
