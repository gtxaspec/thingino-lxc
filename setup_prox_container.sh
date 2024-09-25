#!/bin/bash

### This script is meant to run inside of a proxmox container

# Get the current logged-in user
USER_NAME=$(whoami)
VERSION=0.21
PACKAGES="apt-transport-https apt-utils bc bison build-essential ca-certificates ccache cpio curl dialog \
file figlet flex gawk gcc git libncurses-dev lzop make mc nano patchelf qemu-user \
qemu-user-binfmt rsync ssh tftpd-hpa toilet toilet-fonts u-boot-tools unzip wget whiptail xterm"

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
sudo -u $SUDO_USER wget https://raw.githubusercontent.com/gtxaspec/thingino-lxc/master/additional-tools-setup.sh -P /home/$SUDO_USER/
sudo -u $SUDO_USER chmod +x /home/$SUDO_USER/additional-tools-setup.sh

# Download and extract the toolchain as the original user
sudo -u $SUDO_USER mkdir -p /home/$SUDO_USER/toolchain/
cd /home/$SUDO_USER/toolchain/
sudo -u $SUDO_USER wget https://github.com/themactep/thingino-firmware/releases/download/toolchain/thingino-toolchain_xburst1_musl_gcc14-linux-mipsel.tar.gz
sudo -u $SUDO_USER tar -xf thingino-toolchain_xburst1_musl_gcc14-linux-mipsel.tar.gz
cd /home/$SUDO_USER/toolchain/mipsel-thingino-linux-musl_sdk-buildroot/
sudo -u $SUDO_USER ./relocate-sdk.sh

# Clone necessary repositories as the original user
sudo -u $SUDO_USER git clone --depth 1 --recurse-submodules --shallow-submodules https://github.com/themactep/thingino-firmware /home/$SUDO_USER/thingino-firmware
sudo -u $SUDO_USER git clone --depth 1 https://github.com/gtxaspec/u-boot-ingenic /home/$SUDO_USER/u-boot-ingenic
sudo -u $SUDO_USER git clone --depth 1 https://github.com/themactep/ingenic-sdk /home/$SUDO_USER/ingenic-sdk
sudo -u $SUDO_USER git clone --depth 1 https://github.com/gtxaspec/ingenic-motor /home/$SUDO_USER/ingenic-motor
sudo -u $SUDO_USER git clone --depth 1 https://github.com/gtxaspec/prudynt-t /home/$SUDO_USER/prudynt-t
sudo -u $SUDO_USER git clone --depth 1 https://github.com/gtxaspec/ingenic-musl /home/$SUDO_USER/ingenic-musl

# Set the ccache size as the original user
sudo -u $SUDO_USER ccache --max-size=10G

# Update the PATH for the user
echo 'export PATH=/usr/bin/ccache:$PATH:/home/'$SUDO_USER'/toolchain/mipsel-thingino-linux-musl_sdk-buildroot/bin/' >> /home/$SUDO_USER/.bashrc
echo 'export QEMU_LD_PREFIX=/home/'$SUDO_USER'/toolchain/mipsel-thingino-linux-musl_sdk-buildroot/mipsel-thingino-linux-musl/sysroot' >> /home/$SUDO_USER/.bashrc
echo 'export BR2_DL_DIR=/mnt/BR2_DL' >> /home/$SUDO_USER/.bashrc

# Create local shared directories as the original user
sudo -u $SUDO_USER mkdir -p /home/$SUDO_USER/BR2_DL
sudo -u $SUDO_USER mkdir -p /home/$SUDO_USER/thingino_output

# Ready!
echo -e "\nSetup is complete... WELCOME TO THINGINO-DEVELOPMENT.\n"
