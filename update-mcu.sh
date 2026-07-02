#!/bin/bash

# --- CONFIGURATION ---
USER_NAME="rado"
USER_HOME="/home/$USER_NAME"
MCU_PATH="/dev/serial/by-id/usb-Klipper_lpc1769_0DA0000AA8943BAF8BB3685CC52000F5-if00"
BOARD_TYPE="btt-skr-turbo-v1.4"
# Path to your verified KIAUH config
CONFIG_SOURCE="$USER_HOME/klipper-kconfigs/tronxy.config"

KLIPPER_DIR="$USER_HOME/klipper"
# Communication pipes for UI notifications
KLIPPY_PIPE="$USER_HOME/printer_data/comms/klippy.serial"
KLIPPY_SOCK="$USER_HOME/printer_data/comms/klippy.sock"

STATE_FILE="$USER_HOME/.mcu_last_flash_hash"
LOG_FILE="$USER_HOME/printer_data/logs/mcu_update.log"

# Force environment for Systemd
export HOME="$USER_HOME"
export USER="$USER_NAME"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

notify() {
    # 1. Log to file
    echo -e "$(date +'%H:%M:%S') - $1" >> "$LOG_FILE"
    
    # 2. Try Serial Pipe (for standard RESPOND)
    if [ -p "$KLIPPY_PIPE" ]; then
        (echo "RESPOND MSG=\"$1\"" > "$KLIPPY_PIPE") &
    fi

    # 3. Try Unix Socket (Fallback for Moonraker/Mainsail)
    if [ -S "$KLIPPY_SOCK" ]; then
        (echo -e "{\"method\": \"gcode/script\", \"params\": {\"script\": \"RESPOND MSG=\\\"$1\\\"\"}}" | nc -U -w 1 "$KLIPPY_SOCK" > /dev/null 2>&1) &
    fi
}
# ---------------------

# Start clean log
echo "--- Update Session Started: $(date) ---" > "$LOG_FILE"
cd "$KLIPPER_DIR" || { echo "Error: Klipper directory not found" >> "$LOG_FILE"; exit 1; }

# 1. Version Check
git fetch origin > /dev/null 2>&1
LOCAL_HASH=$(git rev-parse HEAD)
LAST_FLASHED=$(cat "$STATE_FILE" 2>/dev/null)

if [ "$LOCAL_HASH" == "$LAST_FLASHED" ]; then
    notify "✅ MCU is already synced with Pi. Flash skipped."
    exit 0
fi

notify "🆕 Update detected. Pi version: $LOCAL_HASH"

# 2. Restore Config (Prevents build failure)
if [ -f "$CONFIG_SOURCE" ]; then
    cp "$CONFIG_SOURCE" "$KLIPPER_DIR/.config"
    notify "📋 Applied firmware config: tronxy.config"
else
    notify "❌ ERROR: Config source not found at $CONFIG_SOURCE"
    exit 1
fi

# 3. Compilation
notify "⚙️ Compiling Klipper firmware..."
make clean >> "$LOG_FILE" 2>&1
if ! make -j$(nproc) >> "$LOG_FILE" 2>&1; then
    notify "❌ ERROR: Compilation failed! Check the logs."
    exit 1
fi

# 4. Verify Result
if [ ! -f "out/klipper.bin" ]; then
    notify "❌ ERROR: out/klipper.bin not found after build!"
    exit 1
fi

# 5. Flash (Service is only stopped AFTER successful build)
notify "🛑 Stopping Klipper and flashing MCU..."
sudo /usr/bin/systemctl stop klipper
sleep 2

if ./scripts/flash-sdcard.sh "$MCU_PATH" "$BOARD_TYPE" >> "$LOG_FILE" 2>&1; then
    echo "$LOCAL_HASH" > "$STATE_FILE"
    notify "🎉 SUCCESS: MCU flashed successfully!"
else
    notify "❌ ERROR: Flashing failed! Hardware may be disconnected."
fi

# 6. Restart
sudo /usr/bin/systemctl start klipper
notify "🏁 Process finished. Run FIRMWARE_RESTART if needed."
