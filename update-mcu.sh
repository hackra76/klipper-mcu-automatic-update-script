#!/bin/bash
# --- CONFIG ---
MCU_PATH="/dev/serial/by-id/usb-Klipper_lpc1769_12345-if00" # DOUBLE CHECK THIS ID
BOARD_TYPE="btt-skr-turbo-v1.4"
KLIPPER_DIR="${HOME}/klipper"
KLIPPY_PIPE="${HOME}/printer_data/comms/klippy.serial"
STATE_FILE="${HOME}/.mcu_last_flash_hash"

notify() {
    [ -p "$KLIPPY_PIPE" ] && echo "RESPOND MSG=\"$1\"" > "$KLIPPY_PIPE"
    echo -e "$1"
}

cd "$KLIPPER_DIR" || exit

# 1. Clean up without losing the .config file
notify "🧹 Cleaning local Klipper changes..."
git stash push > /dev/null 2>&1 # Only stash tracked files
git fetch origin > /dev/null 2>&1

LOCAL_HASH=$(git rev-parse HEAD)
REMOTE_HASH=$(git rev-parse @{u})
LAST_FLASHED=$(cat "$STATE_FILE" 2>/dev/null)

if [ "$LOCAL_HASH" == "$REMOTE_HASH" ] && [ "$LOCAL_HASH" == "$LAST_FLASHED" ]; then
    notify "✅ MCU version is already current."
    exit 0
fi

# 2. Update and Compile
[ "$LOCAL_HASH" != "$REMOTE_HASH" ] && git pull
NEW_HASH=$(git rev-parse HEAD)

notify "⚙️ Compiling Klipper $NEW_HASH..."
make clean
# We removed > /dev/null so we can see errors in the log
if ! make -j$(nproc); then
    notify "❌ ERROR: Compilation failed! Check ~/printer_data/logs/mcu_update.log"
    exit 1
fi

# Verify the file actually exists before proceeding
if [ ! -f "out/klipper.bin" ]; then
    notify "❌ ERROR: out/klipper.bin was not created!"
    exit 1
fi

# 3. Stop, Flash, Start
notify "🛑 Stopping Klipper and Flashing MCU..."
sudo systemctl stop klipper
sleep 2

if ./scripts/flash-sdcard.sh "$MCU_PATH" "$BOARD_TYPE"; then
    echo "$NEW_HASH" > "$STATE_FILE"
    notify "🎉 SUCCESS: MCU flashed to $NEW_HASH!"
else
    notify "❌ ERROR: Flashing failed!"
fi

sudo systemctl start klipper
