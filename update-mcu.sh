#!/bin/bash

# --- USER CONFIGURATION ---
MCU_PATH="/dev/serial/by-id/usb-Klipper_lpc1769_12345-if00"
BOARD_TYPE="btt-skr-turbo-v1.4"
KLIPPER_DIR="${HOME}/klipper"
KLIPPER_SERVICE="klipper"

# Simple colors for Mainsail console
YELLOW='\e[1;33m'
GREEN='\e[1;32m'
RED='\e[1;31m'
NC='\e[0m'
# --------------------------

echo -e "${YELLOW}▶ Starting MCU Update Process...${NC}"

cd "$KLIPPER_DIR" || exit

# 1. FLASH-SAVER: Check if an update is actually needed
echo -e "${YELLOW}🔍 Checking for Klipper updates on GitHub...${NC}"
git fetch

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse @{u})

if [ "$LOCAL" == "$REMOTE" ]; then
    echo -e "${GREEN}✅ Klipper source is already current. Skipping build to save MCU flash.${NC}"
    exit 0
fi

echo -e "${YELLOW}🆕 New version found. Updating source...${NC}"
git pull

# 2. FREE THE PORT: Stop Klipper so flash-sdcard.sh can connect
echo -e "${YELLOW}🛑 Stopping Klipper service to release serial port...${NC}"
sudo systemctl stop "$KLIPPER_SERVICE"

# 3. BUILD
echo -e "${YELLOW}⚙️ Compiling firmware...${NC}"
make clean
make -j$(nproc)

if [ ! -f "out/klipper.bin" ]; then
    echo -e "${RED}❌ Error: Compilation failed!${NC}"
    sudo systemctl start "$KLIPPER_SERVICE"
    exit 1
fi

# 4. FLASH
echo -e "${YELLOW}⚡ Flashing $BOARD_TYPE via $MCU_PATH...${NC}"
if ./scripts/flash-sdcard.sh "$MCU_PATH" "$BOARD_TYPE"; then
    echo -e "${GREEN}🎉 SUCCESS: MCU flashed successfully!${NC}"
else
    echo -e "${RED}❌ Error: Flashing failed! Check if MCU is powered.${NC}"
    sudo systemctl start "$KLIPPER_SERVICE"
    exit 1
fi

# 5. RESTART
echo -e "${YELLOW}🚀 Restarting Klipper service...${NC}"
sudo systemctl start "$KLIPPER_SERVICE"
echo -e "${GREEN}🏁 Update Complete! Please run FIRMWARE_RESTART in Mainsail.${NC}"