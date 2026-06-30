# 🚀 Klipper MCU Automatic Update Script

A simple, fast, and automated bash script to compile and flash Klipper firmware to a **BTT SKR V1.4 Turbo** (or similar) microcontroller via a Raspberry Pi.

Designed to be universal, this script automatically detects your CPU cores for maximum compilation speed and pulls the latest Klipper updates before building.

## 🌟 Features

- **🧠 Smart Flashing:** Queries Moonraker for the currently running MCU firmware version and compares it to the newly compiled build. If they match, it skips flashing to preserve your board's flash memory!
- **🌐 Web UI Integration:** Easily trigger the update process directly from Mainsail or Fluidd.
- **🔄 Auto-Update:** Runs `git pull` to ensure you are compiling the freshest Klipper source.
- **🛡️ Safety First:** Verifies your `.config` file exists and stops the Klipper service before proceeding.
- **🧹 Clean Build:** Removes old compiled files to prevent conflicts (`make clean`).
- **⚡ Fast Compilation:** Utilizes multiple CPU cores (`make -j$(nproc)`) for rapid building.

## ⚠️ Prerequisites

Before running this script for the first time, you **must** generate a `.config` file for your specific microcontroller.

1. SSH into your Raspberry Pi.
2. Navigate to your Klipper directory:
   ```bash
   cd ~/klipper
   ```
3. Open the configuration menu:
   ```bash
   make menuconfig
   ```
4. Set the correct architecture and parameters for your board (e.g., `lpc1769` for BTT SKR V1.4 Turbo). Save and exit.

## ⚙️ Installation & Configuration (Command Line)

1. **Clone the repository:**
   ```bash
   cd ~
   git clone https://github.com/hackra76/klipper-mcu-automatic-update-script.git
   cd klipper-mcu-automatic-update-script
   ```

2. **Make the script executable:**
   ```bash
   chmod +x update-mcu.sh
   ```

3. **Configure your specific paths:**
   Open `update-mcu.sh` in a text editor (like `nano`) and adjust the `USER CONFIGURATION` block at the very top of the file:

   ```bash
   # --- USER CONFIGURATION ---
   MCU_PATH="/dev/serial/by-id/usb-Klipper_lpc1769_12345-if00" # UPDATE THIS
   BOARD_TYPE="btt-skr-turbo-v1.4"                             # UPDATE THIS IF NEEDED
   KLIPPER_DIR="${HOME}/klipper"                               # Change if you use a different path
   KLIPPER_SERVICE="klipper"                                   # Change if you run multiple instances
   MOONRAKER_URL="http://127.0.0.1:7125"                       # Default Moonraker API address
   # --------------------------
   ```

## 🖥️ Mainsail / Fluidd UI Integration

You can trigger this script directly from your web interface using a macro. 

**Requirements:** You must have the [G-Code Shell Command Extension](https://github.com/th33xitus/kiauh/blob/master/docs/gcode_shell_command.md) installed (easily done via KIAUH).

1. Open your `printer.cfg` (or `macros.cfg`) in the Mainsail/Fluidd web editor.
2. Add the following configuration block. **Make sure the `command:` path exactly matches where your script is located** (e.g., `/home/rado/update_mcu.sh`):

   ```ini
   [gcode_shell_command update_mcu]
   command: /home/rado/update_mcu.sh
   timeout: 300.0
   verbose: True

   [gcode_macro UPDATE_MCU_FIRMWARE]
   description: Triggers the automatic MCU firmware update script
   gcode:
       {action_respond_info("Starting MCU firmware update... Please wait.")}
       RUN_SHELL_COMMAND CMD=update_mcu
   ```
3. Click **SAVE & RESTART**.
4. You will now have a new macro button named `UPDATE_MCU_FIRMWARE` in your dashboard!

## 🚀 Usage

You can run the update in two ways:
1. Click the **UPDATE_MCU_FIRMWARE** button in Mainsail/Fluidd.
2. Or run it directly from the terminal: `./update-mcu.sh`

### ⚠️ The "Menuconfig" Trap
Klipper version strings are based on Git commit hashes. If you change your hardware settings using `make menuconfig` (e.g., changing stepper drivers), but Klipper hasn't released a new software update, the version string will not change. The script will assume everything is up-to-date and skip the flash. **If you manually change your `.config` settings, you must flash the board manually once.**

## 🛑 Disclaimer

**Use at your own risk.** This script interacts directly with your 3D printer's hardware and firmware. While it has been written to be as safe and universal as possible, the author is not responsible for any bricked boards, damaged hardware, failed prints, or other issues that may arise from using this software. Always double-check your `.config` settings before flashing.

## 📝 License

This project is open-source and available under the MIT License. Feel free to modify and adapt it to your specific 3D printer setup.
