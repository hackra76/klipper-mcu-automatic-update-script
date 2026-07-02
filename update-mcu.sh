#!/bin/bash

# --- CONFIGURATION ---
USER_NAME="rado"
USER_HOME="/home/$USER_NAME"
MCU_PATH="/dev/serial/by-id/usb-Klipper_lpc1769_0DA0000AA8943BAF8BB3685CC52000F5-if00"
BOARD_TYPE="btt-skr-turbo-v1.4"
CONFIG_SOURCE="$USER_HOME/klipper-kconfigs/tronxy.config"

KLIPPER_DIR="$USER_HOME/klipper"
STATE_FILE="$USER_HOME/.mcu_last_flash_hash"
LOG_FILE="$USER_HOME/printer_data/logs/mcu_update.log"

# Force environment for the background service
export HOME="$USER_HOME"
export USER="$USER_NAME"

notify() {
    # 1. Log to the file
    echo -e "$(date +'%H:%M:%S') - $1" >> "$LOG_FILE"
    
    # 2. Send to UI via Moonraker API (Port 7125)
    # This is the most reliable way to send console messages
    url_encoded_msg=$(echo "$1" | sed 's/ /%20/g')
    curl -s -X POST "http://localhost:7125/printer/gcode/script?script=RESPOND%20MSG%3D%22$url_encoded_msg%22" > /dev/null 2>&1 &
}
# ---------------------

echo "--- New Update Session: $(date) ---" > "$LOG_FILE"
cd "$KLIPPER_DIR" || { echo "Error: Klipper dir not found" >> "$LOG_FILE"; exit 1; }

# 1. VERSION CHECK
notify "🔍 Checking for updates..."
git fetch origin > /dev/null 2>&1

LOCAL_HASH=$(git rev-parse HEAD)
REMOTE_HASH=$(git rev-parse @{u})
LAST_FLASHED=$(cat "$STATE_FILE" 2>/dev/null)

# Exit if everything is already synced
if [ "$LOCAL_HASH" == "$REMOTE_HASH" ] && [ "$LOCAL_HASH" == "$LAST_FLASHED" ]; then
    notify "✅ MCU is already up to date. Flash skipped."
    exit 0
fi

# 2. SOURCE PREPARATION
if [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
    notify "🆕 New version found. Updating source..."
    # Safe stash: only hides tracked files, leaves .config alone
    git stash > /dev/null 2>&1
    git pull > /dev/null 2>&1
fi

# Ensure your Tronxy config is applied
if [ -f "$CONFIG_SOURCE" ]; then
    cp "$CONFIG_SOURCE" .config
    notify "📋 Applied config: tronxy.config"
else
    notify "❌ ERROR: $CONFIG_SOURCE not found!"
    exit 1
fi

# 3. COMPILATION
notify "⚙️ Compiling firmware... (This takes 1-2 mins)"
make clean >> "$LOG_FILE" 2>&1
if ! make -j$(nproc) >> "$LOG_FILE" 2>&1; then
    notify "❌ ERROR: Compilation failed! Check the log file."
    exit 1
fi

# 4. VERIFY RESULT
if [ ! -f "out/klipper.bin" ]; then
    notify "❌ ERROR: klipper.bin was not created!"
    exit 1
fi

# 5. FLASH
notify "🛑 Stopping Klipper and flashing MCU..."
sudo /usr/bin/systemctl stop klipper
sleep 2

if ./scripts/flash-sdcard.sh "$MCU_PATH" "$BOARD_TYPE" >> "$LOG_FILE" 2>&1; then
    echo "$(git rev-parse HEAD)" > "$STATE_FILE"
    notify "🎉 SUCCESS: MCU flashed successfully!"
else
    notify "❌ ERROR: Flashing failed!"
fi

# 6. RESTART
sudo /usr/bin/systemctl start klipper
notify "🏁 Finished. Run FIRMWARE_RESTART."
