#!/bin/bash
# --- CONFIG ---
MCU_PATH="/dev/serial/by-id/usb-Klipper_lpc1769_12345-if00" # UPDATE THIS
BOARD_TYPE="btt-skr-turbo-v1.4"
KLIPPER_DIR="${HOME}/klipper"
KLIPPY_PIPE="${HOME}/printer_data/comms/klippy.serial"
STATE_FILE="${HOME}/.mcu_last_flash_hash"

notify() {
    [ -p "$KLIPPY_PIPE" ] && echo "RESPOND MSG=\"$1\"" > "$KLIPPY_PIPE"
    echo "$1"
}

cd "$KLIPPER_DIR" || exit

# 1. Clean dirty state & Check for updates
git stash push --all > /dev/null 2>&1
git fetch origin > /dev/null 2>&1

LOCAL_HASH=$(git rev-parse HEAD)
REMOTE_HASH=$(git rev-parse @{u})
LAST_FLASHED=$(cat "$STATE_FILE" 2>/dev/null)

# Logic: If Pi matches GitHub AND Pi matches what we last flashed -> Exit
if [ "$LOCAL_HASH" == "$REMOTE_HASH" ] && [ "$LOCAL_HASH" == "$LAST_FLASHED" ]; then
    notify "✅ MCU version is already current. Flash saved."
    exit 0
fi

# 2. Update and Compile
[ "$LOCAL_HASH" != "$REMOTE_HASH" ] && git pull > /dev/null 2>&1
NEW_HASH=$(git rev-parse HEAD)

notify "⚙️ Compiling Klipper $NEW_HASH..."
make clean > /dev/null 2>&1
if ! make -j$(nproc) > /dev/null 2>&1; then
    notify "❌ Error: Compilation failed!"
    exit 1
fi

# 3. Stop, Flash, Start (Safe because this script runs as its own service)
notify "🛑 Stopping Klipper and Flashing MCU..."
sudo systemctl stop klipper
sleep 2

if ./scripts/flash-sdcard.sh "$MCU_PATH" "$BOARD_TYPE"; then
    echo "$NEW_HASH" > "$STATE_FILE"
    notify "🎉 SUCCESS: MCU flashed to $NEW_HASH!"
else
    notify "❌ Error: Flashing failed!"
fi

sudo systemctl start klipper
