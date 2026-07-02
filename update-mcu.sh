#!/bin/bash

# --- ABSOLUTE CONFIGURATION ---
USER_NAME="rado"
USER_HOME="/home/$USER_NAME"
MCU_PATH="/dev/serial/by-id/usb-Klipper_lpc1769_0DA0000AA8943BAF8BB3685CC52000F5-if00"
BOARD_TYPE="btt-skr-turbo-v1.4"
CONFIG_SOURCE="$USER_HOME/klipper-kconfigs/tronxy.config"

KLIPPER_DIR="$USER_HOME/klipper"
KLIPPY_PIPE="$USER_HOME/printer_data/comms/klippy.serial"
STATE_FILE="$USER_HOME/.mcu_last_flash_hash"
LOG_FILE="$USER_HOME/printer_data/logs/mcu_update.log"

# Force environment variables for Systemd
export HOME="$USER_HOME"
export USER="$USER_NAME"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

notify() {
    # Log to file with timestamp
    echo -e "$(date +'%H:%M:%S') - $1" >> "$LOG_FILE"
    # Send to UI console (only if pipe exists)
    if [ -p "$KLIPPY_PIPE" ]; then
        echo "RESPOND MSG=\"$1\"" > "$KLIPPY_PIPE"
    fi
}
# ------------------------------

# Clear log and start
echo "--- Update Started: $(date) ---" > "$LOG_FILE"
cd "$KLIPPER_DIR" || { echo "Directory $KLIPPER_DIR not found" >> "$LOG_FILE"; exit 1; }

# 1. VERSION CHECK
git fetch origin > /dev/null 2>&1
LOCAL_HASH=$(git rev-parse HEAD)
LAST_FLASHED=$(cat "$STATE_FILE" 2>/dev/null)

if [ "$LOCAL_HASH" == "$LAST_FLASHED" ]; then
    notify "Success: MCU is already synced with Pi ($LOCAL_HASH). Flash skipped."
    exit 0
fi

notify "Update needed. Current Pi Hash: $LOCAL_HASH"

# 2. CONFIG RESTORATION
if [ -f "$CONFIG_SOURCE" ]; then
    cp "$CONFIG_SOURCE" "$KLIPPER_DIR/.config"
    notify "Applied config from $CONFIG_SOURCE"
else
    notify "Error: $CONFIG_SOURCE not found!"
    exit 1
fi

# 3. COMPILATION
notify "Compiling Klipper firmware... (Please wait)"
make clean >> "$LOG_FILE" 2>&1
if ! make -j$(nproc) >> "$LOG_FILE" 2>&1; then
    notify "Error: Compilation failed! Check the log file."
    exit 1
fi

# 4. BINARY VERIFICATION
if [ ! -f "out/klipper.bin" ]; then
    notify "Error: klipper.bin not found after build!"
    exit 1
fi
notify "Firmware compiled successfully."

# 5. STOP AND FLASH
notify "Stopping Klipper and flashing MCU..."
sudo /usr/bin/systemctl stop klipper
sleep 3

# Run the flash script
if ./scripts/flash-sdcard.sh "$MCU_PATH" "$BOARD_TYPE" >> "$LOG_FILE" 2>&1; then
    echo "$LOCAL_HASH" > "$STATE_FILE"
    notify "SUCCESS: MCU flashed successfully!"
else
    notify "Error: Flash tool failed! Check logs."
fi

# 6. RESTART
sudo /usr/bin/systemctl start klipper
notify "Process finished. Run FIRMWARE_RESTART."
