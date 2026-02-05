# Patches for Linux Kernel

This directory contains kernel patches for Redmi Pad (yunluo) support.

## Patch Categories

### Device Tree Patches
- Add device tree for MT6789-yunluo
- Configure display panel
- Add touchscreen support
- Configure WiFi/BT interfaces

### Driver Patches
- MediaTek display driver improvements
- Touchscreen driver patches
- WiFi/BT firmware loading
- Audio codec support

### Platform Patches
- MT6789 SoC support
- Power management improvements
- Thermal management

## Applying Patches

Patches are applied automatically during kernel build:

```bash
cd kernel/linux-6.6
for patch in ../../patches/kernel/*.patch; do
    patch -p1 < "$patch"
done
```

Or use the Makefile:
```bash
make kernel  # Automatically applies patches
```

## Creating Patches

When modifying kernel code:

```bash
# Make your changes
cd kernel/linux-6.6
# ... edit files ...

# Create patch
git diff > ../../patches/kernel/0001-description.patch
```

## Patch Naming Convention

Format: `NNNN-short-description.patch`

Examples:
- `0001-add-mt6789-yunluo-device-tree.patch`
- `0002-fix-display-driver-for-mt6789.patch`
- `0003-enable-wifi-firmware-loading.patch`

## Notes

- Patches should be rebased for each kernel version
- Test patches on clean kernel source
- Document what each patch does
- Submit useful patches upstream when possible
