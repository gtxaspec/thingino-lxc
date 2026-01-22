#!/bin/bash

CONTAINER_NAME="thingino-development"
CONTAINER_USER="dev"
CONTAINER_CONFIG_FILE="/var/lib/lxc/$CONTAINER_NAME/config"
VERSION=0.32
PACKAGES="apt-transport-https apt-utils autoconf bc bison build-essential ca-certificates ccache cmake cpio curl dialog \
file figlet flex gawk gcc git libncurses-dev lzop make mc nano patchelf \
qemu-user qemu-user-binfmt rsync ssh tftpd-hpa toilet \
toilet-fonts tree u-boot-tools unzip vim-tiny wget whiptail xterm"

# Check if the script is running as root
if [[ $(id -u) -ne 0 ]]; then
	echo "This script must be run with sudo."
	exit 1
fi

# Function to install LXC
install_lxc() {
	echo "Updating package lists..."
	sudo apt-get update
	echo "Installing LXC..."
	sudo apt-get install -y --no-install-recommends --no-install-suggests lxc
}

# Determine the architecture
arch=$(uname -m)
case $arch in
	x86_64)
		lxc_arch="amd64"
		toolchain_arch="x86_64"
		;;
	aarch64)
		lxc_arch="arm64"
		toolchain_arch="aarch64"
		;;
	*)
		echo "Unsupported architecture: $arch.  amd64 and aarch64 only."
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

# Check if the container already exists
if lxc-info -n $CONTAINER_NAME &>/dev/null; then
    echo "The container '$CONTAINER_NAME' already exists. Please remove it before running this script again."
    exit 1
fi

clear
echo "thingino-lxc setup version $VERSION"
echo -e "\nThis script will setup an LXC debian 13 (trixie) container tailored for thingino-firmware development, and will install all required dependencies inside the container, so network access is required.\n\n*** Make sure you have at least 10GB available storage for required development tools and sources! ***\n\nStarting in 10 seconds..."
echo -e "Press Ctrl-C to exit now.\n"

sleep 10

# Create a new LXC container
echo "Creating LXC container with architecture: $lxc_arch"
lxc-create -t download -n $CONTAINER_NAME -- --dist debian --release trixie --arch $lxc_arch

# Adjust container config
if grep -q '^lxc.apparmor.profile = generated' "$CONTAINER_CONFIG_FILE"; then
    sed -i 's/^lxc.apparmor.profile = generated/lxc.apparmor.profile = unconfined/' "$CONTAINER_CONFIG_FILE"
else
    if ! grep -q '^lxc.apparmor.profile' "$CONTAINER_CONFIG_FILE"; then
        echo 'lxc.apparmor.profile = unconfined' >> "$CONTAINER_CONFIG_FILE"
    fi
fi

#Set container DNS
echo -e "DNS=8.8.8.8\nFallbackDNS=1.1.1.1" >> /var/lib/lxc/$CONTAINER_NAME/rootfs/etc/systemd/resolved.conf

# Start the container and check for failure
lxc-start -n $CONTAINER_NAME || { echo "Failed to start the container. Exiting."; exit 1; }

# Wait for the container to start up
echo "Starting container..."
sleep 5

# Add a new user without a password
lxc-attach -n $CONTAINER_NAME -- adduser $CONTAINER_USER --uid $SUDO_UID --disabled-password --gecos ""

############### USER ADDED ##########################################################################################

# Create a new sudoers file for $CONTAINER_USER allowing passwordless sudo
echo "$CONTAINER_USER ALL=(ALL) NOPASSWD: ALL" | sudo lxc-attach -n $CONTAINER_NAME -- tee /etc/sudoers.d/$CONTAINER_USER

# Adjust PATH for system
lxc-attach -n $CONTAINER_NAME -- /bin/bash -c "sed -i '/^if \[ \"\$(id -u)\" -eq 0 \]; then$/,/^fi$/c\PATH=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\"\n' /etc/profile"

# Update and install necessary packages
lxc-attach -n $CONTAINER_NAME -- sed -i 's/main contrib$/main contrib non-free non-free-firmware/g' /etc/apt/sources.list
lxc-attach -n $CONTAINER_NAME -- apt-get update
lxc-attach -n $CONTAINER_NAME -- apt-get install -y --no-install-recommends --no-install-suggests $PACKAGES
lxc-attach -n $CONTAINER_NAME -- /bin/bash -c "cd /var/lib/dpkg/info/ && apt install --reinstall -y --no-install-recommends --no-install-suggests \$(grep -l 'setcap' * | sed -e 's/\\.[^.]*\$//g' | sort --unique)"

#Setup tftpd
lxc-attach -n $CONTAINER_NAME -- /bin/bash -c "sed -i 's/^TFTP_DIRECTORY=\"\/srv\/tftp\"$/TFTP_DIRECTORY=\"\/home\/$CONTAINER_USER\/tftp\"/' /etc/default/tftpd-hpa"
lxc-attach -n $CONTAINER_NAME -- su - $CONTAINER_USER -c "mkdir ~/tftp"

# Download Additional tools script
lxc-attach -n $CONTAINER_NAME -- su - $CONTAINER_USER -c "mkdir ~/scripts"
lxc-attach -n $CONTAINER_NAME -- su - $CONTAINER_USER -c "wget https://raw.githubusercontent.com/gtxaspec/thingino-lxc/master/resource/additional-tools-setup.sh -P ~/scripts; chmod +x ~/scripts/additional-tools-setup.sh"

# Download and extract the toolchain
lxc-attach -n $CONTAINER_NAME -- su - $CONTAINER_USER -c "mkdir ~/toolchain/; cd ~/toolchain/; wget https://github.com/themactep/thingino-firmware/releases/download/toolchain-$toolchain_arch/thingino-toolchain-${toolchain_arch}_xburst1_musl_gcc14-linux-mipsel.tar.gz; mkdir mipsel-xburst1-thingino-linux-musl_sdk-buildroot;tar -xf thingino-toolchain-${toolchain_arch}_xburst1_musl_gcc14-linux-mipsel.tar.gz -C mipsel-xburst1-thingino-linux-musl_sdk-buildroot --strip-components=1; cd ~/toolchain/mipsel-xburst1-thingino-linux-musl_sdk-buildroot/; ./relocate-sdk.sh"
lxc-attach -n $CONTAINER_NAME -- su - $CONTAINER_USER -c "mkdir ~/toolchain/; cd ~/toolchain/; wget https://github.com/themactep/thingino-firmware/releases/download/toolchain-$toolchain_arch/thingino-toolchain-${toolchain_arch}_xburst2_musl_gcc14-linux-mipsel.tar.gz; mkdir mipsel-xburst2-thingino-linux-musl_sdk-buildroot;tar -xf thingino-toolchain-${toolchain_arch}_xburst2_musl_gcc14-linux-mipsel.tar.gz -C mipsel-xburst2-thingino-linux-musl_sdk-buildroot --strip-components=1; cd ~/toolchain/mipsel-xburst2-thingino-linux-musl_sdk-buildroot/; ./relocate-sdk.sh"

# Clone necessary repositories
lxc-attach -n $CONTAINER_NAME -- su - $CONTAINER_USER -c "mkdir repo"
lxc-attach -n $CONTAINER_NAME -- su - $CONTAINER_USER -c "git clone --recurse-submodules --shallow-submodules https://github.com/themactep/thingino-firmware repo/thingino-firmware"
lxc-attach -n $CONTAINER_NAME -- su - $CONTAINER_USER -c "git clone https://github.com/gtxaspec/u-boot-ingenic repo/ingenic-u-boot-xburst1"
lxc-attach -n $CONTAINER_NAME -- su - $CONTAINER_USER -c "git clone https://github.com/gtxaspec/ingenic-u-boot-xburst2 -b t40 repo/ingenic-u-boot-xburst2-t40"
lxc-attach -n $CONTAINER_NAME -- su - $CONTAINER_USER -c "git clone https://github.com/gtxaspec/ingenic-u-boot-xburst2 -b t41 repo/ingenic-u-boot-xburst2-t41"
lxc-attach -n $CONTAINER_NAME -- su - $CONTAINER_USER -c "git clone https://github.com/themactep/ingenic-sdk repo/ingenic-sdk"
lxc-attach -n $CONTAINER_NAME -- su - $CONTAINER_USER -c "git clone https://github.com/gtxaspec/ingenic-motor repo/ingenic-motor"
lxc-attach -n $CONTAINER_NAME -- su - $CONTAINER_USER -c "git clone https://github.com/gtxaspec/prudynt-t repo/prudynt-t"
lxc-attach -n $CONTAINER_NAME -- su - $CONTAINER_USER -c "git clone https://github.com/gtxaspec/ingenic-musl repo/ingenic-musl"
lxc-attach -n $CONTAINER_NAME -- su - $CONTAINER_USER -c "git clone https://github.com/gtxaspec/thingino-linux -b ingenic-t31 repo/thingino-linux-3-10-14-t31"
lxc-attach -n $CONTAINER_NAME -- su - $CONTAINER_USER -c "git clone https://github.com/gtxaspec/thingino-linux -b ingenic-t40 repo/thingino-linux-4-4-94-t40"
lxc-attach -n $CONTAINER_NAME -- su - $CONTAINER_USER -c "git clone https://github.com/gtxaspec/thingino-linux -b ingenic-t41-4.4.94 repo/thingino-linux-4-4-94-t41"

# Set the ccache size
lxc-attach -n $CONTAINER_NAME -- su - $CONTAINER_USER -c "ccache --max-size=10G"

# Update the PATH for the $CONTAINER_USER user
lxc-attach -n $CONTAINER_NAME -- su - $CONTAINER_USER -c "echo 'export PATH=/usr/bin/ccache:\$PATH:/home/$CONTAINER_USER/toolchain/mipsel-xburst1-thingino-linux-musl_sdk-buildroot/bin/' >> ~/.bashrc"
lxc-attach -n $CONTAINER_NAME -- su - $CONTAINER_USER -c "echo 'export QEMU_LD_PREFIX=/home/$CONTAINER_USER/toolchain/mipsel-xburst1-thingino-linux-musl_sdk-buildroot/mipsel-thingino-linux-musl/sysroot' >> ~/.bashrc"
lxc-attach -n $CONTAINER_NAME -- su - $CONTAINER_USER -c "echo 'export BR2_DL_DIR=/mnt/BR2_DL' >> ~/.bashrc"
lxc-attach -n $CONTAINER_NAME -- su - $CONTAINER_USER -c "echo 'alias install-additional-tools=\"\$HOME/scripts/additional-tools-setup.sh\"' >> ~/.bashrc"

# Add an alias for the host's user to start the container
if ! grep -q "alias attach-thingino=" /home/$SUDO_USER/.bashrc; then
	echo "alias attach-thingino='if [ \$(sudo lxc-info -n $CONTAINER_NAME -s | grep -c RUNNING) -eq 0 ]; then echo \"Starting $CONTAINER_NAME container...\"; sudo lxc-start -n $CONTAINER_NAME; sleep 5; fi; echo \"Attaching to $CONTAINER_NAME container...\"; sudo lxc-attach -n $CONTAINER_NAME -- su - $CONTAINER_USER'" >> /home/$SUDO_USER/.bashrc
fi

# Create local shared directories
su $SUDO_USER - bash -c "mkdir -p /home/$SUDO_USER/BR2_DL"
su $SUDO_USER - bash -c "mkdir -p /home/$SUDO_USER/thingino-output"
echo "lxc.mount.entry = /home/$SUDO_USER/BR2_DL mnt/BR2_DL none bind,create=dir 0 0" >> $CONTAINER_CONFIG_FILE
echo "lxc.mount.entry = /home/$SUDO_USER/thingino-output home/$CONTAINER_USER/output none bind,create=dir 0 0" >> $CONTAINER_CONFIG_FILE

# Restart container
lxc-stop $CONTAINER_NAME
lxc-start $CONTAINER_NAME

source ~/.bashrc

# Ready!

echo -e "\nLXC container setup is complete... WELCOME TO THINGINO-DEVELOPMENT.  \n\nUse 'attach-thingino' to return to your container at anytime.\n"
echo -e "Attaching you to your "$CONTAINER_NAME" container...\n"

echo -e "\e[38;5;208m  \\\   \e[38;5;231m_______ _     _ \e[38;5;208m_____ __   _  ______ \e[38;5;231m_____ __   _  _____"
echo -e "\e[38;5;208m  )\\\  \e[38;5;231m   |    |_____| \e[38;5;208m  |   | \  | |  ____ \e[38;5;231m  |   | \  | |     |"
echo -e "\e[38;5;208m (  /  \e[38;5;231m  |    |     | \e[38;5;208m__|__ |  \_| |_____| \e[38;5;231m__|__ |  \_| |_____|"
echo -e "\e[38;5;208m / /\n"
echo -e "\e[0mTo install additional tools (binwalk, etc.), run: \e[1minstall-additional-tools\e[0m\n"

lxc-attach -n $CONTAINER_NAME -- su - $CONTAINER_USER -c "echo -e \"ls /home/dev\";ls;echo -n \"ls \";tree -L 1 repo/"

lxc-attach -n $CONTAINER_NAME -- su - $CONTAINER_USER

echo -e "Installation complete!"
