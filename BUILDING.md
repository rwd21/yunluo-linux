# Building Arch Linux for Redmi Pad (yunluo)

This guide covers building all components necessary to run native Arch Linux on the Xiaomi Redmi Pad.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Building the Kernel](#building-the-kernel)
- [Creating the Root Filesystem](#creating-the-root-filesystem)
- [Building the Boot Image](#building-the-boot-image)
- [Firmware Extraction](#firmware-extraction)
- [Complete Build Process](#complete-build-process)

## Prerequisites

### Required Tools
- Arch Linux or Arch-based system (recommended) or any Linux distribution
- Cross-compilation toolchain for ARM64
- Git
- Base development tools

### Install Build Dependencies

```bash
# On Arch Linux
sudo pacman -S base-devel git wget curl android-tools dtc bc \
               aarch64-linux-gnu-gcc aarch64-linux-gnu-binutils \
               qemu-user-static-binfmt arch-install-scripts

# On Debian/Ubuntu
sudo apt-get install build-essential git wget curl adb fastboot \
                     device-tree-compiler bc gcc-aarch64-linux-gnu \
                     binutils-aarch64-linux-gnu qemu-user-static \
                     binfmt-support
```

### Directory Setup

```bash
# Clone the repository
git clone https://github.com/rwd21/yunluo-linux.git
cd yunluo-linux

# Create build directory structure
mkdir -p build/{kernel,rootfs,boot,firmware}
```

## Building the Kernel

### Option 1: Using Mainline Kernel (Recommended)

```bash
# Navigate to kernel directory
cd kernel

# Download latest stable kernel
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.6.tar.xz
tar xf linux-6.6.tar.xz
cd linux-6.6

# Apply device-specific patches (if available)
# Note: MT6789 support may require additional patches
for patch in ../../patches/kernel/*.patch; do
    patch -p1 < "$patch"
done

# Load configuration
cp ../../config/kernel/yunluo_defconfig .config
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- olddefconfig

# Build kernel and modules
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)

# Build device tree
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- dtbs

# Install modules to staging area
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- \
     INSTALL_MOD_PATH=../../build/rootfs modules_install
```

### Option 2: Using MediaTek Kernel Source

```bash
# Clone MediaTek kernel (if available from Xiaomi)
git clone https://github.com/MiCode/Xiaomi_Kernel_OpenSource.git -b yunluo-main
cd Xiaomi_Kernel_OpenSource

# Apply Arch Linux patches
for patch in ../patches/kernel-mtk/*.patch; do
    patch -p1 < "$patch"
done

# Use provided defconfig or custom config
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- yunluo_defconfig

# Build
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
```

### Kernel Configuration

Key kernel options to enable:
- `CONFIG_MODULES=y` - Loadable module support
- `CONFIG_DRM=y` - Direct Rendering Manager
- `CONFIG_DRM_PANEL_SIMPLE=y` - Simple display panel
- `CONFIG_TOUCHSCREEN_MTK=y` - MediaTek touchscreen
- `CONFIG_MTK_CMDQ=y` - MediaTek command queue
- `CONFIG_MTK_SCP=y` - MediaTek System Control Processor
- `CONFIG_MALI_MIDGARD=m` - Mali GPU support
- `CONFIG_EXT4_FS=y` - ext4 filesystem
- `CONFIG_F2FS_FS=y` - F2FS filesystem
- `CONFIG_TMPFS=y` - tmpfs support
- `CONFIG_DEVTMPFS=y` - devtmpfs support
- `CONFIG_DEVTMPFS_MOUNT=y` - Auto-mount devtmpfs

## Creating the Root Filesystem

### Method 1: Using pacstrap (Recommended)

```bash
cd rootfs

# Create rootfs directory
mkdir -p archlinux-arm

# Download and extract Arch Linux ARM base
# Note: Use aarch64 architecture
wget http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz

# Extract to rootfs directory
sudo tar -xpf ArchLinuxARM-aarch64-latest.tar.gz -C archlinux-arm

# Chroot into the new system (using qemu for cross-arch)
sudo cp /usr/bin/qemu-aarch64-static archlinux-arm/usr/bin/
sudo mount --bind /dev archlinux-arm/dev
sudo mount --bind /proc archlinux-arm/proc
sudo mount --bind /sys archlinux-arm/sys
sudo chroot archlinux-arm /usr/bin/qemu-aarch64-static /bin/bash

# Inside chroot:
# Initialize pacman keyring
pacman-key --init
pacman-key --populate archlinuxarm

# Update system
pacman -Syu

# Install essential packages
pacman -S base-devel linux-firmware networkmanager sudo openssh vim

# Exit chroot
exit

# Cleanup
sudo umount archlinux-arm/{dev,proc,sys}
sudo rm archlinux-arm/usr/bin/qemu-aarch64-static
```

### Method 2: Using Build Script

```bash
# Use provided script
cd scripts
sudo ./build-rootfs.sh
```

### Customizing the Root Filesystem

```bash
# Copy device-specific files
sudo cp -r ../config/rootfs/* archlinux-arm/

# Install kernel modules (built earlier)
sudo cp -r ../build/rootfs/lib/modules/* archlinux-arm/lib/modules/

# Create device-specific configuration
sudo mkdir -p archlinux-arm/etc/yunluo
sudo cp ../config/system/* archlinux-arm/etc/yunluo/
```

## Building the Boot Image

### Creating initramfs

```bash
cd build/boot

# Create initramfs directory structure
mkdir -p initramfs/{bin,sbin,etc,proc,sys,dev,tmp,lib,usr,mnt/root}

# Copy essential binaries (busybox)
cp /usr/bin/busybox initramfs/bin/

# Create init script
cat > initramfs/init << 'EOF'
#!/bin/busybox sh

# Mount essential filesystems
/bin/busybox mount -t proc none /proc
/bin/busybox mount -t sysfs none /sys
/bin/busybox mount -t devtmpfs none /dev

# Load modules
/bin/busybox modprobe ext4
/bin/busybox modprobe f2fs

# Detect root device
for dev in mmcblk0p* mmcblk1p*; do
    if [ -e /dev/$dev ]; then
        /bin/busybox mount -t ext4 /dev/$dev /mnt/root 2>/dev/null && break
        /bin/busybox mount -t f2fs /dev/$dev /mnt/root 2>/dev/null && break
    fi
done

# Switch to real root
exec /bin/busybox switch_root /mnt/root /sbin/init
EOF

chmod +x initramfs/init

# Create initramfs archive
cd initramfs
find . | cpio -o -H newc | gzip > ../initramfs.cpio.gz
cd ..
```

### Creating boot.img

```bash
# Using mkbootimg
mkbootimg \
    --kernel ../../kernel/linux-6.6/arch/arm64/boot/Image.gz \
    --ramdisk initramfs.cpio.gz \
    --dtb ../../kernel/linux-6.6/arch/arm64/boot/dts/mediatek/mt6789-yunluo.dtb \
    --cmdline "console=tty0 root=/dev/mmcblk0p30 rootwait rw init=/sbin/init" \
    --base 0x40000000 \
    --pagesize 4096 \
    --output boot-yunluo.img

# Verify boot image
file boot-yunluo.img
```

## Firmware Extraction

Firmware must be extracted from the stock Android ROM.

```bash
cd scripts

# Extract firmware from stock ROM
./extract-firmware.sh /path/to/stock/rom.zip

# This will extract:
# - WiFi firmware (wlan/)
# - Bluetooth firmware (bt/)
# - GPU firmware (mali/)
# - Other device-specific firmware
```

### Manual Firmware Extraction

```bash
# Boot into recovery or ADB
adb root
adb pull /vendor/firmware firmware/
adb pull /vendor/lib64/hw firmware/hw/

# Extract necessary files:
# - WiFi: wlan_mt.cfg, WIFI_RAM_CODE_MT6765.bin, etc.
# - BT: mt66xx_fw.bin, etc.
# - GPU: mali_*.bin
```

## Complete Build Process

Use the automated Makefile:

```bash
# Build everything
make all

# Or build specific components
make kernel          # Build kernel only
make rootfs          # Build rootfs only
make bootimg         # Create boot image only
make firmware        # Extract firmware only

# Create flashable image
make image           # Creates complete flashable image

# Clean build artifacts
make clean
```

### Build Configuration

Edit `config/build.conf` to customize:

```bash
# Kernel configuration
KERNEL_VERSION=6.6
KERNEL_DEFCONFIG=yunluo_defconfig

# Rootfs configuration
ROOTFS_SIZE=4G
INSTALL_DE=xfce  # Desktop environment (none/xfce/lxqt)

# Boot configuration
CMDLINE="console=tty0 root=/dev/mmcblk0p30 rootwait rw"
```

## Build Output

After successful build, you'll have:

```
build/
├── boot-yunluo.img          # Flashable boot image
├── rootfs-yunluo.img        # Root filesystem image
├── kernel/
│   ├── Image.gz             # Kernel image
│   └── mt6789-yunluo.dtb    # Device tree blob
└── firmware/                # Firmware files
```

## Troubleshooting

### Kernel Build Fails

```bash
# Check kernel configuration
make ARCH=arm64 menuconfig

# Verify toolchain
aarch64-linux-gnu-gcc --version

# Clean and rebuild
make ARCH=arm64 clean
make ARCH=arm64 -j$(nproc)
```

### Rootfs Build Issues

```bash
# Ensure QEMU is properly configured
sudo update-binfmts --display

# Check available architectures
qemu-aarch64-static --version
```

### Boot Image Creation Fails

```bash
# Install mkbootimg
pip install mkbootimg

# Or use Android tools
# Install android-tools package
```

## Next Steps

After building, proceed to [INSTALLATION.md](INSTALLATION.md) for flashing instructions.

## References

- Linux Kernel Documentation: https://www.kernel.org/doc/
- Arch Linux ARM: https://archlinuxarm.org/
- Android Boot Image Format: https://source.android.com/docs/core/architecture/bootloader
- MediaTek Kernel Sources: https://github.com/MiCode/

## Support

For build issues, please:
1. Check TROUBLESHOOTING.md
2. Open an issue on GitHub
3. Join the XDA thread for the device
