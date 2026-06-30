#!/bin/bash

# --- USER CONFIGURATION ---
MCU_PATH="/dev/serial/by-id/usb-Klipper_lpc1769_12345-if00" # Update this!
BOARD_TYPE="btt-skr-turbo-v1.4"
KLIPPER_DIR="${HOME}/klipper"
# --------------------------

# 1. Navigate to Klipper directory
cd "$KLIPPER_DIR" || { echo "❌ Error: Klipper directory not found!"; exit 1; }

# 2. Update Source
echo "⬇️ Pulling latest Klipper source..."
git pull

# 3. Clean and Compile
echo "⚙️ Cleaning old build files..."
make clean

echo "🛠️ Compiling firmware (using all CPU cores)..."
make -j$(nproc)

# 4. Verify the build
if [ -f "out/klipper.bin" ]; then
    echo "✅ Compilation successful! Found out/klipper.bin"
else
    echo "❌ Error: Compilation failed. 'out/klipper.bin' was not created."
    exit 1
fi

# 5. Flash the MCU via SD Card method
echo "⚡ Flashing MCU: $BOARD_TYPE via $MCU_PATH..."
./scripts/flash-sdcard.sh "$MCU_PATH" "$BOARD_TYPE"

# 6. Final Check
if [ $? -eq 0 ]; then
    echo "🎉 Flashing completed successfully!"
    echo "🏁 You may need to 'FIRMWARE_RESTART' in Klipper now."
else
    echo "❌ Error: Flashing failed!"
    exit 1
fi