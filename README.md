# No Docker. No Podman. Just *Linux*.

A ready-to-go development environment for [Thingino](https://github.com/themactep/thingino-firmware), powered by [LXC](https://linuxcontainers.org), native Linux containerization with no daemons, no runtimes, and no abstraction layers. Just kernel-level isolation that feels like a normal Debian system.

**Why LXC?**
- **Lightweight** - uses a fraction of the resources of a full VM
- **Isolated** - keeps your host system clean and unaffected
- **Reproducible** - consistent firmware builds every time
- **Native** - no container engine required, just the Linux kernel

**Two setup paths:**
1. **[Standalone LXC](#standalone-lxc-setup)** - run directly on any Linux machine
2. **[Proxmox](#proxmox-setup)** - use an existing Proxmox LXC container

---

## Standalone LXC Setup

Clone the repo and run the setup script on any Linux system:

```bash
git clone https://github.com/gtxaspec/thingino-lxc && cd thingino-lxc
sudo bash setup_thingino_lxc.sh
```

That's it. The script handles everything:
- Installs LXC on the host if not already present
- Creates a Debian container named `thingino-development`
- Installs all required build tools and dependencies
- Downloads toolchains and repositories
- Drops you into the container's shell, ready to build

> **Note:** Only the LXC package is installed on your host. Everything else lives inside the container. As a best practice, inspect the script before running it.

---

## What Gets Installed

### Toolchains

Installed to `~/toolchain/` inside the container:

- **mipsel-xburst1-thingino-linux-musl** - GCC cross-compilation toolchain for XBurst1 SoCs
- **mipsel-xburst2-thingino-linux-musl** - GCC cross-compilation toolchain for XBurst2 SoCs

### Repositories

Cloned to `~/repo/` inside the container:

- **thingino-firmware** - Main Thingino firmware repository
- **ingenic-u-boot-xburst1** - U-Boot for XBurst1 SoCs
- **ingenic-u-boot-xburst2-t40** - U-Boot for T40 SoCs
- **ingenic-u-boot-xburst2-t41** - U-Boot for T41 SoCs
- **ingenic-sdk** - Ingenic SDK
- **ingenic-motor** - Motor control support
- **prudynt-t** - Prudynt video streaming application
- **ingenic-musl** - Musl libc for Ingenic platforms
- **thingino-linux-3-10-14-t31** - Linux kernel for T31
- **thingino-linux-4-4-94-t40** - Linux kernel for T40
- **thingino-linux-4-4-94-t41** - Linux kernel for T41

---

## Shared Directory

The setup script creates a shared directory at `$HOME/thingino-output` on your host. Use it for:

- **Data Transfer** - move files between host and container
- **Firmware Access** - compiled firmware appears here automatically
- **Persistent Storage** - survives container stops and restarts

---

## Additional Development Tools

For firmware analysis and reverse engineering, the container includes an optional tool installer:

```bash
install-additional-tools
```

This compiles and installs tools like binwalk. Running it again is safe, it will detect previously installed tools.

---

## Day-to-Day Usage

**Attach to your container:**

```bash
attach-thingino
```

You're dropped directly into the Thingino development workspace. Code, build, and test in an isolated environment.

**Detach from the container:**

Type `exit` to log out of the `dev` user. If still inside the container, type `exit` again to return to your host shell. Your container retains its state between sessions, so you can pick up right where you left off.

---

## Demo

Installation demonstration video:

https://github.com/themactep/thingino-firmware/assets/12115272/f50f91c6-338b-4eaf-ac51-0a7e3248fb3b

---

## Proxmox Setup

If you're using Proxmox as your virtualization platform, a dedicated setup script is provided. Run it inside an existing Proxmox LXC container to configure it for Thingino development, no manual setup required.

```bash
sudo ./prox_container_setup.sh
```

**Requirements:**
- Debian 12 or 13 container
- At least 10 GB of free space
- Run with `sudo`

The script installs all dependencies, toolchains, and repositories directly into your Proxmox container, giving you the same fully configured environment as the standalone setup.
