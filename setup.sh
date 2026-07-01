#!/bin/bash
USER=$(id -un)
USER_HOME=$(eval echo "~$USER")
SCRIPT_DIR="$USER_HOME/klipper-mcu-automatic-update-script"
EXT_DEST="$USER_HOME/klipper/klippy/extras/gcode_shell_command.py"

echo "🛠️ Starting Professional Setup..."

# 1. Install Klipper G-Code Shell Command extension
echo "📦 Downloading G-Code Shell Command extension..."
# Using the verified th33xitus/kiauh master link
wget -q --show-progress https://raw.githubusercontent.com/th33xitus/kiauh/master/resources/gcode_shell_command.py -O "$EXT_DEST"

if [ -f "$EXT_DEST" ]; then
    echo "✅ Extension successfully installed to Klipper."
else
    echo "❌ ERROR: Download failed. Please check your internet connection and try again."
    exit 1
fi

# 2. Create a dedicated Systemd Service for the update
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
echo "✅ Setup finished. Please REBOOT your Pi now."
