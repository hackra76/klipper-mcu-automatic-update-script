#!/bin/bash
USER_NAME="rado"
USER_HOME="/home/$USER_NAME"
SCRIPT_DIR="$USER_HOME/klipper-mcu-automatic-update-script"
SUDO_FILE="/etc/sudoers.d/klipper_update_$USER_NAME"

echo "Starting Setup..."

# 1. Create/Overwrite Service with absolute paths
sudo bash -c "cat <<EOF > /etc/systemd/system/klipper-mcu-update.service
[Unit]
Description=Klipper MCU Update Service
After=network.target

[Service]
Type=oneshot
User=$USER_NAME
WorkingDirectory=$USER_HOME/klipper
ExecStart=/bin/bash $SCRIPT_DIR/update-mcu.sh
EOF"

# 2. Update Sudoers
sudo bash -c "cat <<EOF > $SUDO_FILE
$USER_NAME ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop klipper, /usr/bin/systemctl start klipper, /usr/bin/systemctl start --no-block klipper-mcu-update.service
EOF"
sudo chmod 0440 "$SUDO_FILE"

chmod +x "$SCRIPT_DIR/update-mcu.sh"
echo "Setup finished. Please reboot your Pi."
