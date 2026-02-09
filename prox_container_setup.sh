#!/bin/bash

### This script is meant to run inside of a proxmox container

# Get the current logged-in user
USER_NAME=$(whoami)
VERSION=0.25
PACKAGES="apt-transport-https apt-utils bc bison build-essential ca-certificates ccache cmake cpio curl dialog \
file figlet flex gawk gcc git libncurses-dev lzop make mc nano patchelf \
qemu-user qemu-user-binfmt rsync software-properties-common ssh tftpd-hpa toilet \
toilet-fonts tree u-boot-tools unzip vim-tiny wget whiptail xterm"

# Ensure the script is not running as root
if [[ $(id -u) -eq 0 ]] && [[ -z "$SUDO_USER" ]]; then
	echo "This script must be run using a normal user via sudo, not as root."
	exit 1
fi

# Check if sudo is installed, and if not, switch to root and install sudo
if ! command -v sudo &> /dev/null; then
	echo "Sudo is not installed. Switching to root to install sudo..."
	su root -c "apt-get update && apt-get install -y sudo"

	# Add the current user to the sudo group
	echo "Adding $USER_NAME to the sudo group..."
	su root -c "usermod -aG sudo $USER_NAME"
	echo "Enabling passwordless sudo for $USER_NAME..."
	su root -c "bash -c 'echo \"$USER_NAME ALL=(ALL) NOPASSWD: ALL\" | tee /etc/sudoers.d/$USER_NAME'"

	echo "Please log out and log back in for the group changes to take effect."
	exit 1
fi

# Ensure the script is run using sudo, not as root
if [[ -z "$SUDO_USER" ]]; then
	echo "This script should be run using a normal user via sudo, not as root."
	exit 1
fi

# Function to install necessary packages
install_packages() {
	echo "Updating package lists..."
	apt-get update
	echo "Installing necessary packages..."
	apt-get install -y --no-install-recommends --no-install-suggests $PACKAGES
}

# Check if necessary commands are available and install missing packages
installation_needed=false
for cmd in git; do
	if ! command -v $cmd &> /dev/null; then
		echo "Required command '$cmd' is not installed."
		installation_needed=true
	fi
done

if [ "$installation_needed" = true ]; then
	read -p "Some necessary packages are not installed. Would you like to install them now? (y/n) " answer
	if [[ $answer =~ ^[Yy]$ ]]; then
		install_packages
		echo "Necessary packages have been installed."
	else
		echo "Installation aborted. Exiting."
		exit 1
	fi
fi

# Setup tftpd
sed -i 's/^TFTP_DIRECTORY="\/srv\/tftp"$/TFTP_DIRECTORY="\/home\/'$SUDO_USER'\/tftp"/' /etc/default/tftpd-hpa
sudo -u $SUDO_USER mkdir -p /home/$SUDO_USER/tftp

# Download additional tools script as the original user
sudo -u $SUDO_USER mkdir -p /home/$SUDO_USER/scripts
sudo -u $SUDO_USER wget https://raw.githubusercontent.com/gtxaspec/thingino-lxc/master/resource/additional-tools-setup.sh -P /home/$SUDO_USER/scripts/
sudo -u $SUDO_USER chmod +x /home/$SUDO_USER/scripts/additional-tools-setup.sh

# Download and extract the toolchains as the original user
sudo -u $SUDO_USER mkdir -p /home/$SUDO_USER/toolchain/
cd /home/$SUDO_USER/toolchain/
sudo -u $SUDO_USER wget https://github.com/themactep/thingino-firmware/releases/download/toolchain-x86_64/thingino-toolchain-x86_64_xburst1_musl_gcc14-linux-mipsel.tar.gz
sudo -u $SUDO_USER mkdir mipsel-xburst1-thingino-linux-musl_sdk-buildroot
sudo -u $SUDO_USER tar -xf thingino-toolchain-x86_64_xburst1_musl_gcc14-linux-mipsel.tar.gz -C mipsel-xburst1-thingino-linux-musl_sdk-buildroot --strip-components=1
cd /home/$SUDO_USER/toolchain/mipsel-xburst1-thingino-linux-musl_sdk-buildroot/
sudo -u $SUDO_USER ./relocate-sdk.sh
cd /home/$SUDO_USER/toolchain/
sudo -u $SUDO_USER wget https://github.com/themactep/thingino-firmware/releases/download/toolchain-x86_64/thingino-toolchain-x86_64_xburst2_musl_gcc14-linux-mipsel.tar.gz
sudo -u $SUDO_USER mkdir mipsel-xburst2-thingino-linux-musl_sdk-buildroot
sudo -u $SUDO_USER tar -xf thingino-toolchain-x86_64_xburst2_musl_gcc14-linux-mipsel.tar.gz -C mipsel-xburst2-thingino-linux-musl_sdk-buildroot --strip-components=1
cd /home/$SUDO_USER/toolchain/mipsel-xburst2-thingino-linux-musl_sdk-buildroot/
sudo -u $SUDO_USER ./relocate-sdk.sh

# Clone necessary repositories as the original user
sudo -u $SUDO_USER mkdir -p /home/$SUDO_USER/repo
sudo -u $SUDO_USER git clone --recurse-submodules --shallow-submodules https://github.com/themactep/thingino-firmware /home/$SUDO_USER/repo/thingino-firmware
sudo -u $SUDO_USER git clone https://github.com/gtxaspec/u-boot-ingenic /home/$SUDO_USER/repo/ingenic-u-boot-xburst1
sudo -u $SUDO_USER git clone https://github.com/gtxaspec/ingenic-u-boot-xburst2 -b t40 /home/$SUDO_USER/repo/ingenic-u-boot-xburst2-t40
sudo -u $SUDO_USER git clone https://github.com/gtxaspec/ingenic-u-boot-xburst2 -b t41 /home/$SUDO_USER/repo/ingenic-u-boot-xburst2-t41
sudo -u $SUDO_USER git clone https://github.com/themactep/ingenic-sdk /home/$SUDO_USER/repo/ingenic-sdk
sudo -u $SUDO_USER git clone https://github.com/gtxaspec/ingenic-motor /home/$SUDO_USER/repo/ingenic-motor
sudo -u $SUDO_USER git clone https://github.com/gtxaspec/prudynt-t /home/$SUDO_USER/repo/prudynt-t
sudo -u $SUDO_USER git clone https://github.com/gtxaspec/ingenic-musl /home/$SUDO_USER/repo/ingenic-musl
sudo -u $SUDO_USER git clone https://github.com/gtxaspec/thingino-linux -b ingenic-t31 /home/$SUDO_USER/repo/thingino-linux-3-10-14-t31
sudo -u $SUDO_USER git clone https://github.com/gtxaspec/thingino-linux -b ingenic-t40 /home/$SUDO_USER/repo/thingino-linux-4-4-94-t40
sudo -u $SUDO_USER git clone https://github.com/gtxaspec/thingino-linux -b ingenic-t41-4.4.94 /home/$SUDO_USER/repo/thingino-linux-4-4-94-t41

# Set the ccache size as the original user
sudo -u $SUDO_USER ccache --max-size=10G

# Update the PATH for the user
echo 'export PATH=/usr/bin/ccache:$PATH:/home/'$SUDO_USER'/toolchain/mipsel-xburst1-thingino-linux-musl_sdk-buildroot/bin/' >> /home/$SUDO_USER/.bashrc
echo 'export QEMU_LD_PREFIX=/home/'$SUDO_USER'/toolchain/mipsel-xburst1-thingino-linux-musl_sdk-buildroot/mipsel-thingino-linux-musl/sysroot' >> /home/$SUDO_USER/.bashrc
echo 'export BR2_DL_DIR=/mnt/BR2_DL' >> /home/$SUDO_USER/.bashrc
echo 'alias install-additional-tools="$HOME/scripts/additional-tools-setup.sh"' >> /home/$SUDO_USER/.bashrc

# Create local shared directories as the original user
sudo -u $SUDO_USER mkdir -p /home/$SUDO_USER/BR2_DL
sudo -u $SUDO_USER mkdir -p /home/$SUDO_USER/thingino-output

# Ready!
echo -e "\nSetup is complete... WELCOME TO THINGINO-DEVELOPMENT.\n"

echo -e "\e[38;5;208m  \\\   \e[38;5;231m_______ _     _ \e[38;5;208m_____ __   _  ______ \e[38;5;231m_____ __   _  _____"
echo -e "\e[38;5;208m  )\\\  \e[38;5;231m   |    |_____| \e[38;5;208m  |   | \  | |  ____ \e[38;5;231m  |   | \  | |     |"
echo -e "\e[38;5;208m (  /  \e[38;5;231m  |    |     | \e[38;5;208m__|__ |  \_| |_____| \e[38;5;231m__|__ |  \_| |_____|"
echo -e "\e[38;5;208m / /\n"
echo -e "\e[0mTo install additional tools (binwalk, etc.), run: \e[1minstall-additional-tools\e[0m\n"
