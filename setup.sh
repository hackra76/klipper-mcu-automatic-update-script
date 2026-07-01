#!/bin/bash

USER=$(id -un)
USER_HOME=$(eval echo "~$USER")
SCRIPT_DIR="$USER_HOME/klipper-mcu-automatic-update-script"
EXT_DEST="$USER_HOME/klipper/klippy/extras/gcode_shell_command.py"
SUDO_FILE="/etc/sudoers.d/klipper_update_$USER"

echo "🛠️ Starting Professional Setup for Klipper MCU Update..."

# 1. Install Klipper G-Code Shell Command extension (Inline method)
echo "📦 Installing G-Code Shell Command extension..."
cat << 'EOF' > "$EXT_DEST"
# G-code shell command - Universal & Multi-instance compatible
import os, subprocess, logging, shlex
class GCodeShellCommand:
    def __init__(self, config):
        self.printer = config.get_printer()
        self.gcode = self.printer.lookup_object('gcode')
        self.name = config.get_name().split()[1]
        self.command = config.get('command')
        self.timeout = config.getfloat('timeout', 2.0)
        self.verbose = config.getboolean('verbose', True)
        try:
            self.gcode.register_command('RUN_SHELL_COMMAND', self.cmd_RUN_SHELL_COMMAND)
        except Exception:
            pass
    def cmd_RUN_SHELL_COMMAND(self, gcmd):
        command = gcmd.get('CMD')
        if command != self.name: return
        try:
            process = subprocess.Popen(shlex.split(self.command), stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            output, _ = process.communicate(timeout=self.timeout)
            if self.verbose: self.gcode.respond_info(output.decode())
        except Exception as e:
            self.gcode.respond_info("Error: " + str(e))
def load_config_prefix(config):
    return GCodeShellCommand(config)
EOF
chmod 644 "$EXT_DEST"

# 2. Create Background System Service
echo "⚙️ Creating systemd service..."
sudo bash -c "cat <<EOF > /etc/systemd/system/klipper-mcu-update.service
[Unit]
Description=Klipper MCU Update Service
[Service]
Type=oneshot
User=$USER
ExecStart=/bin/bash $SCRIPT_DIR/update-mcu.sh
StandardOutput=append:$USER_HOME/printer_data/logs/mcu_update.log
StandardError=append:$USER_HOME/printer_data/logs/mcu_update.log
EOF"

# 3. Setup Sudoers (Passwordless service control)
echo "🔓 Configuring sudo permissions..."
sudo bash -c "cat <<EOF > $SUDO_FILE
$USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop klipper, /usr/bin/systemctl start klipper, /usr/bin/systemctl start --no-block klipper-mcu-update.service
EOF"
sudo chmod 0440 "$SUDO_FILE"

chmod +x "$SCRIPT_DIR/update-mcu.sh"

echo ""
echo "------------------------------------------------------"
echo "📄 ADD THIS TO YOUR printer.cfg:"
echo "------------------------------------------------------"
echo "[gcode_shell_command trigger_update]"
echo "command: sudo systemctl start --no-block klipper-mcu-update.service"
echo "timeout: 2.0"
echo "verbose: True"
echo ""
echo "[gcode_macro UPDATE_MCU_FIRMWARE]"
echo "gcode:"
echo '    RESPOND MSG="Starting background update service..."'
echo "    RUN_SHELL_COMMAND CMD=trigger_update"
echo "------------------------------------------------------"
echo "🏁 Setup finished. Please REBOOT your Pi."
