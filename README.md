## Start Developing with Thingino Using LXC

Are you looking to start development with Thingino but worried about cluttering your system with additional software? An efficient solution is to utilize an LXC container. This approach gives you a fully operational Debian system contained within a virtual environment, already set up for your development needs. LXC serves as a lightweight alternative to Docker and is quite straightforward to use, especially if you're accustomed to Debian-based systems.

### Getting Started with LXC

**Set Up Your Development Environment:**
We've made installation easy with a prepared setup script, which automates the creation and configuration of a new container specifically for Thingino development. This script will prompt you to install LXC (if not installed), the platform we'll use to create and manage our isolated development environments.  Once LXC is installed, you can prepare your Thingino development environment.

Download and execute the setup script by entering these commands in your terminal (ensure you're in the directory where you wish to download the script):

```bash
git clone https://github.com/gtxaspec/thingino-lxc && cd thingino-lxc
sudo bash setup_thingino_lxc.sh
```

This script will automatically generate an LXC container named 'thingino-development' and install all the necessary tools and software required for Thingino development, including various thingino related repositories.

The script will automatically attach to the container after installation, dropping you to the command prompt.  You are now ready to start developing!

### Accessing Your Development Environment

Whenever you're ready to start working, accessing your dedicated Thingino environment is simple:

**1. Open Your Terminal:**
Launch your terminal to begin.

**2. Attach to Your Container:**
Enter the following command to access your development environment:

```bash
attach-thingino
```

By running this command, you'll be placed directly into your Thingino development workspace inside the container, where you can code, build, and test within an isolated and dedicated environment.

**Exiting the Container**

To finish your session and return to your host system's command line, type `exit` and press Enter. This command logs you out from the 'dev' user. If you're still inside the container, typing `exit` again will disconnect you from it.

Remember, your LXC container retains its state between sessions, allowing you to pick up right where you left off by reattaching using the same command.

Installation Demonstration Video:

https://github.com/themactep/thingino-firmware/assets/12115272/f50f91c6-338b-4eaf-ac51-0a7e3248fb3b

### Setting Up with a Proxmox Container

If you're using Proxmox as your virtualization platform, we've created a script to simplify the development setup process. This script is designed for users who already have a Proxmox LXC container configured. It automates the configuration of your container environment for Thingino development by installing all necessary dependencies, tools, and repositories directly into the Proxmox container.

To run the script, use the following command:

```bash
sudo ./setup_prox_container.sh
```

Make sure to run the script using `sudo` and ensure you have at least 5 GB of free space available. The script is compatible with Debian 12 or 13 containers and will download the required repositories for Thingino development.

By running this script inside a Proxmox container, you can quickly set up a fully operational Thingino development environment without manual intervention. Simply download and execute the script within a Debian 12 or 13 container, and it will handle the rest, ensuring your development environment is ready in just a few steps.

---

### Benefits of Using Containers for Development

- **Isolation:** Keeps your primary operating system clean and unaffected.
- **Reproducible:** Simplifies the process of replicating or deleting the development environment.
- **Efficiency:** Containers typically use resources more sparingly than full virtual machines.

Now, you're all set to enjoy hassle-free development with Thingino in a clean, organized LXC environment!
