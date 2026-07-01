
***

# 🚀 Klipper MCU Automatic Update Script

An automated, "one-click" solution to compile and flash Klipper firmware to microcontrollers using the **SD Card flashing method** (optimized for **BTT SKR V1.4 Turbo** and similar boards).

This script allows you to manage firmware updates directly from your **Mainsail/Fluidd** dashboard with real-time status popups, ensuring your MCU stays in sync with your Klipper Host without ever needing to open an SSH terminal.

---

## 🌟 Key Features

*   **💾 Smart Flash-Saver:** Tracks the last successfully flashed Git hash in a local state file. If your Klipper version hasn't changed, the script exits in seconds to protect your MCU's flash memory.
*   **🔔 UI Notifications:** Sends real-time progress alerts (e.g., *"Compiling..."*, *"Flashing..."*, *"Success!"*) directly to your web interface using Klipper's `RESPOND` system.
*   **🛡️ Moonraker Managed:** Executed via Moonraker's `shell_command` system. This allows the script to safely stop the Klipper service, flash the board, and restart Klipper without the script itself being killed.
*   **🛠️ Automated Setup:** Includes a `setup.sh` script that configures necessary system permissions and generates your configuration blocks.
*   **🧹 Dirty Repo Handling:** Automatically stashes local Klipper changes to ensure `git pull` works even if your environment is marked as "dirty."

---

## ⚠️ Prerequisites

Before running the automated update for the first time, you **must** have a valid Klipper configuration file:
1.  SSH into your Raspberry Pi.
2.  Navigate to Klipper: `cd ~/klipper`
3.  Run: `make menuconfig`
4.  Configure the settings for your specific board (e.g., LPC1769 for SKR 1.4 Turbo).
5.  **Save and Exit.**

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
Update these variables at the top:
*   `MCU_PATH`: Your unique ID (find it with `ls /dev/serial/by-id/`).
*   `BOARD_TYPE`: Your board model (e.g., `btt-skr-turbo-v1.4`).

---

## 🖥️ Web Interface Configuration

### 1. Update `moonraker.conf`
Add the following to allow Moonraker to manage the script and provide updates:

```ini
[update_manager klipper-mcu-update]
type: git_repo
path: ~/klipper-mcu-automatic-update-script
origin: https://github.com/hackra76/klipper-mcu-automatic-update-script.git
primary_branch: main
managed_services: klipper

[shell_command update_mcu]
command: bash /home/pi/klipper-mcu-automatic-update-script/update-mcu.sh
timeout: 600
verbose: True
```

### 2. Update `printer.cfg`
Add this macro to create the update button in your dashboard:

```gcode
[gcode_macro UPDATE_MCU_FIRMWARE]
description: Safely flashes the MCU via Moonraker
gcode:
    {action_call_remote_method("run_shell_command", command="update_mcu")}
```

---

## 🚀 Usage

1.  Open **Mainsail** or **Fluidd**.
2.  Locate the **UPDATE_MCU_FIRMWARE** macro in your dashboard.
3.  Click the button and watch for notifications:
    *   **Up to date:** You'll see *"MCU is already up to date."*
    *   **New Version:** You'll see popups for *"Compiling..."* ➡️ *"Flashing..."* ➡️ *"Success!"*
4.  Once finished, run a **FIRMWARE_RESTART** to reconnect the MCU.

---

## 🛑 Disclaimer
**Use at your own risk.** This script interacts directly with hardware and firmware. The author is not responsible for any bricked boards, hardware damage, or failed prints. Always verify your `make menuconfig` settings before flashing.

---

## 📝 License
This project is open-source and available under the [MIT License](LICENSE). Feel free to adapt it for your specific 3D printer setup.