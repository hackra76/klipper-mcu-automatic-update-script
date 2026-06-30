#!/bin/bash
set -e

# --- USER CONFIGURATION ---
# Update these paths to match your specific setup:
MCU_PATH="/dev/serial/by-id/your-mcu-path-here"
BOARD_TYPE="your-board-type-here"
KLIPPER_DIR="${HOME}/klipper"
MOONRAKER_URL="http://127.0.0.1:7125"
# --------------------------

echo "🔍 Fetching current MCU version..."
# We use curl to ask Moonraker for the MCU status, and grep to extract just the version string
CURRENT_VERSION=$(curl -s "${MOONRAKER_URL}/printer/objects/query?mcu" | grep -oP '"mcu_version":\s*"\K[^"]+')

echo "⬇️ Pulling latest Klipper source..."
cd "$KLIPPER_DIR"
git pull

# Compile a quick check-build to get the new version string
echo "⚙️ Compiling a quick check-build..."
make clean > /dev/null
make -j$(nproc) > /dev/null

echo "🔍 Verifying version..."
if [ -f "out/compile_time.h" ]; then
    NEW_VERSION=$(grep -oP '#define VERSION "\K[^"]+' out/compile_time.h)
    echo "Newly Compiled Version: $NEW_VERSION"
else
    echo "❌ Error: Compilation failed or file 'out/compile_time.h' not found."
    exit 1
fi

# Compare the versions
if [ "$CURRENT_VERSION" == "$NEW_VERSION" ] && [ -n "$CURRENT_VERSION" ]; then
    echo "✅ Firmware is already up to date ($NEW_VERSION). Skipping flash."
else
    echo "💾 Version mismatch detected (Current: $CURRENT_VERSION | New: $NEW_VERSION)."
    echo "🚀 Flashing via SD card..."
    ./scripts/flash-sdcard.sh "$MCU_PATH" "$BOARD_TYPE"
    echo "✅ Flash complete!"
fi