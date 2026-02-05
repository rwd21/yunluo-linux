# Troubleshooting Guide

Common issues and solutions for running Arch Linux on Redmi Pad (yunluo).

## Table of Contents

1. [Boot Issues](#boot-issues)
2. [Display Problems](#display-problems)
3. [Input Issues](#input-issues)
4. [Network Connectivity](#network-connectivity)
5. [Audio Problems](#audio-problems)
6. [Power Management](#power-management)
7. [Performance Issues](#performance-issues)
8. [Build Errors](#build-errors)
9. [Installation Problems](#installation-problems)
10. [Recovery Procedures](#recovery-procedures)

---

## Boot Issues

### Device Won't Boot / Stuck at Logo

**Symptoms:**
- Device stuck at Xiaomi logo
- Black screen after boot
- Bootloop

**Diagnosis:**

```bash
# Boot into fastboot mode
# Hold Volume Down + Power button

# Check if fastboot is accessible
fastboot devices

# Check bootloader variables
fastboot getvar all
```

**Solutions:**

1. **Flash stock boot image:**
   ```bash
   fastboot flash boot boot-stock.img
   fastboot reboot
   ```

2. **Check kernel command line:**
   ```bash
   # Extract boot.img to check cmdline
   unpackbootimg -i boot-yunluo.img
   cat boot.img-cmdline
   ```
   
   Ensure it contains:
   - `console=tty0` or `console=ttyMT0`
   - Correct root device (e.g., `root=/dev/mmcblk0p30`)
   - `rootwait` parameter

3. **Verify initramfs:**
   ```bash
   # Extract and check initramfs
   gunzip -c initramfs.cpio.gz | cpio -i
   # Verify init script is executable
   ls -l init
   ```

4. **Check device tree:**
   ```bash
   # Ensure DTB is correct for your device
   fdtdump mt6789-yunluo.dtb
   ```

### Kernel Panic on Boot

**Symptoms:**
- Kernel panic message
- System halts after kernel loads

**Diagnosis:**

Check panic message via UART (if accessible) or last kmsg.

**Solutions:**

1. **Fix root filesystem path:**
   - Kernel command line must match actual partition
   - Check with: `ls -l /dev/block/by-name/`

2. **Missing drivers in initramfs:**
   - Ensure ext4/f2fs modules are included
   - Verify block device drivers are built-in or in initramfs

3. **Rebuild kernel with correct config:**
   ```bash
   # Enable essential options
   CONFIG_EXT4_FS=y
   CONFIG_F2FS_FS=y
   CONFIG_DEVTMPFS=y
   CONFIG_DEVTMPFS_MOUNT=y
   ```

### Infinite Boot Loop

**Solutions:**

1. **Boot into recovery:**
   ```bash
   fastboot boot recovery.img
   ```

2. **Check filesystem:**
   ```bash
   adb shell
   e2fsck -f /dev/block/mmcblk0p30
   ```

3. **Verify fstab:**
   ```bash
   cat /etc/fstab
   # Ensure UUIDs or device paths are correct
   ```

---

## Display Problems

### No Display Output / Black Screen

**Diagnosis:**

```bash
# SSH into device (if network works)
ssh root@device-ip

# Check display driver
dmesg | grep -i drm
dmesg | grep -i panel

# Check framebuffer devices
ls /dev/fb*

# Check display mode
cat /sys/class/drm/card0/card0-DSI-1/status
```

**Solutions:**

1. **Load display modules:**
   ```bash
   modprobe drm
   modprobe drm_kms_helper
   modprobe panel_simple
   ```

2. **Check X11 configuration:**
   ```bash
   # Test with startx
   startx
   
   # Check X11 logs
   cat /var/log/Xorg.0.log
   ```

3. **Verify device tree includes display:**
   ```bash
   # Check for display node in DTB
   dtc -I dtb -O dts mt6789-yunluo.dtb | grep -A 20 "display"
   ```

### Display Upside Down / Wrong Orientation

**Solutions:**

1. **Using xrandr:**
   ```bash
   # List outputs
   xrandr
   
   # Rotate display
   xrandr --output DSI-1 --rotate left    # Portrait
   xrandr --output DSI-1 --rotate right   # Reverse portrait
   xrandr --output DSI-1 --rotate inverted # Upside down
   xrandr --output DSI-1 --rotate normal   # Default
   ```

2. **Persistent configuration:**
   ```bash
   # Create autostart script
   mkdir -p ~/.config/autostart
   cat > ~/.config/autostart/rotation.desktop << EOF
   [Desktop Entry]
   Type=Application
   Name=Display Rotation
   Exec=xrandr --output DSI-1 --rotate left
   EOF
   ```

3. **Kernel parameter (framebuffer):**
   ```bash
   # Add to kernel cmdline
   fbcon=rotate:1  # 1=90°, 2=180°, 3=270°
   ```

### Backlight Not Working

**Diagnosis:**

```bash
# Check backlight devices
ls /sys/class/backlight/

# Check current brightness
cat /sys/class/backlight/*/brightness
cat /sys/class/backlight/*/max_brightness
```

**Solutions:**

```bash
# Manually set brightness
echo 100 > /sys/class/backlight/backlight-dsi/brightness

# Add user to video group
usermod -a -G video username

# Install brightness control tool
pacman -S brightnessctl
brightnessctl set 50%
```

---

## Input Issues

### Touchscreen Not Working

**Diagnosis:**

```bash
# List input devices
ls /dev/input/

# Test input events
evtest
# Select touchscreen device (usually event2 or event3)

# Check loaded modules
lsmod | grep touch

# Check kernel messages
dmesg | grep -i touch
dmesg | grep -i input
```

**Solutions:**

1. **Load touchscreen driver:**
   ```bash
   modprobe mtk_ts
   # or the appropriate MediaTek touch driver
   ```

2. **Configure X11:**
   ```bash
   cat > /etc/X11/xorg.conf.d/99-touchscreen.conf << EOF
   Section "InputClass"
       Identifier "touchscreen"
       MatchIsTouchscreen "on"
       Driver "libinput"
       Option "InvertY" "false"
       Option "InvertX" "false"
   EndSection
   EOF
   ```

3. **Calibrate touchscreen:**
   ```bash
   pacman -S xinput_calibrator
   xinput_calibrator
   # Follow on-screen instructions
   ```

### Touch Inverted or Mirrored

**Solutions:**

```bash
# Using xinput
xinput list
xinput set-prop "device-name" "Coordinate Transformation Matrix" -1 0 1 0 -1 1 0 0 1

# Or in xorg.conf
cat > /etc/X11/xorg.conf.d/99-touchscreen.conf << EOF
Section "InputClass"
    Identifier "touchscreen"
    MatchIsTouchscreen "on"
    Driver "libinput"
    Option "TransformationMatrix" "-1 0 1 0 -1 1 0 0 1"
EndSection
EOF
```

### Volume/Power Buttons Not Working

**Diagnosis:**

```bash
# Check GPIO keys
evtest /dev/input/event0  # Usually event0 or event1

# Check kernel support
dmesg | grep gpio-keys
```

**Solutions:**

```bash
# Verify device tree includes button definitions
# May need to add to device tree:
gpio-keys {
    compatible = "gpio-keys";
    power {
        label = "Power Button";
        gpios = <&pio 42 1>;
        linux,code = <116>;  /* KEY_POWER */
    };
};
```

---

## Network Connectivity

### WiFi Not Working

**Diagnosis:**

```bash
# Check WiFi interface
ip link show
iw dev

# Check for WiFi driver
lsmod | grep mt76
dmesg | grep mt76

# Check firmware loading
dmesg | grep firmware

# List firmware files
ls -R /lib/firmware/mediatek/
```

**Solutions:**

1. **Load WiFi driver:**
   ```bash
   modprobe mt76_sdio
   # or
   modprobe mt7921s
   ```

2. **Install firmware:**
   ```bash
   # Copy from Android system
   adb pull /vendor/firmware/WIFI*.bin /lib/firmware/mediatek/
   ```

3. **Manual network setup:**
   ```bash
   # Bring up interface
   ip link set wlan0 up
   
   # Scan networks
   iw dev wlan0 scan | grep SSID
   
   # Connect using NetworkManager
   nmcli device wifi connect "SSID" password "PASSWORD"
   
   # Or using wpa_supplicant
   wpa_passphrase "SSID" "PASSWORD" > /etc/wpa_supplicant/wpa_supplicant.conf
   wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf
   dhcpcd wlan0
   ```

4. **Check regulatory domain:**
   ```bash
   iw reg get
   iw reg set US  # or your country code
   ```

### WiFi Connects but No Internet

**Diagnosis:**

```bash
# Check IP address
ip addr show wlan0

# Check routing
ip route

# Check DNS
cat /etc/resolv.conf

# Test connectivity
ping -c 4 8.8.8.8
ping -c 4 google.com
```

**Solutions:**

```bash
# Request DHCP lease
dhcpcd wlan0

# Add DNS servers manually
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf

# Restart NetworkManager
systemctl restart NetworkManager
```

### Bluetooth Not Working

**Diagnosis:**

```bash
# Check Bluetooth service
systemctl status bluetooth

# Check Bluetooth device
hciconfig -a

# Check firmware
dmesg | grep -i bluetooth
```

**Solutions:**

```bash
# Install bluez
pacman -S bluez bluez-utils

# Start Bluetooth service
systemctl start bluetooth
systemctl enable bluetooth

# Load firmware (extract from Android)
# Copy to /lib/firmware/mediatek/

# Initialize Bluetooth
bluetoothctl
# power on
# agent on
# scan on
```

---

## Audio Problems

### No Sound Output

**Diagnosis:**

```bash
# List audio devices
aplay -l
aplay -L

# Check ALSA mixer
alsamixer

# Check PulseAudio
pactl info
pactl list sinks
```

**Solutions:**

1. **Unmute channels:**
   ```bash
   # Using alsamixer
   alsamixer
   # Press M to unmute (MM means muted)
   
   # Using amixer
   amixer set Master unmute
   amixer set Master 100%
   amixer set Speaker unmute
   ```

2. **Install audio stack:**
   ```bash
   pacman -S alsa-utils pulseaudio pulseaudio-alsa pavucontrol
   pulseaudio --start
   ```

3. **Test audio:**
   ```bash
   speaker-test -t wav -c 2
   aplay /usr/share/sounds/alsa/Front_Center.wav
   ```

4. **Configure default device:**
   ```bash
   # Create ALSA config
   cat > ~/.asoundrc << EOF
   defaults.pcm.card 0
   defaults.ctl.card 0
   EOF
   ```

### Headphone Jack Not Working

**Solutions:**

```bash
# Check jack detection
amixer contents | grep -i jack

# May need UCM profile for jack switching
# Check /usr/share/alsa/ucm2/
```

---

## Power Management

### Battery Not Detected

**Diagnosis:**

```bash
# Check power supply
ls /sys/class/power_supply/
cat /sys/class/power_supply/battery/capacity
cat /sys/class/power_supply/battery/status

# Check kernel support
dmesg | grep power_supply
dmesg | grep battery
```

**Solutions:**

```bash
# Verify battery driver is loaded
modprobe mt6360_charger  # or appropriate driver

# Check device tree for battery/charger nodes
```

### Suspend/Resume Not Working

**Diagnosis:**

```bash
# Test suspend
systemctl suspend

# Check suspend logs
journalctl -b | grep suspend
dmesg | grep -i suspend
```

**Solutions:**

```bash
# May not be supported yet on tablet
# Requires proper PSCI implementation
# Check kernel config:
CONFIG_ARM_PSCI=y
CONFIG_SUSPEND=y
CONFIG_PM=y
```

### Overheating

**Solutions:**

```bash
# Check temperatures
cat /sys/class/thermal/thermal_zone*/temp

# Install thermal monitoring
pacman -S lm_sensors
sensors

# Monitor CPU frequency
watch -n 1 "cat /proc/cpuinfo | grep MHz"

# Limit CPU frequency
echo 1800000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
```

---

## Performance Issues

### Slow UI / Laggy Display

**Solutions:**

1. **Check GPU acceleration:**
   ```bash
   glxinfo | grep -i "direct rendering"
   glxinfo | grep -i "opengl"
   ```

2. **Enable Panfrost:**
   ```bash
   # Ensure Panfrost driver is loaded
   lsmod | grep panfrost
   modprobe panfrost
   ```

3. **Reduce desktop effects:**
   - Use lightweight DE (XFCE, LXQt)
   - Disable compositing
   - Reduce animations

4. **Check I/O performance:**
   ```bash
   hdparm -Tt /dev/mmcblk0p30
   ```

### High CPU Usage

**Diagnosis:**

```bash
# Monitor processes
htop

# Check what's using CPU
ps aux --sort=-%cpu | head
```

---

## Build Errors

### Kernel Build Fails

**Solutions:**

```bash
# Clean and rebuild
make ARCH=arm64 clean
make ARCH=arm64 mrproper

# Check toolchain
aarch64-linux-gnu-gcc --version

# Verify config
make ARCH=arm64 menuconfig
```

### Cross-compilation Issues

```bash
# Set environment variables explicitly
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export KBUILD_BUILD_USER=builder
export KBUILD_BUILD_HOST=build-host
```

---

## Installation Problems

### Fastboot Not Detecting Device

**Solutions:**

```bash
# Linux: Check udev rules
cat > /etc/udev/rules.d/51-android.rules << EOF
SUBSYSTEM=="usb", ATTR{idVendor}=="2717", MODE="0666", GROUP="plugdev"
EOF
sudo udevadm control --reload-rules

# Verify device in fastboot
lsusb | grep -i xiaomi

# Try different USB cable or port
```

### Cannot Flash Partitions

```bash
# Check bootloader unlock status
fastboot getvar unlocked

# Check partition list
fastboot getvar all | grep partition

# Use correct partition name
fastboot flash boot_a boot.img  # For A/B devices
fastboot flash boot boot.img     # For non-A/B
```

---

## Recovery Procedures

### Soft Brick Recovery

```bash
# Boot into fastboot
# Flash stock boot
fastboot flash boot boot-stock.img
fastboot reboot
```

### Hard Brick Recovery

1. Download official MIUI ROM
2. Use MiFlash tool (Windows)
3. Flash in EDL (Emergency Download) mode
4. See XDA forum for device-specific EDL instructions

### Backup Important Data

```bash
# Before risky operations:
adb pull /sdcard backup/
fastboot boot recovery.img
adb shell
tar czf /sdcard/backup.tar.gz /data/media/0
```

---

## Getting Help

### Collect Diagnostic Information

```bash
# Create a diagnostic report
cat > /tmp/diagnostic.sh << 'EOF'
#!/bin/bash
echo "=== System Info ===" > ~/diagnostic.txt
uname -a >> ~/diagnostic.txt
echo -e "\n=== Kernel Messages ===" >> ~/diagnostic.txt
dmesg >> ~/diagnostic.txt
echo -e "\n=== Loaded Modules ===" >> ~/diagnostic.txt
lsmod >> ~/diagnostic.txt
echo -e "\n=== Hardware Info ===" >> ~/diagnostic.txt
lspci >> ~/diagnostic.txt 2>/dev/null || echo "lspci not available"
lsusb >> ~/diagnostic.txt 2>/dev/null || echo "lsusb not available"
echo -e "\n=== Network Info ===" >> ~/diagnostic.txt
ip addr >> ~/diagnostic.txt
echo -e "\n=== Audio Info ===" >> ~/diagnostic.txt
aplay -l >> ~/diagnostic.txt 2>&1
EOF

chmod +x /tmp/diagnostic.sh
/tmp/diagnostic.sh
```

### Report Issues

When reporting issues, include:
1. Device model and variant
2. Kernel version (`uname -a`)
3. Steps to reproduce
4. Relevant log excerpts
5. What you've already tried

Submit at: https://github.com/rwd21/yunluo-linux/issues

---

## Additional Resources

- XDA Developers Redmi Pad Forum
- PostmarketOS Wiki: https://wiki.postmarketos.org/
- Arch Linux ARM Forums: https://archlinuxarm.org/forum
- MediaTek Developer Resources

---

**Note**: This document will be updated as new issues and solutions are discovered.
