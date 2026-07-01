#!/bin/bash

# --- USER CONFIGURATION ---
MCU_PATH="/dev/serial/by-id/usb-Klipper_lpc1769_12345-if00"
BOARD_TYPE="btt-skr-turbo-v1.4"
USER_NAME=$(id -un)
USER_HOME="/home/$USER_NAME"
KLIPPER_DIR="$USER_HOME/klipper"
KLIPPY_PIPE="$USER_HOME/printer_data/comms/klippy.serial"
STATE_FILE="$USER_HOME/.mcu_last_flash_hash"

notify() {
    [ -p "$KLIPPY_PIPE" ] && echo "RESPOND MSG=\"$1\"" > "$KLIPPY_PIPE"
    echo "$(date +'%H:%M:%S') - $1"
}
# --------------------------

cd "$KLIPPER_DIR" || exit

# 1. VERSION CHECK (SAFE)
# We fetch updates but DO NOT use 'clean' or 'stash --all'
# This ensures .config is never touched by git
git fetch origin > /dev/null 2>&1

LOCAL_HASH=$(git rev-parse HEAD)
REMOTE_HASH=$(git rev-parse @{u})
LAST_FLASHED=$(cat "$STATE_FILE" 2>/dev/null)

if [ "$LOCAL_HASH" == "$REMOTE_HASH" ] && [ "$LOCAL_HASH" == "$LAST_FLASHED" ]; then
    notify "✅ MCU version is current. Flash skipped."
    exit 0
fi

# 2. SOURCE UPDATE
if [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
    notify "🆕 Updating Klipper source..."
    # We only stash TRACKED files. .config is ignored, so it stays safe.
    git stash > /dev/null 2>&1
    git pull > /dev/null 2>&1
fi

# 3. COMPILATION
notify "⚙️ Compiling Klipper firmware..."

# Check if .config actually exists before we start
if [ ! -f ".config" ]; then
    notify "❌ ERROR: .config file is missing! Please run 'make menuconfig' manually one last time."
    exit 1
fi

# Use 'make clean' (safe), NEVER 'make distclean' (deletes .config)
make clean > /dev/null 2>&1

if ! make -j$(nproc); then
    notify "❌ ERROR: Compilation failed!"
    exit 1
fi

# 4. VERIFY RESULT
if [ ! -f "out/klipper.bin" ]; then
    notify "❌ ERROR: Binary not created. Check your menuconfig settings."
    exit 1
fi

# 5. FLASH
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
