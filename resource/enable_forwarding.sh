#!/bin/bash

# Function to show help
show_help() {
	echo "Usage: $0 [-a] [-d] [-i] [-h]"
	echo "Options:"
	echo "  -a    Add the iptables entry"
	echo "  -d    Delete the iptables entry"
	echo "  -i    Show the target container name and IP address"
	echo "  -h    Show help"
}

# Check if the script is running as root
if [[ $(id -u) -ne 0 ]]; then
	echo "This script must be run with sudo."
	exit 1
fi

# Parse arguments
ADD=false
DELETE=false
INFO=false
while getopts "adih" opt; do
	case $opt in
		a)
			ADD=true
			;;
		d)
			DELETE=true
			;;
		i)
			INFO=true
			;;
		h)
			show_help
			exit 0
			;;
		\?)
			show_help
			exit 1
			;;
	esac
done

# Show help by default if no valid option is provided
if [[ "$ADD" = false && "$DELETE" = false && "$INFO" = false ]]; then
	show_help
	exit 1
fi

CONTAINER_NAME="thingino-development"
CONTAINER_IP=$(lxc-info -n $CONTAINER_NAME -iH)

if [ -z "$CONTAINER_IP" ]; then
	echo "Failed to obtain IP address for container $CONTAINER_NAME"
	exit 1
fi

if $INFO; then
	echo "Container Name: $CONTAINER_NAME"
	echo "Container IP: $CONTAINER_IP"
fi

if $DELETE; then
	echo "Deleting port forwarding for TFTP (port 69)..."
	iptables -t nat -D PREROUTING -p udp --dport 69 -j DNAT --to-destination $CONTAINER_IP:69
	iptables -D FORWARD -p udp -d $CONTAINER_IP --dport 69 -j ACCEPT
	echo "Port forwarding entry deleted."
elif $ADD; then
	echo "Setting up port forwarding for TFTP (port 69)..."
	iptables -t nat -A PREROUTING -p udp --dport 69 -j DNAT --to-destination $CONTAINER_IP:69
	iptables -A FORWARD -p udp -d $CONTAINER_IP --dport 69 -j ACCEPT
	echo "Port forwarding entry added."
fi
