**Start Developing with Thingino Using LXC**

Are you looking to start development with Thingino but worried about cluttering your system with additional software? An efficient solution is to utilize an LXC container. This approach gives you a fully operational Debian system contained within a virtual environment, already set up for your development needs. LXC serves as a lightweight alternative to Docker and is quite straightforward to use, especially if you're accustomed to Debian-based systems.

### Getting Started with LXC

**1. Install LXC:**  
If you're on a Debian-based system (like Ubuntu), installing LXC is straightforward. Open your terminal and execute the following command:

```bash
apt install lxc
```

This command installs LXC, the platform we'll use to create and manage our isolated development environments.

**2. Set Up Your Development Environment:**  
Once LXC is installed, you can prepare your Thingino development environment. We've made this easy with a prepared setup script, which automates the creation and configuration of a new container specifically for Thingino development.

Download and execute the setup script by entering these commands in your terminal (ensure you're in the directory where you wish to download the script):

```bash
wget https://raw.githubusercontent.com/gtxaspec/thingino-lxc/master/setup_thingino_lxc.sh -O setup_thingino_lxc.sh
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
sudo lxc-attach -n thingino-development -- su - thingino-dev
```

This command performs the following actions:
- `sudo`: Runs the following command with administrative privileges, necessary for LXC container management.
- `lxc-attach -n thingino-development`: Connects you to the 'thingino-development' container.
- `-- su - thingino-dev`: Switches to the 'thingino-dev' user account within the container, where your development setup resides.

By running this command, you'll be placed directly into your Thingino development workspace inside the container, where you can code, build, and test within an isolated and dedicated environment.

**Exiting the Container**

To finish your session and return to your host system's command line, type `exit` and press Enter. This command logs you out from the 'thingino-dev' user. If you're still inside the container, typing `exit` again will disconnect you from it.

Remember, your LXC container retains its state between sessions, allowing you to pick up right where you left off by reattaching using the same command.

### Benefits of Using Containers for Development

- **Isolation:** Keeps your primary operating system clean and unaffected.
- **Reproducible:** Simplifies the process of replicating or deleting the development environment.
- **Efficiency:** Containers typically use resources more sparingly than full virtual machines.

Now, you're all set to enjoy hassle-free development with Thingino in a clean, organized LXC environment!
