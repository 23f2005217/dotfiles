#!/bin/bash

# Advanced media control script for MPRIS

ACTION="$1"

case "$ACTION" in
    "play-pause")
        playerctl play-pause
        ;;
    "next")
        playerctl next
        ;;
    "previous")
        playerctl previous
        ;;
    "stop")
        playerctl stop
        ;;
    "forward")
        playerctl position 10+
        ;;
    "rewind")
        playerctl position 10-
        ;;
    "shuffle")
        playerctl shuffle toggle
        ;;
    "loop")
        playerctl loop toggle
        ;;
    "volume-up")
        playerctl volume 0.1+
        ;;
    "volume-down")
        playerctl volume 0.1-
        ;;
    "menu")
        # Show a rofi menu with media controls
        PLAYER=$(playerctl -l 2>/dev/null | head -n1)
        if [ -z "$PLAYER" ]; then
            notify-send "Media Player" "No active player found" -u normal
            exit 0
        fi
        
        OPTIONS="󰄄 play/pause\n󰤌 previous\n󰤎 next\n󰄅 stop\n󰆀 rewind 10s\n󰆁 forward 10s\n󰖃 shuffle\n󰖁 loop\n󰕾 volume up\n󰕺 volume down"
        
        CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -p "Controls" -theme ~/.config/rofi/launchers/type-1/style-1.rasi -theme-str 'window {width: 350px;}')
        
        case "$CHOICE" in
            "󰄄 play/pause")
                playerctl play-pause
                ;;
            "󰤌 previous")
                playerctl previous
                ;;
            "󰤎 next")
                playerctl next
                ;;
            "󰄅 stop")
                playerctl stop
                ;;
            "󰆀 rewind 10s")
                playerctl position 10-
                ;;
            "󰆁 forward 10s")
                playerctl position 10+
                ;;
            "󰖃 shuffle")
                playerctl shuffle toggle
                STATUS=$(playerctl shuffle)
                notify-send "Media Player" "Shuffle: $STATUS" -u normal
                ;;
            "󰖁 loop ")
                playerctl loop toggle
                STATUS=$(playerctl loop)
                notify-send "Media Player" "Loop: $STATUS" -u normal
                ;;
            "󰕾 volume up")
                playerctl volume 0.1+
                VOL=$(playerctl volume)
                notify-send "Media Player" "Volume: $(echo "$VOL * 100" | bc | cut -d'.' -f1)%" -u normal
                ;;
            "󰕺 volume down")
                playerctl volume 0.1-
                VOL=$(playerctl volume)
                notify-send "Media Player" "Volume: $(echo "$VOL * 100" | bc | cut -d'.' -f1)%" -u normal
                ;;
        esac
        ;;
    *)
        echo "Usage: $0 {play-pause|next|previous|stop|forward|rewind|shuffle|loop|volume-up|volume-down|menu}"
        exit 1
        ;;
esac
