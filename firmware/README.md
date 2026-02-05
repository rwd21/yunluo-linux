# Firmware Files for Redmi Pad

## ⚠️ Important Notice

This directory should contain firmware files extracted from your device's stock Android ROM.

**Do not distribute these files publicly** - they are proprietary and copyrighted.

## Required Firmware

### WiFi
- `wifi/WIFI_RAM_CODE_MT6789.bin`
- `wifi/WIFI_MT6789.bin`

### Bluetooth
- `bluetooth/mt66xx_bt.bin`
- `bluetooth/BT_RAM_CODE_MT6789.bin`

### GPU (if needed)
- `gpu/mali_*.bin`

### Miscellaneous
- `misc/scp.img` - System Control Processor firmware

## Extraction

Use the provided script to extract firmware:

```bash
# From connected device
./scripts/extract-firmware.sh --from-device

# From ROM file
./scripts/extract-firmware.sh path/to/rom.zip
```

## Installation

Firmware files are automatically copied during rootfs build:

```bash
make rootfs  # Includes firmware in build/rootfs-yunluo.tar.gz
```

Or copy manually to installed system:

```bash
sudo cp -r firmware/* /path/to/rootfs/lib/firmware/
```

## License

These firmware files are proprietary. Use only on devices you own.
Redistribution may violate copyright laws.
