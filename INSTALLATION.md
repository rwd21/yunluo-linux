# Installation Guide - Arch Linux on Redmi Pad (yunluo)

Complete step-by-step guide for installing native Arch Linux on the Xiaomi Redmi Pad.

## ⚠️ WARNING

**This process will:**
- Void your device warranty
- Potentially brick your device if done incorrectly
- Erase all data on your device
- Require technical knowledge

**Before proceeding:**
- Backup ALL data from your device
- Charge your device to at least 80%
- Read this guide completely before starting
- Have access to a recovery plan

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Backup Procedures](#backup-procedures)
3. [Unlocking the Bootloader](#unlocking-the-bootloader)
4. [Installation Methods](#installation-methods)
5. [Method 1: Internal Storage Installation](#method-1-internal-storage-installation)
6. [Method 2: SD Card Installation](#method-2-sd-card-installation)
7. [First Boot and Configuration](#first-boot-and-configuration)
8. [Post-Installation Setup](#post-installation-setup)
9. [Troubleshooting](#troubleshooting)

## Prerequisites

### Hardware Requirements
- Xiaomi Redmi Pad (yunluo)
- USB-C cable (high quality, data transfer capable)
- Computer running Linux, macOS, or Windows
- SD card (optional, for Method 2) - minimum 16GB, Class 10 or better

### Software Requirements

**On Linux:**
```bash
# Install Android tools
sudo pacman -S android-tools  # Arch Linux
sudo apt install android-tools-adb android-tools-fastboot  # Debian/Ubuntu
```

**On Windows:**
- Download Android Platform Tools: https://developer.android.com/studio/releases/platform-tools
- Extract to a folder and add to PATH

**On macOS:**
```bash
brew install android-platform-tools
```

### Download Required Files

```bash
# Clone repository
git clone https://github.com/rwd21/yunluo-linux.git
cd yunluo-linux

# Download pre-built images (if available) or build from source
# See BUILDING.md for build instructions
```

## Backup Procedures

### 1. Backup Android Data

```bash
# Enable USB debugging in Android Developer Options
# Connect device via USB

# Backup apps and data
adb backup -all -apk -shared -system

# Save backup file to safe location
```

### 2. Backup Important Partitions

```bash
# Boot into recovery or use ADB root
adb root

# Backup boot partition
adb pull /dev/block/by-name/boot boot-stock.img

# Backup recovery partition (if exists)
adb pull /dev/block/by-name/recovery recovery-stock.img

# Backup persist partition (contains WiFi/BT MAC, etc.)
adb pull /dev/block/by-name/persist persist.img

# List all partitions for reference
adb shell ls -l /dev/block/by-name/ > partition-layout.txt
```

### 3. Save Stock ROM

Download the official MIUI ROM for your device:
- Visit: https://xiaomifirmwareupdater.com/
- Search for "yunluo" or "Redmi Pad"
- Download the latest stable ROM for recovery

## Unlocking the Bootloader

### 1. Enable Developer Options

On your Android device:
1. Go to Settings → About tablet
2. Tap "MIUI version" 7 times
3. Developer options will appear in Settings

### 2. Enable OEM Unlocking and USB Debugging

1. Go to Settings → Developer options
2. Enable "OEM unlocking"
3. Enable "USB debugging"

### 3. Link Mi Account

1. Go to Settings → Developer options → Mi Unlock status
2. Link your Mi account to the device
3. Wait 7 days (required by Xiaomi)

### 4. Unlock Using Mi Unlock Tool

**On Windows:**
```bash
# Download Mi Unlock Tool
# https://en.miui.com/unlock/download_en.html

1. Extract and run MiFlashUnlock.exe
2. Sign in with your Mi account
3. Boot device to fastboot mode (Volume Down + Power)
4. Connect device to PC
5. Click "Unlock" in the tool
6. Wait for the process to complete (device will reboot)
```

**Alternative (using fastboot):**
```bash
# Boot to fastboot
adb reboot bootloader

# Check if device is detected
fastboot devices

# Attempt unlock (may not work on all devices)
fastboot oem unlock
# or
fastboot flashing unlock

# Confirm on device screen
```

### 5. Verify Bootloader Status

```bash
# Boot to fastboot
fastboot devices

# Check unlock status
fastboot getvar unlocked
# Should return: unlocked: yes
```

## Installation Methods

Choose one of the following methods:

- **Method 1**: Install to internal storage (recommended, faster performance)
- **Method 2**: Install to SD card (safer, allows easy dual-boot)

## Method 1: Internal Storage Installation

### Step 1: Partition the Internal Storage

⚠️ **This will erase all data!**

```bash
# Boot into fastboot
adb reboot bootloader

# Boot into temporary recovery (if available)
fastboot boot recovery.img

# Or boot into custom recovery (TWRP if available)
# fastboot flash recovery twrp-yunluo.img
# fastboot boot twrp-yunluo.img
```

**Partitioning scheme:**

```bash
# In recovery shell or via ADB
adb shell

# Identify storage device (usually /dev/block/mmcblk0)
ls -l /dev/block/by-name/

# Create partitions (example - adjust sizes as needed)
# WARNING: This erases all data!
parted /dev/block/mmcblk0

# Example partition layout:
# p1-p29: Android partitions (keep as-is)
# p30: Linux root (20GB)
# p31: Linux home (remaining space)

# Create ext4 filesystem for root
mkfs.ext4 -L archlinux-root /dev/block/mmcblk0p30

# Create ext4 filesystem for home
mkfs.ext4 -L archlinux-home /dev/block/mmcblk0p31
```

### Step 2: Flash Boot Image

```bash
# From fastboot mode
fastboot flash boot build/boot-yunluo.img

# Verify
fastboot getvar partition-size:boot
```

### Step 3: Install Root Filesystem

```bash
# Boot into recovery
fastboot boot recovery.img

# Push rootfs image
adb push build/rootfs-yunluo.img /tmp/

# Mount root partition
adb shell mount /dev/block/mmcblk0p30 /mnt

# Extract rootfs
adb shell "cd /mnt && tar -xpf /tmp/rootfs-yunluo.img"

# Install firmware
adb push firmware/ /mnt/lib/firmware/

# Unmount
adb shell umount /mnt
```

### Step 4: Reboot

```bash
# Reboot to Arch Linux
adb reboot

# Or from fastboot
fastboot reboot
```

## Method 2: SD Card Installation

### Step 1: Prepare SD Card

**On Linux:**

```bash
# Insert SD card (e.g., /dev/sdb)
# WARNING: Double-check device name!
lsblk

# Partition SD card
sudo parted /dev/sdb

# Create partition table
(parted) mklabel gpt

# Create boot partition (512MB)
(parted) mkpart primary fat32 1MiB 513MiB
(parted) set 1 boot on

# Create root partition (remaining space)
(parted) mkpart primary ext4 513MiB 100%
(parted) quit

# Format partitions
sudo mkfs.vfat -F32 -n BOOT /dev/sdb1
sudo mkfs.ext4 -L ARCHROOT /dev/sdb2

# Mount partitions
mkdir -p /tmp/sdcard/{boot,root}
sudo mount /dev/sdb2 /tmp/sdcard/root
sudo mount /dev/sdb1 /tmp/sdcard/boot

# Extract rootfs
sudo tar -xpf build/rootfs-yunluo.img -C /tmp/sdcard/root

# Copy kernel and DTB to boot partition
sudo cp kernel/linux-6.6/arch/arm64/boot/Image.gz /tmp/sdcard/boot/
sudo cp kernel/linux-6.6/arch/arm64/boot/dts/mediatek/mt6789-yunluo.dtb /tmp/sdcard/boot/

# Copy firmware
sudo cp -r firmware/ /tmp/sdcard/root/lib/firmware/

# Unmount
sudo umount /tmp/sdcard/{boot,root}
```

### Step 2: Flash Boot Image

```bash
# Flash boot image that supports SD card boot
fastboot flash boot build/boot-yunluo-sdcard.img
fastboot reboot
```

## First Boot and Configuration

### 1. First Boot

After rebooting, you should see:
1. Boot screen (if configured)
2. Kernel messages
3. Login prompt

### 2. Initial Login

```
Default credentials:
Username: root
Password: root

OR

Username: alarm
Password: alarm
```

### 3. Basic Configuration

```bash
# Set root password
passwd root

# Create user account
useradd -m -G wheel,audio,video,storage -s /bin/bash yourusername
passwd yourusername

# Configure sudo
EDITOR=vim visudo
# Uncomment: %wheel ALL=(ALL) ALL

# Set timezone
timedatectl set-timezone America/New_York

# Set locale
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set hostname
echo "yunluo-arch" > /etc/hostname

# Configure hosts
cat >> /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   yunluo-arch.localdomain yunluo-arch
EOF
```

### 4. Network Configuration

```bash
# Start NetworkManager
systemctl start NetworkManager
systemctl enable NetworkManager

# Connect to WiFi (if WiFi is working)
nmcli device wifi list
nmcli device wifi connect "SSID" password "PASSWORD"

# Or configure manually
# vim /etc/systemd/network/wlan0.network
```

### 5. Update System

```bash
# Initialize pacman keyring (if needed)
pacman-key --init
pacman-key --populate archlinuxarm

# Update system
pacman -Syu
```

## Post-Installation Setup

### 1. Enable SSH (for remote access)

```bash
# Install and enable SSH
pacman -S openssh
systemctl enable sshd
systemctl start sshd

# Find IP address
ip addr show
```

### 2. Install Desktop Environment

**XFCE (Lightweight, recommended):**

```bash
pacman -S xfce4 xfce4-goodies lightdm lightdm-gtk-greeter
systemctl enable lightdm
```

**LXQt:**

```bash
pacman -S lxqt breeze-icons sddm
systemctl enable sddm
```

### 3. Install Essential Software

```bash
# Browser
pacman -S firefox

# On-screen keyboard
pacman -S onboard

# Terminal emulator
pacman -S xfce4-terminal

# File manager (if not installed with DE)
pacman -S thunar

# Text editor
pacman -S gedit vim

# Audio
pacman -S pulseaudio pulseaudio-alsa pavucontrol
```

### 4. Configure Touch Input

```bash
# Install input drivers
pacman -S xf86-input-evdev

# Create xorg configuration
cat > /etc/X11/xorg.conf.d/99-touchscreen.conf << EOF
Section "InputClass"
    Identifier "touchscreen"
    MatchIsTouchscreen "on"
    Driver "evdev"
    Option "InvertY" "true"
    Option "InvertX" "false"
EndSection
EOF
```

### 5. Configure Display Rotation

```bash
# For portrait mode
xrandr --output DSI-1 --rotate left

# Add to autostart
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/rotation.desktop << EOF
[Desktop Entry]
Type=Application
Name=Display Rotation
Exec=xrandr --output DSI-1 --rotate left
EOF
```

### 6. Setup Auto-login (Optional)

For LightDM:

```bash
# Edit /etc/lightdm/lightdm.conf
[Seat:*]
autologin-user=yourusername
autologin-session=xfce
```

## Dual-Boot Setup (Optional)

See [DUAL-BOOT.md](DUAL-BOOT.md) for detailed instructions on:
- Installing alongside Android
- Using MultiROM
- Creating boot menu
- Switching between systems

## Troubleshooting

### Device Won't Boot

1. Boot into fastboot mode (Volume Down + Power)
2. Flash stock boot image:
   ```bash
   fastboot flash boot boot-stock.img
   fastboot reboot
   ```

### Stuck at Boot Logo

1. Check kernel command line in boot.img
2. Verify root partition is correct
3. Check initramfs

### Display Not Working

1. Check kernel logs:
   ```bash
   dmesg | grep drm
   ```
2. Verify DRM/KMS drivers are enabled
3. Check device tree configuration

### Touch Not Working

1. Check input devices:
   ```bash
   ls /dev/input/
   evtest /dev/input/event*
   ```
2. Verify touchscreen driver is loaded

### WiFi Not Working

1. Check firmware files exist:
   ```bash
   ls /lib/firmware/wlan/
   ```
2. Load WiFi module:
   ```bash
   modprobe mt76_sdio
   ```
3. Check dmesg for errors

### No Audio

1. Check ALSA:
   ```bash
   aplay -l
   alsamixer
   ```
2. Unmute channels
3. Verify PulseAudio is running

## Recovery Procedures

### Restore Android

```bash
# Boot to fastboot
# Flash all stock partitions using MiFlash tool
# Or use fastboot:
fastboot flash boot boot-stock.img
fastboot flash system system-stock.img
# ... (flash all backed-up partitions)
fastboot reboot
```

### Complete Factory Reset

Use official Xiaomi flash tools and stock ROM downloaded earlier.

## Next Steps

- See [HARDWARE.md](HARDWARE.md) for hardware support status
- See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues
- Join the community for support

## Support

- GitHub Issues: https://github.com/rwd21/yunluo-linux/issues
- XDA Developers: [Link to thread]
- Matrix/Discord: [Link to chat]

## Credits

- Arch Linux ARM community
- PostmarketOS developers
- MediaTek kernel developers
- All contributors to this project
