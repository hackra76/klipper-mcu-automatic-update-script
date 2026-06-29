\# 🚀 Klipper MCU Automatic Update Script



A simple, fast, and automated bash script to compile and flash Klipper firmware to a \*\*BTT SKR V1.4 Turbo\*\* (or similar) microcontroller via a Raspberry Pi. 



Originally optimized for \*\*Raspberry Pi Zero 2 W\*\* (using 4 cores for faster compilation), but works flawlessly on any Raspberry Pi running Klipper.



\## 🌟 Features

\- \*\*Safe execution:\*\* Stops the Klipper service before doing anything.

\- \*\*Clean build:\*\* Removes old compiled files to prevent conflicts (`make clean`).

\- \*\*Fast compilation:\*\* Utilizes multiple CPU cores (`make -j4`) for rapid building.

\- \*\*Native flashing:\*\* Uses Klipper's official `flash-sdcard.sh` script to flash the board directly without removing the SD card.

\- \*\*Auto-restart:\*\* Starts the Klipper service back up once the update is complete.



\## ⚠️ Prerequisites

Before running this script for the first time, you \*\*must\*\* generate a `.config` file for your specific microcontroller.



1\. SSH into your Raspberry Pi.

2\. Navigate to the Klipper directory:

&#x20;  ```bash

&#x20;  cd \~/klipper



Open the configuration menu:



Bash

make menuconfig

Set the correct architecture and parameters for your board (e.g., lpc1769 for BTT SKR V1.4 Turbo). Save and exit.



⚙️ Installation \& Configuration

Clone the repository:



Bash

cd \~

git clone \[https://github.com/hackra76/klipper-mcu-automatic-update-script.git](https://github.com/hackra76/klipper-mcu-automatic-update-script.git)

cd klipper-mcu-automatic-update-script

Make the script executable:



Bash

chmod +x update-mcu.sh

Edit the MCU Path:

Open update-mcu.sh in your favorite text editor (like nano) and update the MCU\_PATH variable to match your specific board's serial ID.



To find your MCU path, run:



Bash

ls /dev/serial/by-id/

Then replace this line in the script:



Bash

MCU\_PATH="/dev/serial/by-id/usb-Klipper\_lpc1769\_12345-if00" # <-- CHANGE THIS

🚀 Usage

Whenever Klipper releases an update and you need to recompile the firmware for your MCU, simply run:



Bash

./update-mcu.sh

Sit back and watch the script handle the stopping, cleaning, compiling, flashing, and restarting automatically!



📝 License

This project is open-source and available under the MIT License. Feel free to modify and adapt it to your specific 3D printer setup.

