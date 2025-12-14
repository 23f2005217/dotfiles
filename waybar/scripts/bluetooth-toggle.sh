#!/bin/bash

# Check if bluetooth is powered
POWERED=$(bluetoothctl show | grep "Powered:" | awk '{print $2}')

if [ "$POWERED" != "yes" ]; then
    # Turn on bluetooth
    bluetoothctl power on
    notify-send "Bluetooth" "Bluetooth turned on" -u normal
    exit 0
fi

# Get the first paired device (you can modify this to handle multiple devices)
DEVICE=$(bluetoothctl devices | head -n1 | awk '{print $2}')

if [ -z "$DEVICE" ]; then
    # No paired devices, open bluetooth manager
    notify-send "Bluetooth" "No paired devices. Opening bluetooth manager..." -u normal
    blueman-manager &
    exit 0
fi

# Check if device is connected
CONNECTED=$(bluetoothctl info $DEVICE | grep "Connected:" | awk '{print $2}')

if [ "$CONNECTED" = "yes" ]; then
    # Disconnect
    bluetoothctl disconnect $DEVICE
    notify-send "Bluetooth" "Disconnected" -u normal
else
    # Try to connect
    bluetoothctl connect $DEVICE &>/dev/null
    if [ $? -eq 0 ]; then
        notify-send "Bluetooth" "Connected" -u normal
    else
        # Connection failed, try pairing again
        notify-send "Bluetooth" "Connection failed. Attempting to repair..." -u normal
        
        # Get device MAC (it might have changed or need re-pairing)
        MAC=$(bluetoothctl devices | grep -i "$(bluetoothctl info $DEVICE | grep 'Name:' | cut -d':' -f2- | xargs)" | awk '{print $2}')
        
        if [ -n "$MAC" ]; then
            bluetoothctl remove $MAC &>/dev/null
        fi
        
        # Start scanning
        bluetoothctl --timeout 5 scan on &>/dev/null &
        sleep 3
        
        # Try to find and pair the device again
        NEW_MAC=$(bluetoothctl devices | head -n1 | awk '{print $2}')
        if [ -n "$NEW_MAC" ]; then
            bluetoothctl pair $NEW_MAC &>/dev/null
            bluetoothctl trust $NEW_MAC &>/dev/null
            bluetoothctl connect $NEW_MAC &>/dev/null
            notify-send "Bluetooth" "Device repaired and connected" -u normal
        else
            notify-send "Bluetooth" "Failed to find device. Please pair manually." -u critical
            blueman-manager &
        fi
    fi
fi
