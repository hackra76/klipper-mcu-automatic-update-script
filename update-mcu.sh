#!/bin/bash

# --- USER CONFIGURATION (Updated from KIAUH log) ---
MCU_PATH="/dev/serial/by-id/usb-Klipper_lpc1769_0DA0000AA8943BAF8BB3685CC52000F5-if00"
BOARD_TYPE="btt-skr-turbo-v1.4"
# Your custom config location found in the log:
CONFIG_SOURCE="${HOME}/klipper-kconfigs/tronxy.config"

KLIPPER_DIR="${HOME}/klipper"
KLIPPY_PIPE="${HOME}/printer_data/comms/klippy.serial"
STATE_FILE="${HOME}/.mcu_last_flash_hash"

notify() {
    [ -p "$KLIPPY_PIPE" ] && echo "RESPOND MSG=\"$1\"" > "$KLIPPY_PIPE"
    echo -e "$(date +'%H:%M:%S') - $1"
}
# --------------------------------------------------

cd "$KLIPPER_DIR" || exit

# 1. Version Check (Flash-Saver)
git fetch origin > /dev/null 2>&1
LOCAL_HASH=$(git rev-parse HEAD)
REMOTE_HASH=$(git rev-parse @{u})
LAST_FLASHED=$(cat "$STATE_FILE" 2>/dev/null)

if [ "$LOCAL_HASH" == "$REMOTE_HASH" ] && [ "$LOCAL_HASH" == "$LAST_FLASHED" ]; then
    notify "✅ MCU is already up to date. Flash skipped."
    exit 0
fi

# 2. Source & Config Preparation
if [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
    notify "🆕 Updating Klipper source..."
    git stash > /dev/null 2>&1
    git pull > /dev/null 2>&1
fi

# Ensure the correct config is used (from your tronxy.config)
if [ -f "$CONFIG_SOURCE" ]; then
    cp "$CONFIG_SOURCE" .config
    notify "📋 Applied $CONFIG_SOURCE"
else
    notify "❌ ERROR: $CONFIG_SOURCE not found!"
    exit 1
fi

# 3. Compilation
notify "⚙️ Compiling Klipper firmware..."
make clean > /dev/null 2>&1
if ! make -j$(nproc); then
    notify "❌ ERROR: Compilation failed!"
    exit 1
fi

# 4. Flash
if [ -f "out/klipper.bin" ]; then
    notify "🛑 Stopping Klipper and flashing MCU..."
    sudo /usr/bin/systemctl stop klipper
    sleep 2
    
    if ./scripts/flash-sdcard.sh "$MCU_PATH" "$BOARD_TYPE"; then
        echo "$(git rev-parse HEAD)" > "$STATE_FILE"
        notify "🎉 SUCCESS: MCU flashed successfully!"
    else
        notify "❌ ERROR: Flashing failed!"
    fi
    sudo /usr/bin/systemctl start klipper
else
    notify "❌ ERROR: out/klipper.bin not found!"
    exit 1
fi
