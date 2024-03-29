#!/bin/bash

# Check if the script is running as root
if [[ $(id -u) -ne 0 ]]; then
	echo "This script must be run with sudo or as root."
	exit 1
fi

# Function to install LXC
install_lxc() {
	echo "Updating package lists..."
	sudo apt-get update
	echo "Installing LXC..."
	sudo apt-get install lxc
}

# Determine the architecture
arch=$(uname -m)
case $arch in
	x86_64)
		lxc_arch="amd64"
		;;
	aarch64)
		lxc_arch="arm64"
		;;
	*)
		echo "Unsupported architecture: $arch.  amd64/arm64 only."
		exit 1
		;;
esac

# Check for necessary LXC commands and offer to install if missing
installation_needed=false
for cmd in lxc-create lxc-start lxc-attach; do
	if ! command -v $cmd &> /dev/null; then
		echo "Required command '$cmd' is not installed."
		installation_needed=true
	fi
done

if [ "$installation_needed" = true ]; then
	read -p "LXC is not fully installed. Would you like to install it now? (y/n) " answer
	if [[ $answer =~ ^[Yy]$ ]]; then
		install_lxc
		echo "LXC has been installed."
	else
		echo "LXC installation aborted. Exiting."
		exit 1
	fi
fi

echo "Version 0.8"
echo -e "This script will setup an LXC debian 12 container tailored for thingino-firmware development  \n\n*** Make sure you have at least 10GB available storage for development! ***\n\nStarting in 10 seconds..."
echo "Press Ctrl-C to exit now."

sleep 10

# Create a new LXC container
echo "Creating LXC container with architecture: $lxc_arch"
lxc-create -t download -n thingino-development -- --dist debian --release bookworm --arch $lxc_arch

# Unprivileged users can't create apparmor namespaces...
sed -i '/^lxc.apparmor.profile = generated/c\lxc.apparmor.profile = unconfined' /var/lib/lxc/thingino-development/config

# Start the container and check for failure
lxc-start -n thingino-development || { echo "Failed to start the container. Exiting."; exit 1; }

# Wait for the container to start up
sleep 5

# Update and install necessary packages
lxc-attach -n thingino-development -- apt-get update
lxc-attach -n thingino-development -- apt-get install -y --no-install-recommends --no-install-suggests build-essential bc bison cpio curl file flex git libncurses-dev make rsync unzip wget whiptail gcc gcc-mipsel-linux-gnu lzop u-boot-tools ca-certificates ccache nano sudo xterm vim whiptail figlet toilet toilet-fonts locales ssh cpio apt-utils apt-transport-https patchelf qemu-user qemu-user-binfmt
lxc-attach -n thingino-development -- /bin/bash -c "cd /var/lib/dpkg/info/ && apt install --reinstall \$(grep -l 'setcap' * | sed -e 's/\\.[^.]*\$//g' | sort --unique)"

# Add a new user without a password
lxc-attach -n thingino-development -- adduser thingino-dev --disabled-password --gecos ""

# Create a new sudoers file for thingino-dev allowing passwordless sudo
echo "thingino-dev ALL=(ALL) NOPASSWD: ALL" | sudo lxc-attach -n thingino-development -- tee /etc/sudoers.d/thingino-dev

# Clone necessary repositories
lxc-attach -n thingino-development -- su - thingino-dev -c "git clone --recurse-submodules https://github.com/themactep/thingino-firmware"
lxc-attach -n thingino-development -- su - thingino-dev -c "git clone https://github.com/gtxaspec/u-boot-ingenic"
lxc-attach -n thingino-development -- su - thingino-dev -c "git clone https://github.com/themactep/ingenic-sdk"
lxc-attach -n thingino-development -- su - thingino-dev -c "git clone https://github.com/themactep/thingino-webui"

# Download and extract the toolchain
lxc-attach -n thingino-development -- su - thingino-dev -c "mkdir ~/toolchain/; cd ~/toolchain/; wget https://github.com/themactep/thingino-firmware/releases/download/toolchain/thingino-toolchain_xburst1_musl_gcc13-linux-mipsel.tar.gz; tar -xf thingino-toolchain_xburst1_musl_gcc13-linux-mipsel.tar.gz; cd ~/toolchain/mipsel-thingino-linux-musl_sdk-buildroot/; ./relocate-sdk.sh"

# Set the ccache size
lxc-attach -n thingino-development -- su - thingino-dev -c "ccache --max-size=10G"

# Update the PATH for the thingino-dev user
lxc-attach -n thingino-development -- su - thingino-dev -c "echo 'export PATH=/usr/bin/ccache:\$PATH:/home/thingino-dev/toolchain/mipsel-thingino-linux-musl_sdk-buildroot/bin/' >> ~/.bashrc"
lxc-attach -n thingino-development -- su - thingino-dev -c "echo 'export BR2_DL_DIR=/mnt/BR2_DL' >> ~/.bashrc"

# Add an alias thingino-dev user to start the container
echo "alias attach-thingino='echo "attach to thingino-development container..."; sudo lxc-attach -n thingino-development -- su - thingino-dev'" >> ~/.bashrc
source ~/.bashrc

# Create local shared directories
su $SUDO_USER - bash -c "mkdir -p /home/$SUDO_USER/BR2_DL"
su $SUDO_USER - bash -c "mkdir -p /home/$SUDO_USER/thingino_output"
echo "lxc.mount.entry = /home/$SUDO_USER/BR2_DL mnt/BR2_DL none bind,create=dir 0 0" >> /var/lib/lxc/thingino-development/config
echo "lxc.mount.entry = /home/$SUDO_USER/thingino_output home/thingino-dev/output none bind,create=dir 0 0" >> /var/lib/lxc/thingino-development/config

# Restart container
lxc-stop thingino-development
lxc-start thingino-development

# Ready!

echo -e "\nLXC container setup is complete... WELCOME TO THINGINO-DEVELOPMENT.  \n\nUse 'attach-thingino' to attach to your container at anytime.\n"
echo -e "Attaching you to your "thingino-development" container...\n"

echo "  \\   _______ _     _ _____ __   _  ______ _____ __   _  _____"
echo "  )\\     |    |_____|   |   | \  | |  ____   |   | \  | |     |"
echo " (  /    |    |     | __|__ |  \_| |_____| __|__ |  \_| |_____|"
echo " / /"
echo "    "

lxc-attach -n thingino-development -- su - thingino-dev


