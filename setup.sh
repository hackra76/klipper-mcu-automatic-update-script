#!/bin/bash
USER=$(id -un)
USER_HOME=$(eval echo "~$USER")
SCRIPT_DIR="$USER_HOME/klipper-mcu-automatic-update-script"

echo "🛠️ Starting Professional Setup..."

# 1. Install Klipper G-Code Shell Command extension (The standard way)
echo "📦 Installing G-Code Shell Command extension..."
wget https://raw.githubusercontent.com/dw-0/kiauh/master/resources/gcode_shell_command.py -P "$USER_HOME/klipper/klippy/extras/"
echo "✅ Extension installed to Klipper."

# 2. Create a dedicated Systemd Service for the update
# This allows the update to keep running even when Klipper is stopped.
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

# 3. Setup Sudo Permissions
echo "🔓 Configuring sudo permissions..."
SUDO_FILE="/etc/sudoers.d/klipper_update_$USER"
sudo bash -c "cat <<EOF > $SUDO_FILE
$USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop klipper, /usr/bin/systemctl start klipper, /usr/bin/systemctl start klipper-mcu-update.service
EOF"
sudo chmod 0440 "$SUDO_FILE"

chmod +x "$SCRIPT_DIR/update-mcu.sh"
echo "✅ Setup finished. REBOOT your Pi now."
