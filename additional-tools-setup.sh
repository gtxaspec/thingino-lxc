#!/bin/bash

echo -e "\e[38;5;208m  \\\   \e[38;5;231m_______ _     _ \e[38;5;208m_____ __   _  ______ \e[38;5;231m_____ __   _  _____"
echo -e "\e[38;5;208m  )\\\  \e[38;5;231m   |    |_____| \e[38;5;208m  |   | \  | |  ____ \e[38;5;231m  |   | \  | |     |"
echo -e "\e[38;5;208m (  /  \e[38;5;231m  |    |     | \e[38;5;208m__|__ |  \_| |_____| \e[38;5;231m__|__ |  \_| |_____|"
echo -e "\e[38;5;208m / /\n"
echo "ADDITIONAL TOOLS INSTALLATION SCRIPT"

echo -e "\e[0mInstalling: binwalk, pipx, sasquatch, jefferson, and associated dependencies... please wait."

sleep 5

mkdir additional-tools
cd additional-tools

sudo apt-get install -y --no-install-recommends --no-install-suggests binwalk pipx liblzma-dev liblzo2-dev zlib1g-dev

git clone https://github.com/devttys0/sasquatch
cd sasquatch && git pull origin pull/56/head && ./build.sh

pipx ensurepath

pipx install jefferson

echo "Additional tools have been successfully installed! Please log out and then log back in to start using them."
