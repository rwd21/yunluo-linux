# Yunluo Linux - Native Arch Linux for Redmi Pad

[![License](https://img.shields.io/badge/license-GPL--3.0-blue.svg)](LICENSE)
[![Status](https://img.shields.io/badge/status-under%20development-orange.svg)](https://github.com/rwd21/yunluo-linux)

Native Arch Linux ARM operating system for the Xiaomi Redmi Pad (codename: yunluo), replacing or dual-booting with Android.

## ⚠️ Warning

**This project is in early development!**

- May void your warranty
- Risk of bricking your device
- Data loss is possible
- Advanced Linux knowledge required
- Not for production use yet

**Always backup your data before proceeding!**

## 🎯 Project Status

🚧 **Under Active Development** - Core documentation and build infrastructure complete

### Current Progress

- ✅ Documentation framework
- ✅ Build system design
- ⏳ Kernel configuration (in progress)
- ⏳ Device tree creation (in progress)
- ⏳ Root filesystem builder (in progress)
- ⏳ Hardware driver support (in progress)

See [HARDWARE.md](HARDWARE.md) for detailed hardware support status.

## 📱 Device Information

| Specification | Details |
|--------------|---------|
| **Device** | Xiaomi Redmi Pad |
| **Codename** | yunluo |
| **SoC** | MediaTek Helio G99 (MT6789) |
| **CPU** | Octa-core (2x2.2 GHz Cortex-A76 & 6x2.0 GHz Cortex-A55) |
| **GPU** | Mali-G57 MC2 |
| **RAM** | 3GB / 4GB / 6GB variants |
| **Storage** | 64GB / 128GB eMMC |
| **Display** | 10.61" IPS LCD, 1200 x 2000 pixels |
| **Architecture** | ARM64 (aarch64) |

## 🚀 Quick Start

### Prerequisites

- Xiaomi Redmi Pad with unlocked bootloader
- Linux computer (Arch Linux recommended)
- USB cable for flashing
- Basic knowledge of Linux, Android, and command line
- Backup of all important data

### Installation Overview

1. **Unlock bootloader** (see [INSTALLATION.md](INSTALLATION.md#unlocking-the-bootloader))
2. **Build or download** system images (see [BUILDING.md](BUILDING.md))
3. **Flash** boot image and install root filesystem
4. **Configure** system on first boot

Detailed instructions: [INSTALLATION.md](INSTALLATION.md)

## 📚 Documentation

Comprehensive guides for building and installing Arch Linux on Redmi Pad:

| Document | Description |
|----------|-------------|
| [BUILDING.md](BUILDING.md) | Complete build instructions for kernel, rootfs, and boot images |
| [INSTALLATION.md](INSTALLATION.md) | Step-by-step installation guide with bootloader unlock and flashing |
| [HARDWARE.md](HARDWARE.md) | Hardware support status matrix and compatibility information |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Common issues, diagnostics, and solutions |
| [DUAL-BOOT.md](DUAL-BOOT.md) | Dual-boot setup with Android (optional) |

## 🏗️ Project Structure

```
yunluo-linux/
├── config/              # Configuration files
│   ├── kernel/         # Kernel configs
│   ├── rootfs/         # Root filesystem configs
│   ├── boot/           # Boot configuration
│   └── system/         # System services and configs
├── scripts/            # Build and utility scripts
│   ├── build-kernel.sh
│   ├── build-rootfs.sh
│   ├── create-bootimg.sh
│   └── extract-firmware.sh
├── patches/            # Kernel and system patches
│   ├── kernel/
│   └── device-tree/
├── firmware/           # Device firmware (extracted from Android)
│   ├── wifi/
│   ├── bluetooth/
│   └── gpu/
├── device-tree/        # Device tree sources
│   └── mt6789-yunluo.dts
├── Makefile           # Master build automation
├── README.md          # This file
├── BUILDING.md        # Build guide
├── INSTALLATION.md    # Installation guide
├── HARDWARE.md        # Hardware status
├── TROUBLESHOOTING.md # Troubleshooting guide
└── DUAL-BOOT.md       # Dual-boot guide
```

## 🔧 Building

### Quick Build

```bash
# Clone repository
git clone https://github.com/rwd21/yunluo-linux.git
cd yunluo-linux

# Install dependencies (Arch Linux)
sudo pacman -S base-devel git wget curl android-tools dtc \
               aarch64-linux-gnu-gcc aarch64-linux-gnu-binutils

# Build everything
make all

# Output will be in build/ directory
```

See [BUILDING.md](BUILDING.md) for detailed build instructions.

## 💾 Installation Methods

### Method 1: Internal Storage (Recommended)
- Faster performance
- Full system replacement
- See [INSTALLATION.md - Method 1](INSTALLATION.md#method-1-internal-storage-installation)

### Method 2: SD Card Installation
- Keep Android intact
- Easier to test
- Removable
- See [INSTALLATION.md - Method 2](INSTALLATION.md#method-2-sd-card-installation)

### Method 3: Dual-Boot
- Run both Android and Linux
- Switch between systems
- See [DUAL-BOOT.md](DUAL-BOOT.md)

## 🎯 Roadmap

### Phase 1: Foundation (Current)
- [x] Documentation framework
- [ ] Kernel configuration for MT6789
- [ ] Device tree creation
- [ ] Basic boot capability

### Phase 2: Core Hardware
- [ ] Display output (framebuffer/DRM)
- [ ] Touch input
- [ ] WiFi connectivity
- [ ] Storage access

### Phase 3: Essential Features
- [ ] Desktop environment (XFCE)
- [ ] Audio support
- [ ] Battery management
- [ ] USB functionality

### Phase 4: Advanced Features
- [ ] GPU acceleration (Mali-G57)
- [ ] Bluetooth
- [ ] Sensors
- [ ] Camera support (optional)

See issues and milestones for detailed tracking.

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

### Ways to Contribute

- **Testing**: Install and test on your device, report issues
- **Development**: Kernel patches, driver development, bug fixes
- **Documentation**: Improve guides, add tutorials
- **Hardware Support**: Work on specific hardware components
- **Firmware**: Help extract and document firmware

### Getting Started

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly
5. Commit (`git commit -m 'Add amazing feature'`)
6. Push to branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

Please read existing documentation and code before contributing.

## 🐛 Reporting Issues

When reporting issues, include:

1. Device model and variant (RAM/storage)
2. Steps to reproduce
3. Expected vs actual behavior
4. Kernel version and build info
5. Relevant logs (dmesg, Xorg.log, etc.)
6. What you've already tried

Use the issue templates when available.

## 💬 Community & Support

- **GitHub Issues**: Bug reports and feature requests
- **Discussions**: Questions and general discussion
- **XDA Developers**: [Forum thread] (to be created)

## 📖 References & Resources

### Similar Projects
- [PostmarketOS](https://postmarketos.org/) - Linux on mobile devices
- [Arch Linux ARM](https://archlinuxarm.org/) - Arch Linux for ARM devices
- [Mobian](https://mobian-project.org/) - Debian for mobile

### Technical Resources
- [Linux Kernel Documentation](https://www.kernel.org/doc/)
- [MediaTek Kernel Sources](https://github.com/MiCode/Xiaomi_Kernel_OpenSource)
- [Android Boot Image Format](https://source.android.com/docs/core/architecture/bootloader)
- [Device Tree Documentation](https://www.devicetree.org/)

### Community
- [XDA Developers - Redmi Pad](https://forum.xda-developers.com/)
- [Arch Linux ARM Forums](https://archlinuxarm.org/forum)
- [PostmarketOS Wiki](https://wiki.postmarketos.org/)

## ⚖️ License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

### Third-Party Components

- Linux Kernel: GPL-2.0
- Arch Linux packages: Various licenses
- Firmware blobs: Proprietary (extracted from stock Android)

## 🙏 Credits

- **Arch Linux ARM** community for the base distribution
- **PostmarketOS** developers for mobile Linux pioneering work
- **MediaTek** for kernel sources
- **Xiaomi** for the Redmi Pad hardware
- All contributors and testers

## ⚠️ Disclaimer

This project is not affiliated with, endorsed by, or supported by Xiaomi, MediaTek, or Arch Linux. Use at your own risk.

- This will void your warranty
- We are not responsible for bricked devices
- Always maintain backups
- Only proceed if you understand the risks

## 📊 Project Stats

- **Language**: C, Shell, Makefile, Device Tree
- **Target Device**: Xiaomi Redmi Pad (yunluo)
- **Base System**: Arch Linux ARM (aarch64)
- **Kernel**: Linux 6.6+ (planned)

---

**Made with ❤️ for the Linux and mobile development community**

For questions, issues, or contributions, visit [GitHub](https://github.com/rwd21/yunluo-linux).