#!/bin/bash

# Get current username and paths
USER=$(id -un)
USER_HOME=$(eval echo "~$USER")
SCRIPT_DIR="$USER_HOME/klipper-mcu-automatic-update-script"
EXT_DEST="$USER_HOME/klipper/klippy/extras/gcode_shell_command.py"
SUDO_FILE="/etc/sudoers.d/klipper_update_$USER"

echo "🛠️ Starting Professional Setup for Klipper MCU Update Script..."

# 1. Install Klipper G-Code Shell Command extension
# We use the "inline" method to avoid broken GitHub URLs.
# This version is Python 3 compatible and fixes the "already registered" error.
echo "📦 Installing G-Code Shell Command extension..."
cat << 'EOF' > "$EXT_DEST"
# G-code shell command - Universal & Multi-instance compatible
# Copyright (C) 2021  Eric Callahan <knueppel@gmx.net>
import os, subprocess, logging, shlex

class GCodeShellCommand:
    def __init__(self, config):
        self.printer = config.get_printer()
        self.gcode = self.printer.lookup_object('gcode')
        self.name = config.get_name().split()[1]
        self.command = config.get('command')
        self.timeout = config.getfloat('timeout', 2.0)
        self.verbose = config.getboolean('verbose', True)
        # Protection against duplicate registration
        try:
            self.gcode.register_command('RUN_SHELL_COMMAND', self.cmd_RUN_SHELL_COMMAND)
        except Exception:
            pass

    def cmd_RUN_SHELL_COMMAND(self, gcmd):
        command = gcmd.get('CMD')
        if command != self.name: return
        logging.info("gcode_shell_command: %s running: %s" % (self.name, self.command))
        try:
            process = subprocess.Popen(shlex.split(self.command), stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            output, _ = process.communicate(timeout=self.timeout)
            if self.verbose or process.poll() != 0:
                self.gcode.respond_info(output.decode())
        except Exception as e:
            self.gcode.respond_info("Error running command: %s\n%s" % (self.command, str(e)))

def load_config_prefix(config):
    return GCodeShellCommand(config)
EOF

chmod 644 "$EXT_DEST"
echo "✅ Extension successfully installed to Klipper."

# 2. Create Systemd Service for background updates
# This allows the script to stop Klipper without killing itself.
echo "⚙️ Creating background system service..."
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

# 3. Setup Sudo Permissions (no password required for updates)
echo "🔓 Configuring passwordless sudo permissions..."
sudo bash -c "cat <<EOF > $SUDO_FILE
$USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop klipper, /usr/bin/systemctl start klipper, /usr/bin/systemctl start --no-block klipper-mcu-update.service, /usr/bin/systemctl start klipper-mcu-update.service
EOF"
sudo chmod 0440 "$SUDO_FILE"

# 4. Make update script executable
chmod +x "$SCRIPT_DIR/update-mcu.sh"
echo "✅ Permissions set."

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
description: Starts a safe background MCU update
gcode:
    RESPOND MSG="Starting MCU update service..."
    RUN_SHELL_COMMAND CMD=trigger_update
------------------------------------------------------
EOF

echo ""
echo "🏁 Setup finished. Please update your configs and REBOOT your Pi (sudo reboot)."
