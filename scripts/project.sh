#!/bin/bash

mkdir -p /tmp/i3status

OUTPUT_FILE="/tmp/i3status/projects.txt"

get_project_icon() {
    local project_name="$1"
    local icon="$2"

    STATUS=$(systemctl is-active "$project_name" 2>/dev/null)

    if [ "$STATUS" = "active" ]; then
        echo "<span font='Material Icons' rise='-2200' color='#ffb748'>$icon</span>"
    elif [ "$STATUS" = "inactive" ]; then
        echo "<span font='Material Icons' rise='-2200' color='#a6a6a6'>$icon</span>"
    else
        echo "<span font='Material Icons' rise='-2200' color='#ff4848'>$icon</span>"
    fi
}

sleep 5

while true; do
    PROJECT1_ICON=$(get_project_icon "db" "dns")
    PROJECT2_ICON=$(get_project_icon "p1" "looks_one")
    PROJECT3_ICON=$(get_project_icon "p2" "looks_two")

    echo "$PROJECT1_ICON$PROJECT2_ICON$PROJECT3_ICON" > "$OUTPUT_FILE"

    sleep 60
done
