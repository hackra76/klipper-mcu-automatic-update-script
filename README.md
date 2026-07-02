
***

# 🚀 Klipper MCU Automatic Update Script

An automated, "one-click" solution to compile and flash Klipper firmware to microcontrollers. Optimized for the **BTT SKR V1.4 Turbo** (LPC1769) using the **SD Card flashing method**.

This script runs as a **detached background service**. This allows it to safely stop the Klipper service, flash the MCU, and restart Klipper without the script itself being killed when the connection is lost.

---

## 🌟 Key Features

*   **💾 Smart Version Tracking:** Tracks the Git hash of your last successful flash. It only updates if a new Klipper version is detected, saving your MCU's flash memory lifespan.
*   **📂 KIAUH Config Integration:** Automatically pulls your specific firmware settings from your KIAUH kconfigs folder (e.g., `tronxy.config`).
*   **🔔 Real-Time Notifications:** Sends progress alerts (*"Compiling..."*, *"Flashing..."*, *"Success!"*) directly to your Mainsail/Fluidd dashboard popups.
*   **🛡️ Crash-Proof Execution:** By running as a Systemd service, the flash process is never interrupted by Klipper shutting down.
*   **🧹 Dirty Repo Handling:** Automatically handles "-dirty" Klipper environments by stashing local changes before updating, ensuring `git pull` never fails.

---

## ⚠️ Prerequisites

Before running the automated update for the first time, ensure you have a saved configuration in KIAUH or Klipper:
1.  Verify your config file exists (e.g., `~/klipper-kconfigs/tronxy.config`).
2.  If you don't use KIAUH configs, ensure `~/klipper/.config` is correctly set for your **LPC1769** architecture.

---

## ⚙️ Installation & Setup

### 1. Download and Run Setup
Run these commands in your SSH terminal to clone the repository and automate the system configuration:

```bash
cd ~
git clone https://github.com/hackra76/klipper-mcu-automatic-update-script.git
cd klipper-mcu-automatic-update-script
bash setup.sh
```

### 2. Configure the Script
Open the script to set your specific hardware paths:
```bash
nano update-mcu.sh
```
Update these three variables at the top of the file:
*   `MCU_PATH`: Your unique ID (e.g., `/dev/serial/by-id/usb-Klipper_lpc1769_...`).
*   `BOARD_TYPE`: Your board model (e.g., `btt-skr-turbo-v1.4`).
*   `CONFIG_SOURCE`: The path to your KIAUH config (e.g., `${HOME}/klipper-kconfigs/tronxy.config`).

### 3. Reboot
**You must reboot your Pi** after running the setup for the Klipper extensions and system permissions to take effect:
```bash
sudo reboot
```

---

## 🖥️ Web Interface Configuration

### 1. Update `printer.cfg`
Add the following to your configuration to create the update macro:

```gcode
[gcode_shell_command trigger_update]
command: sudo systemctl start --no-block klipper-mcu-update.service
timeout: 2.0
verbose: True

[gcode_macro UPDATE_MCU_FIRMWARE]
description: Starts a safe background MCU update
gcode:
    RESPOND MSG="Starting background update service..."
    RUN_SHELL_COMMAND CMD=trigger_update
```

### 2. Update `moonraker.conf` (Optional)
To receive update notifications for this script itself in your dashboard:

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

1.  Open **Mainsail** or **Fluidd**.
2.  Click the **UPDATE_MCU_FIRMWARE** macro button.
3.  Monitor the console/dashboard for notifications:
    *   **Up to date:** *"MCU is already up to date. Flash skipped."*
    *   **New Version:** *"Compiling..."* ➡️ *"Flashing..."* ➡️ *"Success!"*
4.  Once the success message appears, run a **FIRMWARE_RESTART** to reconnect.

---

## 🔍 Troubleshooting
If the update fails or you don't see notifications, check the dedicated log file:
```bash
cat ~/printer_data/logs/mcu_update.log
```

---

## 🛑 Disclaimer
**Use at your own risk.** This script interacts directly with hardware and firmware. The author is not responsible for any bricked boards, hardware damage, or failed prints. Always verify your firmware settings before flashing.

---

## 📝 License
This project is open-source and available under the [MIT License](LICENSE).
