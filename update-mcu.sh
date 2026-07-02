#!/bin/bash

# --- CONFIGURATION ---
MCU_PATH="/dev/serial/by-id/usb-Klipper_lpc1769_0DA0000AA8943BAF8BB3685CC52000F5-if00"
BOARD_TYPE="btt-skr-turbo-v1.4"
# Your custom config location
CONFIG_SOURCE="/home/rado/klipper-kconfigs/tronxy.config"

KLIPPER_DIR="/home/rado/klipper"
KLIPPY_PIPE="/home/rado/printer_data/comms/klippy.serial"
STATE_FILE="/home/rado/.mcu_last_flash_hash"
LOG_FILE="/home/rado/printer_data/logs/mcu_update.log"

notify() {
    # Send to UI console
    if [ -p "$KLIPPY_PIPE" ]; then
        echo "RESPOND MSG=\"$1\"" > "$KLIPPY_PIPE"
    fi
    # Log to file with timestamp
    echo -e "$(date +'%H:%M:%S') - $1" >> "$LOG_FILE"
}
# ---------------------

# Clear log for new attempt
echo "--- New Update Attempt ---" > "$LOG_FILE"
cd "$KLIPPER_DIR" || exit

# 1. VERSION CHECK
git fetch origin > /dev/null 2>&1
LOCAL_HASH=$(git rev-parse HEAD)
LAST_FLASHED=$(cat "$STATE_FILE" 2>/dev/null)

# If the Pi version matches our last successful flash, STOP.
if [ "$LOCAL_HASH" == "$LAST_FLASHED" ]; then
    notify "✅ MCU is already synced with Pi ($LOCAL_HASH). Flash skipped."
    exit 0
fi

notify "🆕 Update needed. Current Pi Hash: $LOCAL_HASH"

# 2. PREPARE CONFIG
# We don't use 'git stash --all' because it hides the .config file.
# We just copy your known good config directly.
if [ -f "$CONFIG_SOURCE" ]; then
    cp "$CONFIG_SOURCE" "$KLIPPER_DIR/.config"
    notify "📋 Applied $BOARD_TYPE config from $CONFIG_SOURCE"
else
    notify "❌ ERROR: Config source not found at $CONFIG_SOURCE"
    exit 1
fi

# 3. COMPILATION
notify "⚙️ Compiling Klipper firmware..."
make clean >> "$LOG_FILE" 2>&1

# Run make and capture ALL output to the log
if ! make -j$(nproc) >> "$LOG_FILE" 2>&1; then
    notify "❌ ERROR: Compilation failed! Check the log file."
    exit 1
fi

# 4. VERIFY BINARY
if [ ! -f "out/klipper.bin" ]; then
    notify "❌ ERROR: out/klipper.bin not found after build!"
    exit 1
fi

# 5. STOP AND FLASH
notify "🛑 Stopping Klipper and flashing MCU..."
sudo /usr/bin/systemctl stop klipper
sleep 2

# We run the flash script and capture its output
if ./scripts/flash-sdcard.sh "$MCU_PATH" "$BOARD_TYPE" >> "$LOG_FILE" 2>&1; then
    # ONLY write the state file if the flash tool reported SUCCESS
    echo "$LOCAL_HASH" > "$STATE_FILE"
    notify "🎉 SUCCESS: MCU flashed successfully!"
else
    notify "❌ ERROR: Flash tool failed! Check logs."
fi

# 6. RESTART
sudo /usr/bin/systemctl start klipper
notify "🏁 Process finished."
