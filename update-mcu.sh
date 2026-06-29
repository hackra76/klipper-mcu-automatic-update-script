#!/bin/bash
set -e

# --- USER CONFIGURATION ---
MCU_PATH="/dev/serial/by-id/usb-Klipper_lpc1769_12345-if00" # UPDATE THIS
BOARD_TYPE="btt-skr-turbo-v1.4"                             # UPDATE THIS IF NEEDED
KLIPPER_DIR="${HOME}/klipper"
KLIPPER_SERVICE="klipper"
# --------------------------

# Safety Confirmation
echo "⚠️  WARNING: You are about to flash firmware to your printer's MCU."
echo "This operation carries a risk of flashing incorrect firmware or bricking your board."
read -p "Are you sure you want to proceed? (y/N): " confirm

if [[ "$confirm" != [yY] ]]; then
    echo "❌ Update aborted by user."
    exit 1
fi

echo "🔍 Checking MCU connection..."
if [ ! -e "$MCU_PATH" ]; then
    echo "❌ Error: MCU not found at $MCU_PATH!"
    echo "Check the USB cable or printer power."
    exit 1
fi

echo "📝 Checking for Klipper configuration..."
if [ ! -f "${KLIPPER_DIR}/.config" ]; then
    echo "❌ Error: No .config file found in ${KLIPPER_DIR}!"
    echo "Please run 'make menuconfig' in your Klipper directory first."
    exit 1
fi

echo "🛑 Stopping ${KLIPPER_SERVICE} service..."
sudo systemctl stop "$KLIPPER_SERVICE"

echo "⬇️ Pulling the latest Klipper updates..."
cd "$KLIPPER_DIR"
git pull

echo "🧹 Cleaning previous build..."
make clean

echo "⚙️ Compiling new firmware..."
make -j$(nproc)

echo "💾 Flashing firmware to the SD card..."
./scripts/flash-sdcard.sh "$MCU_PATH" "$BOARD_TYPE"

echo "🚀 Starting ${KLIPPER_SERVICE} service..."
sudo systemctl start "$KLIPPER_SERVICE"

echo "✅ MCU update completed successfully!"