#!/bin/bash

# --- CONFIGURATION ---
MCU_PATH="/dev/serial/by-id/usb-Klipper_lpc1769_0DA0000AA8943BAF8BB3685CC52000F5-if00"
BOARD_TYPE="btt-skr-turbo-v1.4"
CONFIG_SOURCE="/home/rado/klipper-kconfigs/tronxy.config"

KLIPPER_DIR="/home/rado/klipper"
KLIPPY_PIPE="/home/rado/printer_data/comms/klippy.serial"
STATE_FILE="/home/rado/.mcu_last_flash_hash"
LOG_FILE="/home/rado/printer_data/logs/mcu_update.log"

# Force Environment
export HOME="/home/rado"
export USER="rado"

notify() {
    echo -e "$(date +'%H:%M:%S') - $1" >> "$LOG_FILE"
    if [ -p "$KLIPPY_PIPE" ]; then
        # Send message in the background so the script doesn't hang
        (echo "RESPOND MSG=\"$1\"" > "$KLIPPY_PIPE") &
    fi
}
# ---------------------

echo "--- Script Started: $(date) ---" > "$LOG_FILE"

# 1. VERSION CHECK
cd "$KLIPPER_DIR" || { echo "ERROR: Cannot find Klipper directory" >> "$LOG_FILE"; exit 1; }
git fetch origin > /dev/null 2>&1
LOCAL_HASH=$(git rev-parse HEAD)
LAST_FLASHED=$(cat "$STATE_FILE" 2>/dev/null)

if [ "$LOCAL_HASH" == "$LAST_FLASHED" ]; then
    notify "Success: MCU already synced with Pi. Flash skipped."
    exit 0
fi

notify "Update needed for MCU..."

# 2. CONFIG RESTORE
if [ -f "$CONFIG_SOURCE" ]; then
    cp "$CONFIG_SOURCE" "$KLIPPER_DIR/.config"
    notify "Applied config from: tronxy.config"
else
    notify "Error: $CONFIG_SOURCE not found!"
    exit 1
fi

# 3. COMPILATION
notify "Compiling firmware... (Please wait)"
make clean >> "$LOG_FILE" 2>&1
# We capture ALL output of make now
if ! make -j$(nproc) >> "$LOG_FILE" 2>&1; then
    notify "Error: Compilation failed. See $LOG_FILE"
    exit 1
fi

if [ ! -f "out/klipper.bin" ]; then
    notify "Error: klipper.bin not found!"
    exit 1
fi

# 4. STOP AND FLASH
notify "Stopping Klipper and flashing..."
sudo /usr/bin/systemctl stop klipper
sleep 2

if ./scripts/flash-sdcard.sh "$MCU_PATH" "$BOARD_TYPE" >> "$LOG_FILE" 2>&1; then
    echo "$LOCAL_HASH" > "$STATE_FILE"
    notify "🎉 SUCCESS: MCU flashed!"
else
    notify "Error: Flash tool failed!"
fi

sudo /usr/bin/systemctl start klipper
notify "Process finished."
