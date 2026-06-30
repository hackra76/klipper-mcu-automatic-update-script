#!/bin/bash
set -e

# --- USER CONFIGURATION ---
MCU_PATH="/dev/serial/by-id/your-mcu-path-here"
BOARD_TYPE="your-board-type-here"
KLIPPER_DIR="${HOME}/klipper"
MOONRAKER_URL="http://127.0.0.1:7125"
# --------------------------

echo "🔍 Checking MCU connection..."
# (You can actually remove this check too if you're only flashing via SD card)

echo "📡 Checking firmware version..."
CURRENT_VERSION=$(curl -s "${MOONRAKER_URL}/printer/objects/query?mcu" | grep -oP '"mcu_version":\s*"\K[^"]+')

echo "⬇️ Pulling latest Klipper..."
cd "$KLIPPER_DIR"
git pull

echo "⚙️ Compiling firmware..."
make clean
make -j$(nproc)

echo "🔍 Verifying version..."
NEW_VERSION=$(grep -oP '#define VERSION "\K[^"]+' out/compile_time.h)

if [ "$CURRENT_VERSION" == "$NEW_VERSION" ] && [ -n "$CURRENT_VERSION" ]; then
    echo "✅ Version is already up to date ($NEW_VERSION). Skipping flash."
else
    echo "💾 Flashing via SD card..."
    ./scripts/flash-sdcard.sh "$MCU_PATH" "$BOARD_TYPE"
    echo "✅ Flash complete!"
fi