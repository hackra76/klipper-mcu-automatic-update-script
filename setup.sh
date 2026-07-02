#!/bin/bash
USER=$(id -un)
USER_HOME="/home/$USER"
SCRIPT_DIR="$USER_HOME/klipper-mcu-automatic-update-script"
SUDO_FILE="/etc/sudoers.d/klipper_update_$USER"

# Install background service
sudo bash -c "cat <<EOF > /etc/systemd/system/klipper-mcu-update.service
[Unit]
Description=Klipper MCU Update Service
After=network.target

[Service]
Type=oneshot
User=$USER
WorkingDirectory=$SCRIPT_DIR
ExecStart=/bin/bash $SCRIPT_DIR/update-mcu.sh
EOF"

# Update Sudo
sudo bash -c "cat <<EOF > $SUDO_FILE
$USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop klipper, /usr/bin/systemctl start klipper, /usr/bin/systemctl start --no-block klipper-mcu-update.service
EOF"
sudo chmod 0440 "$SUDO_FILE"

chmod +x "$SCRIPT_DIR/update-mcu.sh"
echo "✅ Setup finished. Reboot your Pi."
