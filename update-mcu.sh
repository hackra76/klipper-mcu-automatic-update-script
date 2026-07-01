#!/bin/bash
# --- CONFIG ---
MCU_PATH="/dev/serial/by-id/usb-Klipper_lpc1769_12345-if00"
BOARD_TYPE="btt-skr-turbo-v1.4"
KLIPPER_DIR="${HOME}/klipper"
KLIPPY_PIPE="${HOME}/printer_data/comms/klippy.serial"
STATE_FILE="${HOME}/.mcu_last_flash_hash"

notify() {
    [ -p "$KLIPPY_PIPE" ] && echo "RESPOND MSG=\"$1\"" > "$KLIPPY_PIPE"
    echo -e "$1"
}

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

# 2. Build Process
notify "⚙️ Compiling Klipper..."
make clean
if ! make -j$(nproc); then
    notify "❌ ERROR: Compilation failed!"
    exit 1
fi

# 3. Identify the Output File (.bin or .hex)
if [ -f "out/klipper.bin" ]; then
    FLASH_FILE="out/klipper.bin"
elif [ -f "out/klipper.elf.hex" ]; then
    FLASH_FILE="out/klipper.elf.hex"
else
    notify "❌ ERROR: No firmware file found in out/ folder!"
    exit 1
fi

# 4. Flashing
notify "🛑 Stopping Klipper and Flashing MCU..."
sudo systemctl stop klipper
sleep 2

# We pass the identified file to the flash script
if ./scripts/flash-sdcard.sh "$MCU_PATH" "$BOARD_TYPE"; then
    echo "$LOCAL_HASH" > "$STATE_FILE"
    notify "🎉 SUCCESS: MCU flashed using $FLASH_FILE!"
else
    notify "❌ ERROR: Flashing tool failed!"
fi

sudo systemctl start klipper
