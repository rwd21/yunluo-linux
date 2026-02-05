# Hardware Support Status

Current hardware support status for Arch Linux on Xiaomi Redmi Pad (yunluo).

## Legend

- ✅ **Working**: Fully functional
- 🟡 **Partial**: Works with limitations or requires manual configuration
- 🔴 **Not Working**: Currently not functional
- ❓ **Unknown**: Not yet tested
- 🚧 **In Progress**: Currently being worked on

## Overall Status: 🚧 Under Development

Last Updated: 2026-02-05

## Hardware Components

### Display
| Component | Status | Notes |
|-----------|--------|-------|
| LCD Panel (10.61" 1200x2000) | ❓ | Requires DRM/KMS driver configuration |
| Backlight Control | ❓ | May require custom ACPI/device tree configuration |
| Auto-brightness | ❓ | Depends on light sensor support |
| Resolution/Scaling | ❓ | Should work with proper X11/Wayland config |

**Implementation Notes:**
- Panel likely uses DSI interface
- May need custom panel driver or generic panel support
- Device tree configuration critical for display init

### Touch Input
| Component | Status | Notes |
|-----------|--------|-------|
| Touchscreen | ❓ | Requires MediaTek touchscreen driver |
| Multi-touch | ❓ | Depends on driver capabilities |
| Gesture Support | ❓ | Kernel + userspace configuration |
| Palm Rejection | ❓ | May require tuning |

**Implementation Notes:**
- Check `/dev/input/event*` for touchscreen device
- Use `evtest` to verify touch events
- Configure X11 input with xf86-input-evdev or libinput

### Wireless Connectivity

#### WiFi
| Component | Status | Notes |
|-----------|--------|-------|
| WiFi Chip (MediaTek) | ❓ | Requires mt76 driver and firmware |
| 2.4 GHz | ❓ | Check mt76 driver compatibility |
| 5 GHz | ❓ | Check mt76 driver compatibility |
| WiFi Direct | ❓ | Depends on driver support |

**Required Files:**
- Firmware: `/lib/firmware/mediatek/WIFI_RAM_CODE_*.bin`
- Configuration files from `/vendor/firmware/`

#### Bluetooth
| Component | Status | Notes |
|-----------|--------|-------|
| Bluetooth | ❓ | Requires MediaTek BT firmware |
| BLE | ❓ | Should work with bluez |
| Audio (A2DP) | ❓ | Requires PulseAudio configuration |

**Required Files:**
- Firmware: `/lib/firmware/mediatek/mt66*.bin`

### Audio
| Component | Status | Notes |
|-----------|--------|-------|
| Speaker Playback | ❓ | ALSA/UCM configuration needed |
| Headphone Jack | ❓ | Jack detection may need configuration |
| Microphone | ❓ | ALSA capture device |
| Volume Control | ❓ | Kernel mixer support required |

**Implementation Notes:**
- Use `aplay -l` to list playback devices
- Use `arecord -l` to list capture devices
- May need UCM (Use Case Manager) profiles

### Power Management
| Component | Status | Notes |
|-----------|--------|-------|
| Battery Detection | ❓ | Requires power_supply driver |
| Battery Percentage | ❓ | Kernel fuel gauge support |
| Charging Detection | ❓ | Check `/sys/class/power_supply/` |
| Charge Control | ❓ | May require custom implementation |
| Suspend/Sleep | ❓ | ARM PSCI support needed |
| Wake-up | ❓ | Device-specific configuration |
| CPU Frequency Scaling | ❓ | cpufreq driver for MT6789 |

**Implementation Notes:**
- Check kernel support for `mt6789-cpufreq`
- Configure power profiles with TLP or powertop

### Graphics/GPU
| Component | Status | Notes |
|-----------|--------|-------|
| Mali-G57 MC2 | ❓ | Panfrost driver recommended |
| 2D Acceleration | ❓ | Should work with DRM/KMS |
| 3D Acceleration | ❓ | Panfrost or blob driver |
| OpenGL ES | ❓ | Mesa with Panfrost |
| Vulkan | ❓ | Check Mesa/Panfrost support |
| Video Decode | ❓ | V4L2/vaapi support TBD |
| Video Encode | ❓ | V4L2 support TBD |

**Implementation Notes:**
- Panfrost is preferred open-source driver
- May need Mali proprietary blobs for full functionality
- Check Mesa version for latest Panfrost improvements

### Storage
| Component | Status | Notes |
|-----------|--------|-------|
| Internal Storage (eMMC/UFS) | ❓ | Standard block device support |
| SD Card Slot | ❓ | MMC/SD host controller driver |
| USB Storage (OTG) | ❓ | USB host mode support |
| TRIM/Discard | ❓ | Check filesystem support |

**Implementation Notes:**
- Internal storage likely at `/dev/mmcblk0`
- SD card likely at `/dev/mmcblk1`

### USB
| Component | Status | Notes |
|-----------|--------|-------|
| USB-C Port | ❓ | Type-C driver support |
| USB OTG | ❓ | Host and device mode |
| USB Host Mode | ❓ | For keyboards, mice, storage |
| USB Device Mode | ❓ | For ADB, MTP, etc. |
| USB-C Display | ❓ | DisplayPort Alt Mode (unlikely on tablet) |

**Implementation Notes:**
- Check for dual-role USB controller
- May need device tree configuration for role switching

### Sensors
| Component | Status | Notes |
|-----------|--------|-------|
| Accelerometer | ❓ | IIO subsystem driver |
| Gyroscope | ❓ | IIO subsystem driver |
| Light Sensor | ❓ | For auto-brightness |
| Proximity Sensor | ❓ | May not be present |
| Magnetometer | ❓ | Depends on hardware |
| Hall Sensor | ❓ | For smart covers (if present) |

**Implementation Notes:**
- Check `/sys/bus/iio/devices/`
- Use iio-sensor-proxy for desktop integration

### Cameras
| Component | Status | Notes |
|-----------|--------|-------|
| Rear Camera (8MP) | ❓ | Low priority, complex driver |
| Front Camera | ❓ | Low priority, complex driver |
| Camera Flash/Torch | ❓ | LED control |

**Implementation Notes:**
- Cameras are lowest priority
- May require proprietary ISP blobs
- V4L2 driver development needed

### Miscellaneous
| Component | Status | Notes |
|-----------|--------|-------|
| LED Indicators | ❓ | Check `/sys/class/leds/` |
| Vibration Motor | ❓ | PWM or GPIO control |
| Buttons (Power, Volume) | ❓ | GPIO keys driver |

## SoC-Specific Features

### MediaTek Helio G99 (MT6789)
| Feature | Status | Notes |
|---------|--------|-------|
| CPU (Cortex-A76/A55) | ❓ | Should work with ARM64 kernel |
| ARM TrustZone | ❓ | May affect some features |
| MediaTek APU | 🔴 | AI processor - likely unsupported |
| MediaTek ISP | 🔴 | Image processor - proprietary |
| Hardware Crypto | ❓ | Check ARM crypto extensions |

## Software Stack Status

### Kernel
- **Target Version**: Linux 6.6+ (mainline)
- **Current Status**: ❓ Not yet built
- **Required Patches**: Device tree, panel drivers, MediaTek-specific drivers

### Display Server
- **X11**: ❓ Planned (recommended initially)
- **Wayland**: ❓ Future consideration

### Desktop Environments
| DE | Status | Notes |
|----|--------|-------|
| XFCE | ❓ | Recommended - lightweight |
| LXQt | ❓ | Alternative lightweight option |
| MATE | ❓ | Good touch support |
| KDE Plasma Mobile | ❓ | Touch-optimized, heavier |
| GNOME | ❓ | Heavy, not recommended |

### Boot Process
- **Bootloader**: ❓ Using Android bootloader chain
- **Initramfs**: ❓ To be created
- **Boot Time**: ❓ TBD

## Performance Expectations

| Metric | Expected | Notes |
|--------|----------|-------|
| Boot Time | 30-60s | Depends on optimization |
| UI Responsiveness | Good | With proper GPU drivers |
| Battery Life | 6-10h | Depends on power management |
| Thermal Management | TBD | May need tuning |

## Testing Checklist

### Phase 1: Basic Functionality
- [ ] Device boots to login prompt
- [ ] Display shows output
- [ ] Can login as root
- [ ] Internal storage accessible
- [ ] USB connection works
- [ ] Power button works
- [ ] Volume buttons work

### Phase 2: Essential Hardware
- [ ] Touch input responds
- [ ] Multi-touch works
- [ ] WiFi connects
- [ ] Internet connectivity works
- [ ] Bluetooth pairs with device
- [ ] Audio plays through speakers
- [ ] Headphone jack works
- [ ] Battery percentage displays
- [ ] Charging detection works

### Phase 3: Advanced Features
- [ ] GPU acceleration works
- [ ] Desktop environment runs smoothly
- [ ] Suspend/resume works
- [ ] Sensors provide data
- [ ] CPU frequency scaling works
- [ ] Thermal management prevents overheating

### Phase 4: Optional Features
- [ ] SD card detection
- [ ] USB OTG works
- [ ] Cameras function
- [ ] Dual-boot with Android works

## Known Issues

### Critical
- None yet (project in early stages)

### High Priority
- Device tree configuration needs to be created from scratch
- Display driver compatibility unknown
- WiFi/BT firmware extraction required

### Medium Priority
- Power management optimization needed
- Audio configuration may be complex
- Touch calibration may be needed

### Low Priority
- Camera support unlikely in initial release
- Some sensors may not work initially

## Firmware Requirements

Required firmware files (to be extracted from Android):

```
/lib/firmware/
├── mediatek/
│   ├── WIFI_RAM_CODE_MT6789.bin
│   ├── WIFI_MT6789.bin
│   ├── BT_RAM_CODE_MT6789.bin
│   └── scp.img
├── mali/
│   └── g57_*.bin (if needed)
└── regulatory.db (WiFi regulatory)
```

## Development Priorities

### Milestone 1: Basic Boot (Critical)
1. Kernel compilation with basic drivers
2. Device tree configuration
3. Boot image creation
4. Successful boot to shell

### Milestone 2: Display and Input (High)
1. Display output working
2. Touchscreen functional
3. Basic framebuffer console

### Milestone 3: Connectivity (High)
1. WiFi driver and firmware
2. Network connectivity
3. SSH access

### Milestone 4: Desktop Environment (Medium)
1. X11 server running
2. Lightweight DE installed
3. Touch-friendly UI

### Milestone 5: Power Management (Medium)
1. Battery monitoring
2. Charging detection
3. CPU frequency scaling
4. Suspend/resume (if possible)

### Milestone 6: Audio and Additional Features (Low)
1. Audio playback
2. Bluetooth connectivity
3. GPU acceleration
4. Sensors

## Contributing Hardware Tests

If you're testing this on your device, please report:

1. Hardware component you tested
2. Current status (working/partial/not working)
3. Error messages (if any)
4. Kernel version used
5. Any special configuration needed

File issues at: https://github.com/rwd21/yunluo-linux/issues

## References

- PostmarketOS Device Support: https://wiki.postmarketos.org/wiki/Devices
- Linux Kernel MT6789 Support Status
- Arch Linux ARM Hardware Compatibility

---

**Note**: This is a living document that will be updated as hardware support improves. Last major update: 2026-02-05
