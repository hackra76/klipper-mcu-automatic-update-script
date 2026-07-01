#!/bin/bash

# --- USER CONFIGURATION ---
MCU_PATH="/dev/serial/by-id/usb-Klipper_lpc1769_12345-if00"
BOARD_TYPE="btt-skr-turbo-v1.4"
KLIPPER_DIR="${HOME}/klipper"
KLIPPER_SERVICE="klipper"
KLIPPY_PIPE="${HOME}/printer_data/comms/klippy.serial"
# New file to track the last successful flash
STATE_FILE="${HOME}/.klipper_mcu_last_flash"

YELLOW='\e[1;33m'
GREEN='\e[1;32m'
RED='\e[1;31m'
NC='\e[0m'

notify() {
    echo -e "${YELLOW}UI-NOTIFY: $1${NC}"
    if [ -p "$KLIPPY_PIPE" ]; then
        echo "RESPOND MSG=\"$1\"" > "$KLIPPY_PIPE"
    fi
}
# --------------------------

notify "🚀 Starting MCU Update Check..."

cd "$KLIPPER_DIR" || { notify "❌ Error: Klipper dir not found"; exit 1; }

# 1. HANDLE "DIRTY" REPO & FETCH
# Stash local changes (fixes the -dirty issue) so git pull works
git stash > /dev/null 2>&1
git fetch origin > /dev/null 2>&1

# 2. CHECK IF UPDATE IS NEEDED (Local vs GitHub)
LOCAL_HASH=$(git rev-parse HEAD)
REMOTE_HASH=$(git rev-parse @{u})
LAST_FLASHED=$(cat "$STATE_FILE" 2>/dev/null)

# Logic: Update if (Local != Remote) OR if (Current Hash hasn't been flashed yet)
if [ "$LOCAL_HASH" == "$REMOTE_HASH" ] && [ "$LOCAL_HASH" == "$LAST_FLASHED" ]; then
    notify "✅ MCU is already running this version ($LOCAL_HASH). Flash saved!"
    exit 0
fi

# 3. PULL & COMPILE
if [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
    notify "🆕 New version found on GitHub. Pulling..."
    git pull > /dev/null 2>&1
    # Update LOCAL_HASH after pull
    LOCAL_HASH=$(git rev-parse HEAD)
else
    notify "🔧 Source is current, but MCU needs a refresh flash..."
fi

# Stop Klipper service
sudo systemctl stop "$KLIPPER_SERVICE"

notify "⚙️ Compiling firmware..."
make clean > /dev/null 2>&1
if make -j$(nproc) > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Compilation successful!${NC}"
else
    notify "❌ Error: Compilation failed!"
    sudo systemctl start "$KLIPPER_SERVICE"
    exit 1
fi

# 4. FLASH
notify "⚡ Flashing MCU ($BOARD_TYPE)..."
if ./scripts/flash-sdcard.sh "$MCU_PATH" "$BOARD_TYPE" > /dev/null 2>&1; then
    # SUCCESS: Save the hash so we don't flash this version again
    echo "$LOCAL_HASH" > "$STATE_FILE"
    notify "🎉 SUCCESS: MCU flashed to $LOCAL_HASH!"
else
    notify "❌ Error: Flashing failed!"
    sudo systemctl start "$KLIPPER_SERVICE"
    exit 1
fi

# 5. RESTART
sudo systemctl start "$KLIPPER_SERVICE"
notify "🏁 Update finished. Run FIRMWARE_RESTART."