#!/bin/bash
USER_NAME="rado"
USER_HOME="/home/$USER_NAME"
SCRIPT_DIR="$USER_HOME/klipper-mcu-automatic-update-script"
SUDO_FILE="/etc/sudoers.d/klipper_update_$USER_NAME"

echo "🛠️ Performing System Setup..."

# 1. Install Klipper extension
cat << 'EOF' > "$USER_HOME/klipper/klippy/extras/gcode_shell_command.py"
import os, subprocess, logging, shlex
class GCodeShellCommand:
    def __init__(self, config):
        self.printer = config.get_printer()
        self.gcode = self.printer.lookup_object('gcode')
        self.name = config.get_name().split()[1]
        self.command = config.get('command')
        self.timeout = config.getfloat('timeout', 2.0)
        self.verbose = config.getboolean('verbose', True)
        try: self.gcode.register_command('RUN_SHELL_COMMAND', self.cmd_RUN_SHELL_COMMAND)
        except Exception: pass
    def cmd_RUN_SHELL_COMMAND(self, gcmd):
        command = gcmd.get('CMD')
        if command != self.name: return
        try:
            process = subprocess.Popen(shlex.split(self.command), stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            output, _ = process.communicate(timeout=self.timeout)
            if self.verbose: self.gcode.respond_info(output.decode())
        except Exception as e: self.gcode.respond_info("Error: " + str(e))
def load_config_prefix(config): return GCodeShellCommand(config)
EOF

# 2. Background Service
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

# 3. Sudoers (Bulletproof)
sudo bash -c "cat <<EOF > $SUDO_FILE
$USER_NAME ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop klipper, /usr/bin/systemctl start klipper, /usr/bin/systemctl start --no-block klipper-mcu-update.service
EOF"
sudo chmod 0440 "$SUDO_FILE"

# 4. Permissions
sudo chown $USER_NAME:$USER_NAME "$USER_HOME/printer_data/logs/mcu_update.log" 2>/dev/null
chmod +x "$SCRIPT_DIR/update-mcu.sh"

sudo systemctl daemon-reload
echo "✅ Setup finished. REBOOT now."
