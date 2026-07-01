#!/bin/bash

# Get current username and home directory
USER=$(id -un)
USER_HOME=$(eval echo "~$USER")
SCRIPT_DIR="$USER_HOME/klipper-mcu-automatic-update-script"
SUDO_FILE="/etc/sudoers.d/klipper_update_$USER"

echo "🛠️ Starting Setup for Klipper MCU Update Script (Moonraker Edition)..."

# 1. Setup Sudo Permissions for service control
echo "🔓 Configuring passwordless sudo for Klipper service control..."
sudo bash -c "cat <<EOF > $SUDO_FILE
$USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop klipper, /usr/bin/systemctl start klipper
EOF"
sudo chmod 0440 "$SUDO_FILE"
echo "✅ Sudoers file created at $SUDO_FILE"

# 2. Make update script executable
if [ -f "$SCRIPT_DIR/update-mcu.sh" ]; then
    chmod +x "$SCRIPT_DIR/update-mcu.sh"
    echo "✅ Script made executable."
else
    echo "⚠️ Warning: update-mcu.sh not found in $SCRIPT_DIR"
fi

# 3. Output the Configuration Blocks
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

[shell_command update_mcu]
command: bash $SCRIPT_DIR/update-mcu.sh
timeout: 600
verbose: True
EOF

echo ""
echo "------------------------------------------------------"
echo "📄 2. ADD THIS TO YOUR printer.cfg (Remove old versions):"
echo "------------------------------------------------------"
cat <<EOF
[gcode_macro UPDATE_MCU_FIRMWARE]
description: Safely flashes the MCU via Moonraker
gcode:
    {action_call_remote_method("run_shell_command", command="update_mcu")}
------------------------------------------------------
EOF

echo ""
echo "✅ Setup script finished. Please update your configs and REBOOT your Pi."