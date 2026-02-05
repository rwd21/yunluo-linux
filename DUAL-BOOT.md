# Dual-Boot Configuration

Guide for setting up dual-boot between Arch Linux and Android on the Redmi Pad (yunluo).

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Dual-Boot Methods](#dual-boot-methods)
4. [Method 1: Separate Boot Images](#method-1-separate-boot-images)
5. [Method 2: MultiROM (Advanced)](#method-2-multirom-advanced)
6. [Method 3: SD Card Boot](#method-3-sd-card-boot)
7. [Switching Between Systems](#switching-between-systems)
8. [Troubleshooting](#troubleshooting)

## Overview

Dual-booting allows you to keep your Android system while running Arch Linux. You can choose which OS to boot at startup.

### Advantages
- Keep Android as fallback
- Switch between systems as needed
- Test Arch Linux without full commitment
- Safer than full replacement

### Disadvantages
- More complex setup
- Requires more storage space
- Slightly longer boot time
- Need to manage two systems

## Prerequisites

- Unlocked bootloader
- At least 20GB free space (for Arch Linux)
- Working Android installation
- Backed up data
- TWRP or similar custom recovery (recommended)

## Dual-Boot Methods

### Comparison

| Method | Difficulty | Boot Selection | Recommended |
|--------|-----------|----------------|-------------|
| Separate Boot Images | Easy | Manual (fastboot) | For testing |
| MultiROM | Hard | Boot menu | Advanced users |
| SD Card Boot | Easy | Automatic | Best for beginners |

## Method 1: Separate Boot Images

Boot Android or Linux by flashing different boot images.

### Setup

1. **Keep stock Android boot image:**
   ```bash
   # Already backed up during installation
   # Location: boot-stock.img
   ```

2. **Flash Arch Linux boot:**
   ```bash
   fastboot flash boot boot-yunluo.img
   ```

3. **Boot to Arch Linux:**
   ```bash
   fastboot reboot
   ```

### Switching to Android

```bash
# Reboot to fastboot
adb reboot bootloader

# Flash Android boot
fastboot flash boot boot-stock.img
fastboot reboot
```

### Switching to Arch Linux

```bash
# Reboot to fastboot
# (From Android: adb reboot bootloader)
# (From Arch: systemctl reboot --bootloader)

# Flash Linux boot
fastboot flash boot boot-yunluo.img
fastboot reboot
```

### Automation Script

Create a helper script on your PC:

```bash
#!/bin/bash
# dual-boot-switch.sh

if [ "$1" == "android" ]; then
    echo "Switching to Android..."
    fastboot flash boot boot-stock.img
    fastboot reboot
elif [ "$1" == "linux" ]; then
    echo "Switching to Arch Linux..."
    fastboot flash boot boot-yunluo.img
    fastboot reboot
else
    echo "Usage: $0 {android|linux}"
    exit 1
fi
```

Usage:
```bash
chmod +x dual-boot-switch.sh
./dual-boot-switch.sh android
./dual-boot-switch.sh linux
```

## Method 2: MultiROM (Advanced)

**Note**: MultiROM may not be available for this device yet. This is theoretical guidance.

### Concept

MultiROM is a multi-boot manager that:
- Shows boot menu on startup
- Stores multiple ROMs
- Allows boot selection without PC

### Installation

1. **Install TWRP recovery:**
   ```bash
   fastboot flash recovery twrp-yunluo.img
   ```

2. **Install MultiROM:**
   ```bash
   # Download MultiROM for your device (if available)
   # Flash in TWRP
   # Install MultiROM manager app
   ```

3. **Add Arch Linux as secondary ROM:**
   ```bash
   # In MultiROM manager:
   # 1. Add ROM
   # 2. Select "Generic Linux"
   # 3. Point to Arch rootfs
   # 4. Configure boot image
   ```

### Boot Menu

On boot, you'll see a menu:
- Android (Primary)
- Arch Linux (Secondary)
- Recovery

Use volume keys to select, power button to confirm.

## Method 3: SD Card Boot (Recommended)

Boot Arch Linux from SD card while keeping Android on internal storage.

### Advantages
- Easiest to set up
- Android untouched
- Can remove SD card to boot Android
- Safe to experiment

### Setup

1. **Prepare SD card:**
   
   See [INSTALLATION.md - Method 2](INSTALLATION.md#method-2-sd-card-installation)

2. **Create boot image for SD card:**

   ```bash
   # Build boot image with modified init
   # init should check for SD card first
   
   cat > initramfs/init << 'EOF'
   #!/bin/busybox sh
   
   mount -t proc none /proc
   mount -t sysfs none /sys
   mount -t devtmpfs none /dev
   
   # Try SD card first
   if mount -t ext4 /dev/mmcblk1p2 /mnt/root 2>/dev/null; then
       echo "Booting from SD card..."
   else
       # Fall back to internal storage
       mount -t ext4 /dev/mmcblk0p30 /mnt/root
       echo "Booting from internal storage..."
   fi
   
   exec switch_root /mnt/root /sbin/init
   EOF
   ```

3. **Flash the boot image:**
   ```bash
   fastboot flash boot boot-yunluo-sdcard.img
   ```

4. **Boot selection:**
   - **With SD card inserted**: Boots Arch Linux
   - **Without SD card**: Boots Android (if Android on internal storage)

### Hybrid Configuration

Keep Android on internal storage, Arch on SD card:

```
Internal Storage:
├── Android system (unchanged)
└── All Android partitions intact

SD Card:
├── /boot (FAT32, 512MB)
└── /root (ext4, remaining space)
    └── Arch Linux root filesystem
```

## Method 4: Shared Data Partition (Advanced)

Share a data partition between Android and Linux.

### Setup

1. **Create shared partition:**
   ```bash
   # From recovery or Linux
   mkfs.ext4 -L shared /dev/mmcblk0p31
   ```

2. **Mount in both systems:**

   **In Arch Linux** (`/etc/fstab`):
   ```
   /dev/mmcblk0p31  /mnt/shared  ext4  defaults  0  2
   ```

   **In Android**:
   - Use app like "BindFS" or modify init scripts

3. **Access files:**
   - Linux: `/mnt/shared/`
   - Android: `/storage/shared/` or `/data/shared/`

## Switching Between Systems

### From Android to Arch Linux

**Quick method (requires PC):**
```bash
adb reboot bootloader
fastboot flash boot boot-yunluo.img
fastboot reboot
```

**Without PC (using terminal app):**
```bash
su
dd if=/sdcard/boot-yunluo.img of=/dev/block/by-name/boot
reboot
```

### From Arch Linux to Android

**Quick method (requires PC):**
```bash
systemctl reboot --bootloader
# Then from PC:
fastboot flash boot boot-stock.img
fastboot reboot
```

**Without PC:**
```bash
su
dd if=/boot/boot-stock.img of=/dev/block/bootdevice/by-name/boot
reboot
```

### Using Recovery

**Boot to recovery:**
```bash
# From Android:
adb reboot recovery

# From Arch:
reboot recovery

# Or:
adb reboot bootloader
fastboot boot recovery.img
```

**Switch from recovery:**
- Flash desired boot image
- Reboot

## Boot Manager Script

Create a boot selection script in recovery:

```bash
#!/sbin/sh
# /sbin/bootmenu.sh

echo "Select OS:"
echo "1. Android"
echo "2. Arch Linux"
echo "3. Recovery"

read choice

case $choice in
    1)
        dd if=/data/media/0/boot-images/boot-android.img of=/dev/block/by-name/boot
        reboot
        ;;
    2)
        dd if=/data/media/0/boot-images/boot-linux.img of=/dev/block/by-name/boot
        reboot
        ;;
    3)
        reboot recovery
        ;;
    *)
        echo "Invalid choice"
        ;;
esac
```

## Backup Boot Images

Store boot images for easy switching:

### On Device
```bash
# Create directory
mkdir -p /data/media/0/boot-images

# Copy boot images
cp boot-stock.img /data/media/0/boot-images/
cp boot-yunluo.img /data/media/0/boot-images/
```

### Quick Switch Script

```bash
#!/bin/bash
# On-device script (requires root)

BOOT_IMAGES="/data/media/0/boot-images"
BOOT_DEV="/dev/block/by-name/boot"

case "$1" in
    android)
        dd if=$BOOT_IMAGES/boot-stock.img of=$BOOT_DEV
        echo "Switched to Android. Rebooting..."
        reboot
        ;;
    linux)
        dd if=$BOOT_IMAGES/boot-yunluo.img of=$BOOT_DEV
        echo "Switched to Arch Linux. Rebooting..."
        reboot
        ;;
    *)
        echo "Usage: $0 {android|linux}"
        exit 1
        ;;
esac
```

## Troubleshooting

### Can't Boot Either System

1. **Boot to fastboot:**
   - Hold Volume Down + Power

2. **Flash working boot image:**
   ```bash
   fastboot flash boot boot-stock.img
   fastboot reboot
   ```

### Wrong OS Boots

- Check which boot image is flashed:
  ```bash
  adb shell dd if=/dev/block/by-name/boot of=/sdcard/current-boot.img
  adb pull /sdcard/current-boot.img
  # Compare with known images
  ```

### Boot Loop After Switching

- Boot to recovery
- Check filesystem:
  ```bash
  e2fsck -f /dev/block/mmcblk0p30
  ```
- Reflash boot image

### SD Card Not Detected

1. Check if card is properly inserted
2. Verify card is formatted correctly:
   ```bash
   # In recovery or Linux
   fdisk -l /dev/mmcblk1
   ```
3. Rebuild boot image with proper SD card detection

### Storage Full

When dual-booting, storage can fill up quickly:

```bash
# Free up space in Android
# Clear cache, remove unused apps

# Free up space in Linux
pacman -Scc  # Clear package cache
journalctl --vacuum-size=50M  # Limit journal size
```

## Best Practices

1. **Always keep backups:**
   - Stock boot image
   - Important data
   - Partition layout

2. **Label your images:**
   ```bash
   mv boot.img boot-yunluo-v1.0.img
   mv boot-stock.img boot-android-miui-14.img
   ```

3. **Test before relying on dual-boot:**
   - Ensure you can switch both ways
   - Verify all hardware works in both systems

4. **Keep switching method available:**
   - Store boot images on PC
   - Keep fastboot cable handy
   - Know how to access recovery

## Limitations

- Can't run both systems simultaneously
- Boot switching requires reboot
- Some methods require PC connection
- Storage is split between systems

## Advanced: Boot Selection via Hardware

**Idea**: Use volume button during boot to select OS.

Requires custom bootloader or modified boot image:

```bash
# Pseudocode for init script
if [ volume_down_pressed ]; then
    # Boot Android
    switch_root /mnt/android
else
    # Boot Linux
    switch_root /mnt/linux
fi
```

Implementation requires:
- Custom init script
- Button detection in early boot
- Multiple root filesystems

## Resources

- TWRP for Redmi Pad: [XDA Thread]
- MultiROM Project: https://github.com/Tasssadar/multirom
- Android Boot Image Format: https://source.android.com/docs/core/architecture/bootloader

## Support

For dual-boot issues:
1. Check TROUBLESHOOTING.md
2. Ask in GitHub Issues
3. XDA Developers forum

---

**Remember**: Always maintain ability to return to stock Android in case of issues!
