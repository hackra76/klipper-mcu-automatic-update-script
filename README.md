
***

# 🚀 Klipper MCU Automatic Update Script

An automated solution to compile and flash Klipper firmware to microcontrollers (optimized for **BTT SKR V1.4 Turbo** and similar) using the **SD Card flashing method**.

This version is designed for a "one-click" experience. Once installed, you can update your printer's firmware directly from the **Mainsail/Fluidd dashboard** and receive real-time status notifications.

---

## 🌟 Key Features

*   **💾 Flash-Saver Technology:** Before compiling, the script compares your local Git hash with the official Klipper repository. If no updates are found, it stops immediately to save your MCU's flash memory cycles.
*   **🔔 UI Notifications:** Sends real-time status updates (e.g., "Compiling...", "Flashing...", "Success!") back to the Klipper console as pop-up notifications.
*   **🛠️ One-Command Setup:** Includes a `setup.sh` script that automates sudo permissions and prepares your environment.
*   **⚡ Optimized Build:** Automatically detects CPU cores to compile firmware as fast as possible.
*   **🛡️ Seamless Service Handling:** Automatically stops the Klipper service to release the serial port for flashing and restarts it when finished, all without requiring a password.

---

## ⚠️ Prerequisites

Before using this script, you must have generated your initial configuration:
1.  SSH into your Pi.
2.  `cd ~/klipper`
3.  `make menuconfig` (Set your board architecture, e.g., LPC1769 for SKR 1.4 Turbo).
4.  **Save and Exit.**

---

## ⚙️ Quick Installation

Run these commands in your SSH terminal to clone the repo and run the automated setup:

```bash
cd ~
git clone https://github.com/hackra76/klipper-mcu-automatic-update-script.git
cd klipper-mcu-automatic-update-script
bash setup.sh
```

### What the `setup.sh` does:
1.  **Sets Permissions:** Configures a secure, passwordless sudo rule specifically for starting/stopping the Klipper service.
2.  **Prepares Scripts:** Makes the update script executable.
3.  **Generates Config:** Prints the exact G-code block you need to copy into your `printer.cfg`.

---

## 🔧 Configuration

### 1. Script Configuration
Open `update-mcu.sh` to set your specific hardware path:
```bash
nano ~/klipper-mcu-automatic-update-script/update-mcu.sh
```
Update these two lines:
*   `MCU_PATH`: Your unique ID from `ls /dev/serial/by-id/`.
*   `BOARD_TYPE`: Your board model (e.g., `btt-skr-turbo-v1.4`).

### 2. Klipper Configuration
Add the following to your `printer.cfg` (The `setup.sh` will have printed this for you as well):

```gcode
[gcode_shell_command update_mcu]
command: /home/pi/klipper-mcu-automatic-update-script/update-mcu.sh
timeout: 600.0
verbose: True

[gcode_macro UPDATE_MCU_FIRMWARE]
description: Compiles and flashes the MCU if an update is available.
gcode:
    RUN_SHELL_COMMAND CMD=update_mcu
```

---

## 🚀 Usage

Simply click the **UPDATE_MCU_FIRMWARE** button in your Mainsail/Fluidd macro list.

*   **If Up to Date:** You will see a green notification: *"MCU is already up to date."*
*   **If Updates Exist:** You will see status updates: *"Compiling..."* ➡️ *"Flashing..."* ➡️ *"Success!"*

Once the script finishes, run a **FIRMWARE_RESTART** to reconnect.

---

## 🛑 Disclaimer
**Use at your own risk.** This script interacts directly with your 3D printer's hardware and firmware. The author is not responsible for any bricked boards, damaged hardware, or failed prints. Always double-check your `make menuconfig` settings before flashing.

---

## 📝 License
This project is open-source and available under the [MIT License](LICENSE). Feel free to adapt it to your specific setup!
