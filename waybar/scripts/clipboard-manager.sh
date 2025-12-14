#!/bin/bash

# Clipboard manager with delete functionality
# Usage: clipboard-manager.sh [copy|delete]

ACTION="${1:-copy}"

if [ "$ACTION" = "delete" ]; then
    # Delete mode - show items and delete selected one
    SELECTED=$(cliphist list | rofi -dmenu -p '🗑️ Delete Clipboard Item' -theme ~/.config/rofi/launchers/type-1/style-1.rasi)
    
    if [ -n "$SELECTED" ]; then
        echo "$SELECTED" | cliphist delete
        notify-send "Clipboard" "Item deleted" -u low
    fi
else
    # Copy mode - show items and copy selected one
    cliphist list | rofi -dmenu -p 'Clipboard' -theme ~/.config/rofi/launchers/type-1/style-1.rasi | cliphist decode | wl-copy
fi
