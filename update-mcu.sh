#!/bin/bash

# --- USER CONFIGURATION ---
MCU_PATH="/dev/serial/by-id/usb-Klipper_lpc1769_12345-if00"
BOARD_TYPE="btt-skr-turbo-v1.4"
KLIPPER_DIR="${HOME}/klipper"
KLIPPER_SERVICE="klipper"
KLIPPY_PIPE="${HOME}/printer_data/comms/klippy.serial"
STATE_FILE="${HOME}/.klipper_mcu_last_flash"

YELLOW='\e[1;33m'
GREEN='\e[1;32m'
RED='\e[1;31m'
NC='\e[0m'

notify() {
    echo -e "${YELLOW}UI-NOTIFY: $1${NC}"
    # We use a slight delay to ensure Moonraker catches the message
    if [ -p "$KLIPPY_PIPE" ]; then
        echo "RESPOND MSG=\"$1\"" > "$KLIPPY_PIPE"
    fi
}
# --------------------------

echo -e "${YELLOW}▶ Starting MCU Update Check...${NC}"
cd "$KLIPPER_DIR" || exit

# 1. FIX "DIRTY" STATE & FETCH
# This cleans up the '-dirty' flag you saw in your screenshot
notify "🧹 Cleaning local Klipper changes..."
git stash push --all > /dev/null 2>&1
git fetch origin > /dev/null 2>&1

# 2. VERSION CHECK
LOCAL_HASH=$(git rev-parse HEAD)
REMOTE_HASH=$(git rev-parse @{u})
LAST_FLASHED=$(cat "$STATE_FILE" 2>/dev/null)

if [ "$LOCAL_HASH" == "$REMOTE_HASH" ] && [ "$LOCAL_HASH" == "$LAST_FLASHED" ]; then
    notify "✅ MCU is already up to date ($LOCAL_HASH)."
    exit 0
fi

# 3. PREPARE UPDATE
if [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
    notify "🆕 New Klipper version detected. Updating source..."
    git pull > /dev/null 2>&1
    LOCAL_HASH=$(git rev-parse HEAD)
else
    notify "🔧 Source current, but MCU needs a refresh flash..."
fi

# 4. COMPILATION (Done while Klipper is still running to save time)
notify "⚙️ Compiling firmware..."
make clean > /dev/null 2>&1
if ! make -j$(nproc) > /dev/null 2>&1; then
    notify "❌ Error: Compilation failed!"
    exit 1
fi

# 5. SAFE FLASHING (This is where Moonraker shines)
notify "🛑 Stopping Klipper and Flashing..."
sudo systemctl stop "$KLIPPER_SERVICE"

# Give the system 2 seconds to release the serial port
sleep 2

if ./scripts/flash-sdcard.sh "$MCU_PATH" "$BOARD_TYPE"; then
    echo "$LOCAL_HASH" > "$STATE_FILE"
    SUCCESS=true
else
    SUCCESS=false
fi

# 6. RESTART
sudo systemctl start "$KLIPPER_SERVICE"

if [ "$SUCCESS" = true ]; then
    notify "🎉 SUCCESS: MCU flashed! Please run FIRMWARE_RESTART."
else
    notify "❌ Error: Flashing failed! Check cable or SD card."
    exit 1
fi