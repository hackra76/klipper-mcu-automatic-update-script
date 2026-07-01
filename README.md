
***

# 🚀 Klipper MCU Automatic Update Script

An automated, "one-click" solution to compile and flash Klipper firmware to microcontrollers using the **SD Card flashing method**. Optimized for the **BTT SKR V1.4 Turbo** and other LPC176x/ARM-based boards.

This script is designed to run as a **detached background service**. This ensures that the update process survives when the Klipper service is stopped for flashing, preventing UI crashes and connection freezes.

---

## 🌟 Key Features

*   **💾 Smart Version Tracking:** Compares the Git hash of your last successful flash against the current Klipper version. It only flashes when an update is actually available, saving your MCU's flash memory.
*   **🔔 Real-Time Notifications:** Sends progress alerts (*"Compiling..."*, *"Flashing..."*, *"Success!"*) directly to your Mainsail/Fluidd dashboard as pop-up notifications.
*   **🛡️ Crash-Proof Execution:** Runs as a Systemd service. This allows the script to safely stop Klipper, flash the MCU, and restart Klipper without the script being interrupted.
*   **🛠️ One-Command Setup:** Includes a `setup.sh` that automates the installation of the G-code shell extension, system services, and sudo permissions.
*   **🧹 Automatic Cleanup:** Automatically stashes local changes to handle "-dirty" Klipper environments, ensuring `git pull` never fails.

---

## ⚠️ Prerequisites

Before running the automated update for the first time, you **must** have a valid Klipper configuration file:
1.  SSH into your Raspberry Pi.
2.  Run: `cd ~/klipper && make menuconfig`.
3.  Configure the settings for your board (e.g., **LPC176x (LPC1769)** for SKR 1.4 Turbo).
4.  **Save and Exit.**

---

## ⚙️ Installation & Setup

### 1. Download and Run Setup
Run these commands in your terminal to clone the repository and automate the system configuration:

```bash
cd ~
git clone https://github.com/hackra76/klipper-mcu-automatic-update-script.git
cd klipper-mcu-automatic-update-script
bash setup.sh
```

### 2. Configure `update-mcu.sh`
Open the script to set your specific hardware paths:
```bash
nano update-mcu.sh
```
Update these two variables:
*   `MCU_PATH`: Your unique ID (find it with `ls /dev/serial/by-id/`).
*   `BOARD_TYPE`: Your board model (e.g., `btt-skr-turbo-v1.4`).

### 3. Reboot
**You must reboot your Pi** after running the setup for the Klipper extensions and system permissions to take effect:
```bash
sudo reboot
```

---

## 🖥️ Web Interface Configuration

Add the following to your `printer.cfg` (or a separate `shell_command.cfg`) to create the update macro:

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

---

## 🚀 Usage

1.  Open **Mainsail** or **Fluidd**.
2.  Click the **UPDATE_MCU_FIRMWARE** macro button.
3.  Monitor the dashboard for notifications:
    *   If up to date: *"MCU is already up to date. Flash skipped."*
    *   If updates exist: *"Compiling..."* ➡️ *"Flashing..."* ➡️ *"Success!"*
4.  Once you see the success message, run a **FIRMWARE_RESTART** to reconnect.

---

## 🔍 Troubleshooting
If the update does not seem to progress, you can check the background logs:
```bash
cat ~/printer_data/logs/mcu_update.log
```

---

## 🛑 Disclaimer
**Use at your own risk.** This script interacts directly with hardware and firmware. The author is not responsible for any bricked boards, hardware damage, or failed prints. Always verify your `make menuconfig` settings before flashing.

---

## 📝 License
This project is open-source and available under the [MIT License](LICENSE).
