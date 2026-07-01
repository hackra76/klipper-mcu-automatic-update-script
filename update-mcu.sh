#!/bin/bash

# --- USER CONFIGURATION ---
# Replace with your actual ID from: ls /dev/serial/by-id/
MCU_PATH="/dev/serial/by-id/usb-Klipper_lpc1769_12345-if00"
BOARD_TYPE="btt-skr-turbo-v1.4"
KLIPPER_DIR="${HOME}/klipper"
KLIPPY_PIPE="${HOME}/printer_data/comms/klippy.serial"
STATE_FILE="${HOME}/.mcu_last_flash_hash"

# Notification function for Mainsail/Fluidd UI popups
notify() {
    [ -p "$KLIPPY_PIPE" ] && echo "RESPOND MSG=\"$1\"" > "$KLIPPY_PIPE"
    echo -e "$1"
}
# --------------------------

cd "$KLIPPER_DIR" || exit

# 1. Version Comparison (Flash-Saver Logic)
git fetch origin > /dev/null 2>&1
LOCAL_HASH=$(git rev-parse HEAD)
REMOTE_HASH=$(git rev-parse @{u})
LAST_FLASHED=$(cat "$STATE_FILE" 2>/dev/null)

if [ "$LOCAL_HASH" == "$REMOTE_HASH" ] && [ "$LOCAL_HASH" == "$LAST_FLASHED" ]; then
    notify "✅ MCU is already up to date. No flash required."
    exit 0
fi

# 2. Compilation Process
notify "⚙️ Compiling Klipper firmware..."
make clean > /dev/null 2>&1
if ! make -j$(nproc); then
    notify "❌ ERROR: Compilation failed! Check the logs."
    exit 1
fi

# 3. Output Detection (LPC176x requires .bin)
if [ -f "out/klipper.bin" ]; then
    notify "✅ Build successful (out/klipper.bin)."
elif [ -f "out/klipper.elf.hex" ]; then
    notify "✅ Build successful (out/klipper.elf.hex)."
else
    notify "❌ ERROR: No firmware file found in out/ folder!"
    exit 1
fi

# 4. Flashing (Stop service, Flash, Start service)
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
