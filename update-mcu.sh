#!/bin/bash

# --- USER CONFIGURATION ---
# Replace with your actual ID from: ls /dev/serial/by-id/
MCU_PATH="/dev/serial/by-id/usb-Klipper_lpc1769_12345-if00"
BOARD_TYPE="btt-skr-turbo-v1.4"

# Use absolute paths for stability
USER_NAME=$(id -un)
USER_HOME="/home/$USER_NAME"
KLIPPER_DIR="$USER_HOME/klipper"
KLIPPY_PIPE="$USER_HOME/printer_data/comms/klippy.serial"
STATE_FILE="$USER_HOME/.mcu_last_flash_hash"
# --------------------------

notify() {
    # Send message to Klipper Console
    if [ -p "$KLIPPY_PIPE" ]; then
        echo "RESPOND MSG=\"$1\"" > "$KLIPPY_PIPE"
    fi
    # Also log to the system log
    echo "$(date +'%H:%M:%S') - $1"
}

cd "$KLIPPER_DIR" || exit

# 1. Version Check (Flash-Saver)
# Stash local changes to fix "-dirty" status and fetch updates
git stash push --all > /dev/null 2>&1
git fetch origin > /dev/null 2>&1

LOCAL_HASH=$(git rev-parse HEAD)
REMOTE_HASH=$(git rev-parse @{u})
LAST_FLASHED=$(cat "$STATE_FILE" 2>/dev/null)

if [ "$LOCAL_HASH" == "$REMOTE_HASH" ] && [ "$LOCAL_HASH" == "$LAST_FLASHED" ]; then
    notify "✅ MCU is already up to date ($LOCAL_HASH). Flash skipped."
    exit 0
fi

# 2. Build Process
notify "⚙️ Compiling Klipper firmware..."
make clean > /dev/null 2>&1

if ! make -j$(nproc); then
    notify "❌ ERROR: Compilation failed! Check Klipper menuconfig."
    exit 1
fi

# 3. Binary Verification (Must be .bin for SKR V1.4)
if [ ! -f "out/klipper.bin" ]; then
    notify "❌ ERROR: out/klipper.bin not found! Check your architecture."
    exit 1
fi

# 4. Flashing (Stop Klipper -> Flash -> Start Klipper)
notify "🛑 Stopping Klipper and flashing MCU..."
sudo /usr/bin/systemctl stop klipper
sleep 2

if ./scripts/flash-sdcard.sh "$MCU_PATH" "$BOARD_TYPE"; then
    echo "$LOCAL_HASH" > "$STATE_FILE"
    notify "🎉 SUCCESS: MCU flashed successfully!"
else
    notify "❌ ERROR: Flashing failed!"
fi

sudo /usr/bin/systemctl start klipper
