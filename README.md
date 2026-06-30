***

# 🚀 Klipper MCU Automatic Update Script

An automated bash script to compile and flash Klipper firmware to microcontrollers (designed for BTT SKR V1.4 Turbo and similar) using the **SD Card flashing method**.

This script is specifically optimized to be triggered directly from the **Mainsail/Fluidd UI**, allowing for one-click firmware updates without ever opening a terminal.

---

## 🌟 Key Features

*   **💾 Flash-Saver Logic:** Compares your local Klipper version with the official GitHub repository. If no updates are found, the script exits immediately to avoid unnecessary wear on your MCU's flash memory.
*   **⚡ Fast Compilation:** Automatically detects and utilizes all available CPU cores (`make -j$(nproc)`).
*   **🛠️ UI Integration:** Designed to run via `gcode_shell_command` without hanging on password prompts.
*   **🛡️ Safety First:** Automatically stops the Klipper service to release the serial port for flashing and restarts it upon completion.
*   **🧹 Clean Builds:** Performs `make clean` to ensure no stale objects cause compilation errors.

---

## ⚙️ Installation & Setup

### 1. Clone the repository
SSH into your Raspberry Pi and run:
```bash
cd ~
git clone https://github.com/hackra76/klipper-mcu-automatic-update-script.git
cd klipper-mcu-automatic-update-script
chmod +x update-mcu.sh
```

### 2. Configure the Script
Open the script and update your specific MCU path and board type:
```bash
nano update-mcu.sh
```
Adjust the top block:
```bash
MCU_PATH="/dev/serial/by-id/usb-Klipper_lpc1769_...-if00"
BOARD_TYPE="btt-skr-turbo-v1.4"
```

### 3. Configure Sudo Permissions (Crucial for UI)
To allow Mainsail to stop/start the Klipper service without asking for a password, you must edit the `sudoers` file:
1. Run: `sudo visudo`
2. Scroll to the bottom and add this line (replace `pi` with your username if different):
   ```text
   pi ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop klipper, /usr/bin/systemctl start klipper
   ```
3. Save and exit (**Ctrl+O**, **Enter**, **Ctrl+X**).

---

## 🖥️ Mainsail / Moonraker Integration

### 1. Enable Shell Commands
Ensure you have the `gcode_shell_command` extension installed (e.g., via [KIAUH](https://github.com/dw-0/kiauh)).

### 2. Update `printer.cfg`
Add the following to your configuration to create the update button:

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

### 3. Update `moonraker.conf` (Optional - for Updates)
To see update notifications for this script in your dashboard:
```ini
[update_manager klipper-mcu-update]
type: git_repo
path: ~/klipper-mcu-automatic-update-script
origin: https://github.com/hackra76/klipper-mcu-automatic-update-script.git
managed_services: klipper
```

---

## 🚀 Usage

1.  Navigate to your Mainsail/Fluidd dashboard.
2.  Click the **UPDATE_MCU_FIRMWARE** macro button.
3.  Monitor the console:
    *   If Klipper is up to date, the script stops in seconds.
    *   If a new version exists, it will compile and flash automatically.
4.  Once finished, run `FIRMWARE_RESTART`.

---

## ⚠️ Prerequisites
Before running for the first time, you **must** have a valid `.config` file generated. 
```bash
cd ~/klipper
make menuconfig
# Select your board settings, Save and Exit.
```

---

## 🛑 Disclaimer
**Use at your own risk.** This script interacts directly with firmware and hardware. The author is not responsible for any damage, bricked boards, or failed prints. Always verify your `make menuconfig` settings before flashing.

---

## 📝 License
This project is open-source under the [MIT License](LICENSE). Feel free to adapt it for your printer.
