
***

# 🚀 Klipper MCU Automatic Update Script (Pro Edition)

An automated, background-managed solution to compile and flash Klipper firmware. This script is specifically designed to handle the **SD Card flashing method** (optimized for **BTT SKR V1.4 Turbo** and similar) directly from your web interface.

### 💎 Why this version?
Unlike standard scripts, this one runs as a **detached Systemd service**. This means it can safely stop the Klipper service, flash your hardware, and restart Klipper without the script itself being killed in the process.

---

## 🌟 Key Features

*   **⚡ Background Execution:** Runs as an independent system service to prevent UI crashes during the flash process.
*   **💾 Smart Version Tracking:** Compares the Git hash of your last successful flash against your current Pi version. It only flashes when an actual update is needed, saving your MCU's flash memory.
*   **🔔 Real-Time Popups:** Sends progress notifications (*"Compiling..."*, *"Flashing..."*, *"Success!"*) directly to your Mainsail/Fluidd dashboard.
*   **🧹 Dirty State Recovery:** Automatically handles `-dirty` Klipper versions by stashing local changes before updating.
*   **🛠️ One-Command Setup:** Includes a `setup.sh` that installs the necessary Klipper extensions and system services for you.

---

## ⚙️ Quick Installation

1.  **SSH** into your Raspberry Pi.
2.  **Clone and Run Setup**:
    ```bash
    cd ~
    git clone https://github.com/hackra76/klipper-mcu-automatic-update-script.git
    cd klipper-mcu-automatic-update-script
    bash setup.sh
    ```
3.  **Reboot your Pi** to apply the new system services and Klipper extensions.

---

## 🔧 Configuration

### 1. Script Settings
Open `update-mcu.sh` and set your unique hardware ID:
```bash
nano ~/klipper-mcu-automatic-update-script/update-mcu.sh
```
*   `MCU_PATH`: Find this by running `ls /dev/serial/by-id/`.
*   `BOARD_TYPE`: Set to your board (e.g., `btt-skr-turbo-v1.4`).

### 2. Printer G-Code (`printer.cfg`)
Add this to create your update button:
```gcode
[gcode_shell_command trigger_update]
command: sudo systemctl start klipper-mcu-update.service
timeout: 5.0
verbose: True

[gcode_macro UPDATE_MCU_FIRMWARE]
description: Detached MCU update (Safe from crashes)
gcode:
    RESPOND MSG="Starting background update service..."
    RUN_SHELL_COMMAND CMD=trigger_update
```

### 3. Update Manager (`moonraker.conf`)
Add this so you can update this script via your dashboard:
```ini
[update_manager klipper-mcu-update]
type: git_repo
path: ~/klipper-mcu-automatic-update-script
origin: https://github.com/hackra76/klipper-mcu-automatic-update-script.git
primary_branch: main
managed_services: klipper
```

---

## 🚀 Usage

1.  Click the **UPDATE_MCU_FIRMWARE** button in Mainsail/Fluidd.
2.  The script will check if your MCU is out of date.
3.  If an update is needed, Klipper will disconnect briefly while the background service flashes the board.
4.  Watch the console for the **"SUCCESS"** notification.
5.  Run `FIRMWARE_RESTART` once finished.

---

## 🛑 Disclaimer
**Use at your own risk.** Flashing firmware carries inherent risks. Ensure your `make menuconfig` is correctly configured for your board before running this script. The author is not responsible for any hardware damage.

---

## 📝 License
MIT License. Open-source and free to use.
