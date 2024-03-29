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

echo "Version 0.6"
echo "This script will setup an LXC debian 12 container.  Starting in 10 seconds..."

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

echo -e "\nLXC container setup is complete... WELCOME TO THINGINO-DEVELOPMENT.  \n\nUse 'sudo lxc-attach -n thingino-development -- su - thingino-dev' to attach to your container at anytime.\n"
echo -e "Attaching you to your "thingino-development" container..."
lxc-attach -n thingino-development -- su - thingino-dev