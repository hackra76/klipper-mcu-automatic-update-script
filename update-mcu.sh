#!/bin/bash
set -e

# ENTER YOUR EXACT MCU PATH HERE
MCU_PATH="/dev/serial/by-id/usb-Klipper_lpc1769_12345-if00"
BOARD_TYPE="btt-skr-turbo-v1.4"

echo "🔍 Checking MCU connection..."
if [ ! -e "$MCU_PATH" ]; then
    echo "❌ Error: MCU not found at $MCU_PATH!"
    echo "Check the USB cable or printer power."
    exit 1
fi

echo "🛑 Stopping Klipper..."
sudo systemctl stop klipper

echo "⬇️ Pulling the latest Klipper updates..."
cd ~/klipper
git pull

echo "🧹 Cleaning previous build..."
make clean

echo "⚙️ Compiling new firmware..."
# Auto-detecting the number of CPU cores for maximum speed
make -j$(nproc)

echo "💾 Flashing firmware to the SD card..."
./scripts/flash-sdcard.sh $MCU_PATH $BOARD_TYPE

echo "🚀 Starting Klipper..."
sudo systemctl start klipper

echo "✅ MCU update completed!"