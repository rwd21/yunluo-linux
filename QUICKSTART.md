# Quick Start Guide - Yunluo Linux

Get started with Yunluo Linux (Arch Linux on Redmi Pad) in minutes.

## For Users: Installing Yunluo Linux

### Prerequisites
- Xiaomi Redmi Pad (yunluo)
- Unlocked bootloader
- USB cable
- Computer with Android tools
- **⚠️ Backup all data!**

### Quick Installation

1. **Download pre-built image** (when available):
   ```bash
   # Check releases page
   wget https://github.com/rwd21/yunluo-linux/releases/latest/download/yunluo-linux.zip
   unzip yunluo-linux.zip
   ```

2. **Flash boot image**:
   ```bash
   # Boot device to fastboot mode (Volume Down + Power)
   fastboot flash boot boot-yunluo.img
   ```

3. **Install rootfs**:
   See [INSTALLATION.md](INSTALLATION.md#method-1-internal-storage-installation)

4. **Reboot**:
   ```bash
   fastboot reboot
   ```

### First Boot
- Default login: `root` / `root`
- Configure network, create user account
- Update system: `pacman -Syu`
- Install desktop: `pacman -S xfce4 lightdm`

**Full guide**: [INSTALLATION.md](INSTALLATION.md)

---

## For Developers: Building from Source

### Prerequisites
- Linux computer (Arch recommended)
- 50GB free disk space
- Fast internet connection
- Cross-compilation tools

### Quick Build

1. **Clone repository**:
   ```bash
   git clone https://github.com/rwd21/yunluo-linux.git
   cd yunluo-linux
   ```

2. **Setup development environment**:
   ```bash
   ./scripts/setup-dev.sh
   ```

3. **Download kernel source**:
   ```bash
   make download-kernel
   ```

4. **Build everything**:
   ```bash
   make all-build
   ```

5. **Find output**:
   ```bash
   ls -lh build/
   # boot-yunluo.img - Flashable boot image
   # rootfs-yunluo.tar.gz - Root filesystem
   ```

**Full guide**: [BUILDING.md](BUILDING.md)

---

## For Contributors: Getting Involved

### Ways to Help

**Testing** (Most Needed!):
- Install on your device
- Report hardware status
- Document issues

**Development**:
- Kernel patches
- Driver development
- Hardware support

**Documentation**:
- Improve guides
- Add tutorials
- Translate docs

### Quick Contribution

1. **Fork the repo**
2. **Make changes**
3. **Test thoroughly**
4. **Submit PR**

**Full guide**: [CONTRIBUTING.md](CONTRIBUTING.md)

---

## Project Status

**Current Phase**: Foundation Complete ✅

**What Works**:
- ✅ Documentation
- ✅ Build system
- ✅ Project infrastructure

**What's Next**:
- 🔄 Kernel development
- 🔄 Hardware support
- 🔄 Testing on device

**See**: [STATUS.md](STATUS.md) for detailed status

---

## Need Help?

### Common Questions

**Q: Is this safe?**
A: Only if you know what you're doing. Can brick your device.

**Q: Will I lose Android?**
A: Not if you use dual-boot. See [DUAL-BOOT.md](DUAL-BOOT.md)

**Q: Which Redmi Pad models work?**
A: Currently targeting all yunluo variants (3GB/4GB/6GB RAM)

**Q: Does [feature] work?**
A: Check [HARDWARE.md](HARDWARE.md) for current support status

**Q: Can I help without a device?**
A: Yes! Documentation, testing builds, code review all help.

### Resources

- **Documentation**: All `.md` files in this repo
- **Issues**: https://github.com/rwd21/yunluo-linux/issues
- **Discussions**: https://github.com/rwd21/yunluo-linux/discussions

### Getting Support

1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Search existing issues
3. Ask in Discussions
4. Open an issue (include full details)

---

## Important Links

| Document | Purpose |
|----------|---------|
| [README.md](README.md) | Project overview |
| [BUILDING.md](BUILDING.md) | Build from source |
| [INSTALLATION.md](INSTALLATION.md) | Install on device |
| [HARDWARE.md](HARDWARE.md) | Hardware support |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Fix issues |
| [DUAL-BOOT.md](DUAL-BOOT.md) | Keep Android |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Help the project |
| [STATUS.md](STATUS.md) | Current status |

---

## Quick Commands

```bash
# Check build environment
make info

# Build kernel only
make kernel

# Build rootfs only
make rootfs

# Create boot image
make bootimg

# Extract firmware from device
./scripts/extract-firmware.sh --from-device

# Clean build
make clean

# Get help
make help
```

---

## ⚠️ Warnings

**Before proceeding**:
- ✅ Backup all data
- ✅ Charge device to 80%+
- ✅ Read documentation
- ✅ Understand risks
- ✅ Have recovery plan

**Risks**:
- Void warranty
- Potential brick
- Data loss
- Unstable system

**Only proceed if you accept these risks!**

---

## License

GPL-3.0 - See [LICENSE](LICENSE)

Firmware files are proprietary and not covered by GPL.

---

**Ready to start? Pick your path above! 🚀**

For detailed information, start with [README.md](README.md) or [BUILDING.md](BUILDING.md).
