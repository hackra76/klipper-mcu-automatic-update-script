# 🚀 Klipper MCU Automatic Update Script

A simple, fast, and automated bash script to compile and flash Klipper firmware to a **BTT SKR V1.4 Turbo** (or similar) microcontroller via a Raspberry Pi.

Designed to be universal, this script automatically detects your CPU cores for maximum compilation speed and pulls the latest Klipper updates before building.

---

## 🌟 Features

*   **Auto-Update:** Runs `git pull` to ensure you are compiling the freshest Klipper source.
*   **Safety First:** Verifies your `.config` file exists and stops the Klipper service before proceeding.
*   **Clean Build:** Removes old compiled files to prevent conflicts (`make clean`).
*   **Fast Compilation:** Utilizes multiple CPU cores (`make -j$(nproc)`) for rapid building.
*   **Native Flashing:** Uses Klipper's official `flash-sdcard.sh` script to flash the board directly.

---

## ⚠️ Prerequisites

> [!IMPORTANT]  
> Before running this script for the first time, you **must** generate a `.config` file for your specific microcontroller.

1.  **SSH** into your Raspberry Pi.
2.  **Navigate** to your Klipper directory:
    ```bash
    cd ~/klipper
    ```
3.  **Open** the configuration menu:
    ```bash
    make menuconfig
    ```
4.  **Set the correct architecture** and parameters for your board (e.g., `lpc1769` for BTT SKR V1.4 Turbo). 
5.  **Save and exit.**

---

## ⚙️ Installation & Configuration

### 1. Clone the repository
```bash
cd ~
git clone https://github.com/hackra76/klipper-mcu-automatic-update-script.git
cd klipper-mcu-automatic-update-script
```

### 2. Make the script executable
```bash
chmod +x update-mcu.sh
```

### 3. Configure your specific paths
Open `update-mcu.sh` in a text editor (like `nano`) and adjust the **USER CONFIGURATION** block at the very top of the file:

```bash
# --- USER CONFIGURATION ---
MCU_PATH="/dev/serial/by-id/usb-Klipper_lpc1769_12345-if00" # UPDATE THIS
BOARD_TYPE="btt-skr-turbo-v1.4"                             # UPDATE THIS IF NEEDED
KLIPPER_DIR="${HOME}/klipper"                               # Change if you use a different path
KLIPPER_SERVICE="klipper"                                   # Change if you run multiple instances
# --------------------------
```

> [!TIP]
> To find your exact MCU path, run `ls /dev/serial/by-id/` in your terminal.

---

## 🚀 Usage

Whenever Klipper releases an update and you need to recompile the firmware for your MCU, simply run:

```bash
./update-mcu.sh
```

Sit back and watch the script handle the stopping, updating, cleaning, compiling, flashing, and restarting automatically!

---

## 🛑 Disclaimer

> [!WARNING]  
> **Use at your own risk.** This script interacts directly with your 3D printer's hardware and firmware. While it has been written to be as safe and universal as possible, the author is not responsible for any bricked boards, damaged hardware, failed prints, or other issues that may arise from using this software. Always double-check your `.config` settings before flashing.

---

## 📝 License

This project is open-source and available under the [MIT License](LICENSE). Feel free to modify and adapt it to your specific 3D printer setup."}
