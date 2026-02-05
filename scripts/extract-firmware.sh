#!/bin/bash
# Extract firmware from stock Android ROM or device

set -e

# Configuration
FIRMWARE_DIR="firmware"
BUILD_DIR="build/firmware"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

usage() {
    echo "Usage: $0 [ROM_FILE|--from-device]"
    echo ""
    echo "Extract firmware from stock ROM or connected device"
    echo ""
    echo "Options:"
    echo "  ROM_FILE        Path to stock ROM zip file"
    echo "  --from-device   Extract from connected device via ADB"
    echo ""
    echo "Examples:"
    echo "  $0 miui_YUNLUO_V14.0.3.0.zip"
    echo "  $0 --from-device"
}

extract_from_rom() {
    local rom_file="$1"
    
    if [ ! -f "$rom_file" ]; then
        echo_error "ROM file not found: $rom_file"
        exit 1
    fi
    
    echo_info "Extracting firmware from ROM: $rom_file"
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    
    # Extract ROM
    echo_info "Extracting ROM archive..."
    unzip -q "$rom_file" -d "$temp_dir"
    
    # Find and extract system/vendor images
    for img in "$temp_dir"/*.img "$temp_dir"/*.new.dat.br; do
        if [ -f "$img" ]; then
            echo_info "Found image: $(basename $img)"
        fi
    done
    
    # TODO: Extract vendor.img and get firmware files
    echo_warn "ROM extraction not fully implemented yet"
    echo_info "Please use --from-device option for now"
}

extract_from_device() {
    echo_info "Extracting firmware from connected device..."
    
    # Check if device is connected
    if ! adb devices | grep -q "device$"; then
        echo_error "No device connected via ADB"
        echo_error "Enable USB debugging and connect device"
        exit 1
    fi
    
    # Check for root access
    if ! adb shell "su -c 'echo test'" 2>/dev/null | grep -q "test"; then
        echo_warn "Device may not have root access"
        echo_warn "Some firmware files may not be extractable"
    fi
    
    # Create firmware directories
    mkdir -p "$FIRMWARE_DIR"/{wifi,bluetooth,gpu,misc}
    mkdir -p "$BUILD_DIR"
    
    # Extract WiFi firmware
    echo_info "Extracting WiFi firmware..."
    adb pull /vendor/firmware/WIFI_RAM_CODE_MT6789.bin "$FIRMWARE_DIR/wifi/" 2>/dev/null || \
        echo_warn "WiFi firmware not found (WIFI_RAM_CODE_MT6789.bin)"
    adb pull /vendor/firmware/WIFI_MT6789.bin "$FIRMWARE_DIR/wifi/" 2>/dev/null || \
        echo_warn "WiFi firmware not found (WIFI_MT6789.bin)"
    
    # Extract generic WiFi firmware
    adb shell "su -c 'ls /vendor/firmware/WIFI*'" 2>/dev/null | while read fw; do
        [ -z "$fw" ] && continue
        echo_info "Pulling $fw"
        adb pull "$fw" "$FIRMWARE_DIR/wifi/" 2>/dev/null || true
    done
    
    # Extract Bluetooth firmware
    echo_info "Extracting Bluetooth firmware..."
    adb pull /vendor/firmware/mt66xx_bt.bin "$FIRMWARE_DIR/bluetooth/" 2>/dev/null || \
        echo_warn "Bluetooth firmware not found (mt66xx_bt.bin)"
    adb pull /vendor/firmware/BT_RAM_CODE_MT6789.bin "$FIRMWARE_DIR/bluetooth/" 2>/dev/null || true
    
    # Extract GPU firmware
    echo_info "Extracting GPU firmware..."
    adb shell "su -c 'ls /vendor/firmware/mali*'" 2>/dev/null | while read fw; do
        [ -z "$fw" ] && continue
        echo_info "Pulling $fw"
        adb pull "$fw" "$FIRMWARE_DIR/gpu/" 2>/dev/null || true
    done
    
    # Extract other firmware
    echo_info "Extracting miscellaneous firmware..."
    adb pull /vendor/firmware/scp.img "$FIRMWARE_DIR/misc/" 2>/dev/null || \
        echo_warn "SCP firmware not found"
    
    # List all firmware files for reference
    echo_info "Creating firmware list..."
    adb shell "su -c 'find /vendor/firmware -type f'" > "$BUILD_DIR/firmware-list.txt" 2>/dev/null || \
        echo_warn "Could not create complete firmware list"
    
    # Count extracted files
    local wifi_count=$(find "$FIRMWARE_DIR/wifi" -type f 2>/dev/null | wc -l)
    local bt_count=$(find "$FIRMWARE_DIR/bluetooth" -type f 2>/dev/null | wc -l)
    local gpu_count=$(find "$FIRMWARE_DIR/gpu" -type f 2>/dev/null | wc -l)
    local misc_count=$(find "$FIRMWARE_DIR/misc" -type f 2>/dev/null | wc -l)
    
    echo ""
    echo "===================================="
    echo "Firmware Extraction Complete"
    echo "===================================="
    echo "WiFi firmware files: $wifi_count"
    echo "Bluetooth firmware files: $bt_count"
    echo "GPU firmware files: $gpu_count"
    echo "Misc firmware files: $misc_count"
    echo ""
    echo "Firmware saved to: $FIRMWARE_DIR/"
    echo ""
    echo "Next steps:"
    echo "1. Review extracted firmware files"
    echo "2. Copy to rootfs: cp -r $FIRMWARE_DIR/* rootfs/lib/firmware/"
    echo "3. Build boot image with firmware"
    echo "===================================="
}

create_readme() {
    cat > "$FIRMWARE_DIR/README.md" << 'EOF'
# Firmware Files for Redmi Pad (yunluo)

This directory contains firmware files extracted from the stock Android ROM.

## Directory Structure

- `wifi/` - WiFi firmware for MediaTek wireless chip
- `bluetooth/` - Bluetooth firmware
- `gpu/` - Mali-G57 GPU firmware (if needed)
- `misc/` - Other device-specific firmware

## Usage

Copy these files to the root filesystem:

```bash
sudo cp -r firmware/* /path/to/rootfs/lib/firmware/
```

## Licenses

These firmware files are proprietary and extracted from the stock Android system.
They are redistributed under the assumption of fair use for the device owner.

**Do not distribute these files separately from this project.**

## Source

Extracted from: Xiaomi Redmi Pad (yunluo) stock Android ROM
Extraction date: $(date)
EOF
}

# Main script
if [ $# -eq 0 ]; then
    usage
    exit 1
fi

case "$1" in
    --from-device)
        extract_from_device
        create_readme
        ;;
    --help|-h)
        usage
        exit 0
        ;;
    *)
        extract_from_rom "$1"
        create_readme
        ;;
esac

echo_info "Firmware extraction process completed!"
