#!/bin/bash

# --- USER CONFIGURATION ---
MCU_PATH="/dev/serial/by-id/usb-Klipper_lpc1769_12345-if00"
BOARD_TYPE="btt-skr-turbo-v1.4"
KLIPPER_DIR="${HOME}/klipper"
KLIPPER_SERVICE="klipper"
# Path to moonraker/klipper pipe (standard for most installs)
KLIPPY_PIPE="${HOME}/printer_data/comms/klippy.serial"

# Colors for Terminal
YELLOW='\e[1;33m'
GREEN='\e[1;32m'
RED='\e[1;31m'
NC='\e[0m'

# Function to send popups to Mainsail/Fluidd UI
notify() {
    echo -e "${YELLOW}UI-NOTIFY: $1${NC}"
    if [ -p "$KLIPPY_PIPE" ]; then
        echo "RESPOND MSG=\"$1\"" > "$KLIPPY_PIPE"
    fi
}
# --------------------------

notify "🚀 Starting MCU Update Check..."

cd "$KLIPPER_DIR" || { notify "❌ Error: Klipper dir not found"; exit 1; }

# 1. FLASH-SAVER
git fetch origin > /dev/null 2>&1
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse @{u})

if [ "$LOCAL" == "$REMOTE" ]; then
    notify "✅ MCU is already up to date. Flash memory saved!"
    exit 0
fi

# 2. UPDATE & COMPILE
notify "🆕 New version found. Compiling firmware..."
git pull > /dev/null 2>&1

# Stop Klipper to free the serial port
sudo systemctl stop "$KLIPPER_SERVICE"

make clean > /dev/null 2>&1
if make -j$(nproc) > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Compilation successful!${NC}"
else
    notify "❌ Error: Compilation failed!"
    sudo systemctl start "$KLIPPER_SERVICE"
    exit 1
fi

# 3. FLASH
notify "⚡ Flashing MCU ($BOARD_TYPE)..."
if ./scripts/flash-sdcard.sh "$MCU_PATH" "$BOARD_TYPE" > /dev/null 2>&1; then
    notify "🎉 SUCCESS: MCU flashed! Restarting Klipper..."
else
    notify "❌ Error: Flashing failed!"
    sudo systemctl start "$KLIPPER_SERVICE"
    exit 1
fi

sudo systemctl start "$KLIPPER_SERVICE"
notify "🏁 Update finished. Run FIRMWARE_RESTART."