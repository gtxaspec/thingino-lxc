#!/bin/bash

CONFIG_FILE="$HOME/.config/additional-tools.cfg"

# Check if tools are already installed
if [ -f "$CONFIG_FILE" ]; then
    echo "Additional tools are already installed."
    echo "If you want to reinstall, remove the file: $CONFIG_FILE"
    exit 0
fi

echo -e "\e[38;5;208m  \\\   \e[38;5;231m_______ _     _ \e[38;5;208m_____ __   _  ______ \e[38;5;231m_____ __   _  _____"
echo -e "\e[38;5;208m  )\\\  \e[38;5;231m   |    |_____| \e[38;5;208m  |   | \  | |  ____ \e[38;5;231m  |   | \  | |     |"
echo -e "\e[38;5;208m (  /  \e[38;5;231m  |    |     | \e[38;5;208m__|__ |  \_| |_____| \e[38;5;231m__|__ |  \_| |_____|"
echo -e "\e[38;5;208m / /\n"
echo "ADDITIONAL TOOLS INSTALLATION SCRIPT"

echo -e "\e[0mCompiling: binwalk and installing associated dependencies... please wait."

sleep 5

mkdir additional-tools
cd additional-tools

sudo apt-get install -y --no-install-recommends --no-install-suggests libbz2-dev libssl-dev python3-dev python3-pip zlib1g-dev

git clone --depth 1 https://github.com/ReFirmLabs/binwalk binwalk
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
. $HOME/.cargo/env
sudo binwalk/dependencies/ubuntu.sh
cd binwalk
export PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH
cargo build --release
sudo cp target/release/binwalk /usr/local/bin/binwalk

# Create config directory if it doesn't exist and mark installation as complete
mkdir -p "$HOME/.config"
echo "Installation completed on $(date)" > "$CONFIG_FILE"

echo "Additional tools have been successfully installed. Enjoy!"
