#!/bin/bash
set -e

# --- USER CONFIGURATION ---
MCU_PATH="/dev/serial/by-id/your-mcu-path-here"
BOARD_TYPE="your-board-type-here"
KLIPPER_DIR="${HOME}/klipper"
MOONRAKER_URL="http://127.0.0.1:7125"
# --------------------------

echo "🔍 Fetching current MCU version..."
CURRENT_VERSION=$(curl -s "${MOONRAKER_URL}/printer/objects/query?mcu" | grep -oP '"mcu_version":\s*"\K[^"]+')

echo "⬇️ Pulling latest Klipper source..."
cd "$KLIPPER_DIR"
git pull

# Create a temporary build to check the version string without overwriting firmware yet
echo "⚙️ Compiling a quick check-build..."
make clean > /dev/null
make -j$(nproc) > /dev/null
NEW_VERSION=$(grep -oP '#define VERSION "\K[^"]+' out/compile_time.h)

if [ "$CURRENT_VERSION" == "$NEW_VERSION" ] && [ -n "$CURRENT_VERSION" ]; then
    echo "✅ Firmware is already up to date ($NEW_VERSION). Skipping flash."
else
    echo "💾 Version mismatch detected (Current: $CURRENT_VERSION | New: $NEW_VERSION)."
    echo "🚀 Flashing via SD card..."
    ./scripts/flash-sdcard.sh "$MCU_PATH" "$BOARD_TYPE"
    echo "✅ Flash complete!"
fi