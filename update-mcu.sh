#!/bin/bash

# --- USER CONFIGURATION ---
MCU_PATH="/dev/serial/by-id/usb-Klipper_lpc1769_12345-if00"
BOARD_TYPE="btt-skr-turbo-v1.4"
KLIPPER_DIR="${HOME}/klipper"

# Colors for better visibility in Klipper Console
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
# --------------------------

echo -e "${YELLOW}▶ Starting Klipper MCU Update...${NC}"

# 1. Pre-Flight Checks
if [ ! -d "$KLIPPER_DIR" ]; then
    echo -e "${RED}❌ Error: Klipper directory not found at $KLIPPER_DIR${NC}"
    exit 1
fi

if [ ! -f "$KLIPPER_DIR/.config" ]; then
    echo -e "${RED}❌ Error: No .config file found! Run 'make menuconfig' first.${NC}"
    exit 1
fi

if [ ! -e "$MCU_PATH" ]; then
    echo -e "${RED}❌ Error: MCU not found at $MCU_PATH${NC}"
    echo -e "${YELLOW}Is the printer turned on and connected?${NC}"
    exit 1
fi

# 2. Update Source
cd "$KLIPPER_DIR" || exit
echo -e "${YELLOW}⬇️ Pulling latest Klipper source...${NC}"
git pull

# Display Version
VERSION=$(git describe --always --tags --long)
echo -e "${GREEN}📦 Building Klipper Version: $VERSION${NC}"

# 3. Clean and Compile
echo -e "${YELLOW}⚙️ Cleaning and Compiling...${NC}"
make clean
make -j$(nproc)

# 4. Verify Build Result
if [ -f "out/klipper.bin" ]; then
    echo -e "${GREEN}✅ Compilation successful!${NC}"
else
    echo -e "${RED}❌ Error: Compilation failed. klipper.bin not found.${NC}"
    exit 1
fi

# 5. Flash via SD Card
echo -e "${YELLOW}⚡ Flashing $BOARD_TYPE...${NC}"
if ./scripts/flash-sdcard.sh "$MCU_PATH" "$BOARD_TYPE"; then
    echo -e "${GREEN}🎉 SUCCESS: MCU flashed and rebooted!${NC}"
    echo -e "${YELLOW}ℹ️ Please run FIRMWARE_RESTART in your dashboard.${NC}"
else
    echo -e "${RED}❌ Error: Flashing failed! Check permissions or MCU state.${NC}"
    exit 1
fi