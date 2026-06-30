#!/bin/bash

# Get current username and home directory
USER=$(id -un)
USER_HOME=$(eval echo "~$USER")
SUDO_FILE="/etc/sudoers.d/klipper_update_$USER"

echo "🛠️ Starting Setup for Klipper MCU Update Script..."

# 1. Setup Sudo Permissions (Safe method using /etc/sudoers.d/)
echo "🔓 Configuring sudo permissions..."
sudo bash -c "cat <<EOF > $SUDO_FILE
$USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop klipper, /usr/bin/systemctl start klipper
EOF"
sudo chmod 0440 "$SUDO_FILE"
echo "✅ Sudoers file created at $SUDO_FILE"

# 2. Make update script executable
chmod +x "$USER_HOME/klipper-mcu-automatic-update-script/update-mcu.sh"
echo "✅ Script made executable."

# 3. Output the G-Code block for the user
echo ""
echo "------------------------------------------------------"
echo "📋 COPY AND PASTE THIS INTO YOUR printer.cfg:"
echo "------------------------------------------------------"
cat <<EOF
[gcode_shell_command update_mcu]
command: $USER_HOME/klipper-mcu-automatic-update-script/update-mcu.sh
timeout: 600.0
verbose: True

[gcode_macro UPDATE_MCU_FIRMWARE]
description: Compiles and flashes the MCU if an update is available.
gcode:
    RUN_SHELL_COMMAND CMD=update_mcu
------------------------------------------------------
EOF
echo "✅ Setup complete!"
