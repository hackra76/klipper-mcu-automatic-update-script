#!/bin/bash

# --- USER CONFIGURATION ---
MCU_PATH="/dev/serial/by-id/usb-Klipper_lpc1769_12345-if00"
BOARD_TYPE="btt-skr-turbo-v1.4"
KLIPPER_DIR="${HOME}/klipper"
# Using the serial pipe you confirmed exists
KLIPPY_PIPE="${HOME}/printer_data/comms/klippy.serial"
STATE_FILE="${HOME}/.mcu_last_flash_hash"

notify() {
    # Send message to Klipper Console
    if [ -p "$KLIPPY_PIPE" ]; then
        echo "RESPOND MSG=\"$1\"" > "$KLIPPY_PIPE"
    fi
    # Log to file with timestamp
    echo -e "$(date +'%H:%M:%S') - $1"
}
# --------------------------

cd "$KLIPPER_DIR" || exit

# 1. Clean dirty state and Fetch updates
notify "🔍 Checking for Klipper updates..."
git stash push --all > /dev/null 2>&1
git fetch origin > /dev/null 2>&1

LOCAL_HASH=$(git rev-parse HEAD)
REMOTE_HASH=$(git rev-parse @{u})
LAST_FLASHED=$(cat "$STATE_FILE" 2>/dev/null)

# 2. Flash-Saver Check
if [ "$LOCAL_HASH" == "$REMOTE_HASH" ] && [ "$LOCAL_HASH" == "$LAST_FLASHED" ]; then
    notify "✅ MCU is already up to date. Flash skipped."
    exit 0
fi

# 3. Compile
notify "⚙️ Compiling Klipper firmware..."
make clean > /dev/null 2>&1
if ! make -j$(nproc); then
    notify "❌ ERROR: Compilation failed! Check Klipper config."
    exit 1
fi

# 4. Verify the correct file type was created (.bin for LPC1769)
if [ ! -f "out/klipper.bin" ]; then
    if [ -f "out/klipper.elf.hex" ]; then
        notify "❌ ERROR: Wrong architecture! Created .hex instead of .bin."
        notify "Please run 'make menuconfig' and select LPC1769."
    else
        notify "❌ ERROR: No firmware file created!"
    fi
    exit 1
fi

# 5. Safe Flash (Klipper service is stopped only after successful build)
notify "🛑 Stopping Klipper and flashing MCU..."
sudo systemctl stop klipper
sleep 2

if ./scripts/flash-sdcard.sh "$MCU_PATH" "$BOARD_TYPE"; then
    echo "$LOCAL_HASH" > "$STATE_FILE"
    notify "🎉 SUCCESS: MCU flashed successfully!"
else
    notify "❌ ERROR: Flashing tool failed!"
fi

sudo systemctl start klipper
