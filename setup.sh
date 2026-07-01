#!/bin/bash

# Get current username and home directory
USER=$(id -un)
USER_HOME=$(eval echo "~$USER")
SCRIPT_DIR="$USER_HOME/klipper-mcu-automatic-update-script"
EXT_DEST="$USER_HOME/klipper/klippy/extras/gcode_shell_command.py"
SUDO_FILE="/etc/sudoers.d/klipper_update_$USER"

echo "🛠️ Starting Professional Setup for Klipper MCU Update..."

# 1. Install Klipper G-Code Shell Command extension
echo "📦 Downloading G-Code Shell Command extension..."
# Using the verified th33xitus/kiauh master link
wget -q --show-progress https://raw.githubusercontent.com/th33xitus/kiauh/master/resources/gcode_shell_command.py -O "$EXT_DEST"

if [ -f "$EXT_DEST" ]; then
    echo "✅ Extension successfully installed to Klipper."
else
    echo "❌ ERROR: Download failed. Please check your internet connection."
    exit 1
fi

# 2. Create the Systemd Service for the background update
# This allows the script to stop Klipper without being killed itself.
echo "⚙️ Creating Systemd service..."
sudo bash -c "cat <<EOF > /etc/systemd/system/klipper-mcu-update.service
[Unit]
Description=Klipper MCU Update Service
After=network.target

[Service]
Type=oneshot
User=$USER
ExecStart=/bin/bash $SCRIPT_DIR/update-mcu.sh
StandardOutput=append:$USER_HOME/printer_data/logs/mcu_update.log
StandardError=append:$USER_HOME/printer_data/logs/mcu_update.log

[Install]
WantedBy=multi-user.target
EOF"

# 3. Setup Sudo Permissions for service control
# We add the --no-block version to the allowed commands
echo "🔓 Configuring passwordless sudo for service control..."
sudo bash -c "cat <<EOF > $SUDO_FILE
$USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop klipper, /usr/bin/systemctl start klipper, /usr/bin/systemctl start --no-block klipper-mcu-update.service, /usr/bin/systemctl start klipper-mcu-update.service
EOF"
sudo chmod 0440 "$SUDO_FILE"
echo "✅ Sudoers file created."

# 4. Make update script executable
chmod +x "$SCRIPT_DIR/update-mcu.sh"
echo "✅ Script permissions set."

# 5. Output Configuration Instructions
echo ""
echo "------------------------------------------------------"
echo "📂 1. ADD THIS TO YOUR moonraker.conf:"
echo "------------------------------------------------------"
cat <<EOF
[update_manager klipper-mcu-update]
type: git_repo
path: ~/klipper-mcu-automatic-update-script
origin: https://github.com/hackra76/klipper-mcu-automatic-update-script.git
primary_branch: main
managed_services: klipper
EOF

echo ""
echo "------------------------------------------------------"
echo "📄 2. ADD THIS TO YOUR printer.cfg:"
echo "------------------------------------------------------"
cat <<EOF
[gcode_shell_command trigger_update]
command: sudo systemctl start --no-block klipper-mcu-update.service
timeout: 2.0
verbose: True

[gcode_macro UPDATE_MCU_FIRMWARE]
description: Detached MCU update (Safe from crashes)
gcode:
    RESPOND MSG="Starting background update service..."
    RUN_SHELL_COMMAND CMD=trigger_update
------------------------------------------------------
EOF

echo ""
echo "🏁 Setup finished. Please update your configs and REBOOT your Pi now."
