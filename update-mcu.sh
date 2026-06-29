#!/bin/bash
set -e
# VLOŽ SEM SVOJU PRESNÚ CESTU K MCU
MCU_PATH="/dev/serial/by-id/usb-Klipper_lpc1769_12345-if00"
BOARD_TYPE="btt-skr-turbo-v1.4"

echo "🛑 Zastavujem Klipper..."
sudo systemctl stop klipper

echo "🧹 Čistím predchádzajúci build..."
cd ~/klipper
make clean

echo "⚙️ Kompilujem nový firmvér..."
# Pi Zero 2 W má 4 jadrá, parameter -j4 kompiláciu výrazne urýchli
make -j4

echo "💾 Flashujem firmvér na SD kartu v SKR 1.4..."
# Tento natívny Klipper skript robí to isté čo KIAUH
./scripts/flash-sdcard.sh $MCU_PATH $BOARD_TYPE

echo "🚀 Spúšťam Klipper..."
sudo systemctl start klipper

echo "✅ Aktualizácia MCU dokončená!"
