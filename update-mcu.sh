#!/bin/bash

# --- USER CONFIGURATION ---
MCU_PATH="/dev/serial/by-id/usb-Klipper_lpc1769_12345-if00"
BOARD_TYPE="btt-skr-turbo-v1.4"
KLIPPER_DIR="${HOME}/klipper"
KLIPPY_PIPE="${HOME}/printer_data/comms/klippy.serial"
STATE_FILE="${HOME}/.mcu_last_flash_hash"

notify() {
    [ -p "$KLIPPY_PIPE" ] && echo "RESPOND MSG=\"$1\"" > "$KLIPPY_PIPE"
    echo -e "$1"
}
# --------------------------

cd "$KLIPPER_DIR" || exit

# 1. Version Check
git fetch origin > /dev/null 2>&1
LOCAL_HASH=$(git rev-parse HEAD)
REMOTE_HASH=$(git rev-parse @{u})
LAST_FLASHED=$(cat "$STATE_FILE" 2>/dev/null)

if [ "$LOCAL_HASH" == "$REMOTE_HASH" ] && [ "$LOCAL_HASH" == "$LAST_FLASHED" ]; then
    notify "✅ MCU is already up to date."
    exit 0
fi

# 2. Compilation
notify "⚙️ Compiling Klipper $LOCAL_HASH..."
make clean > /dev/null 2>&1

# We run make and log errors to the mcu_update.log
if ! make -j$(nproc); then
    notify "❌ ERROR: Compilation failed! Check logs."
    exit 1
fi

# 3. VERIFY BINARY BEFORE STOPPING KLIPPER
if [ ! -f "out/klipper.bin" ]; then
    # Check if maybe it built a .hex (AVR) instead of .bin (LPC/ARM)
    if [ -f "out/klipper.elf.hex" ]; then
        notify "❌ ERROR: Architecture is wrong! Created .hex instead of .bin."
        notify "Please run 'make menuconfig' and set to LPC1769."
    else
        notify "❌ ERROR: No binary found in out/ folder!"
    fi
    exit 1
fi

# 4. Flashing
notify "🛑 Stopping Klipper and flashing MCU..."
sudo systemctl stop klipper
sleep 2

if ./scripts/flash-sdcard.sh "$MCU_PATH" "$BOARD_TYPE"; then
    echo "$LOCAL_HASH" > "$STATE_FILE"
    notify "🎉 SUCCESS: MCU flashed successfully!"
else
    notify "❌ ERROR: Flashing failed!"
fi

sudo systemctl start klipper
