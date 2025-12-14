#!/bin/bash

# Check if bluetooth is powered
POWERED=$(bluetoothctl show | grep "Powered:" | awk '{print $2}')

if [ "$POWERED" != "yes" ]; then
    echo '{"text":"󰂲","class":"bt-off","tooltip":"Bluetooth Off (Click to turn on)"}'
    exit 0
fi

# Get first paired device
DEVICE=$(bluetoothctl devices | head -n1 | awk '{print $2}')

if [ -z "$DEVICE" ]; then
    echo '{"text":"󰂯","class":"bt-disconnected","tooltip":"No paired devices (Click to pair)"}'
    exit 0
fi

# Check if device is connected
CONNECTED=$(bluetoothctl info $DEVICE | grep "Connected:" | awk '{print $2}')
NAME=$(bluetoothctl devices | head -n1 | cut -d' ' -f3-)

if [ "$CONNECTED" = "yes" ]; then
    # Get battery if available
    BATTERY=$(bluetoothctl info $DEVICE | grep "Battery Percentage" | awk '{print $4}' | tr -d '()')
    if [ -n "$BATTERY" ]; then
        echo '{"text":"󰂯 '$BATTERY'%","class":"bt-connected","tooltip":"'$NAME' (Click to disconnect)"}'
    else
        echo '{"text":"󰂯","class":"bt-connected","tooltip":"'$NAME' (Click to disconnect)"}'
    fi
else
    echo '{"text":"󰂯","class":"bt-disconnected","tooltip":"'$NAME' (Click to connect)"}'
fi
