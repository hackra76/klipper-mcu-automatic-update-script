#!/bin/bash
set -e

# --- USER CONFIGURATION ---
MCU_PATH="/dev/serial/by-id/usb-Klipper_lpc1769_12345-if00" # UPDATE THIS
BOARD_TYPE="btt-skr-turbo-v1.4"                             # UPDATE THIS IF NEEDED
KLIPPER_DIR="${HOME}/klipper"
KLIPPER_SERVICE="klipper"
MOONRAKER_URL="http://127.0.0.1:7125"                       # Default Moonraker API address
# --------------------------

echo "🔍 Checking MCU connection..."
if [ ! -e "$MCU_PATH" ]; then
    echo "❌ Error: MCU not found at $MCU_PATH!"
    echo "Check the USB cable or printer power."
    exit 1
fi

echo "📡 Fetching currently flashed MCU version via Moonraker..."
# We use curl to ask Moonraker for the MCU status, and grep to extract just the version string
CURRENT_VERSION=$(curl -s "${MOONRAKER_URL}/printer/objects/query?mcu" | grep -oP '"mcu_version":\s*"\K[^"]+')

if [ -z "$CURRENT_VERSION" ]; then
    echo "⚠️ Could not read current version (Klipper might be disconnected). Will force flash."
else
    echo "Current MCU Version: $CURRENT_VERSION"
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

echo "🔍 Checking newly compiled version..."
NEW_VERSION=$(grep -oP '#define VERSION "\K[^"]+' out/compile_time.h)
echo "Newly Compiled Version: $NEW_VERSION"

# --- VERSION COMPARISON ---
if [ "$CURRENT_VERSION" == "$NEW_VERSION" ] && [ -n "$CURRENT_VERSION" ]; then
    echo "✅ The MCU is already running the latest version ($NEW_VERSION)."
    echo "⏭️ Skipping flash process to preserve flash memory."
else
    echo "💾 Version mismatch detected! Flashing new firmware to the MCU..."
    ./scripts/flash-sdcard.sh "$MCU_PATH" "$BOARD_TYPE"
fi

echo "🚀 Starting ${KLIPPER_SERVICE} service..."
sudo systemctl start "$KLIPPER_SERVICE"

echo "✅ Script finished successfully!"