#!/bin/bash
# Create boot image for Redmi Pad

set -e

# Configuration
BUILD_DIR="build"
KERNEL_DIR="$BUILD_DIR/kernel"
BOOT_DIR="$BUILD_DIR/boot"
DEVICE="yunluo"

# Boot image parameters
KERNEL_IMAGE="$KERNEL_DIR/Image.gz"
DTB_FILE="$KERNEL_DIR/mt6789-yunluo.dtb"
RAMDISK="$BOOT_DIR/initramfs.cpio.gz"
OUTPUT="$BUILD_DIR/boot-$DEVICE.img"

# Android boot image parameters
CMDLINE="console=tty0 root=/dev/mmcblk0p30 rootwait rw init=/sbin/init"
BASE="0x40000000"
PAGESIZE="4096"
KERNEL_OFFSET="0x00008000"
RAMDISK_OFFSET="0x01000000"
TAGS_OFFSET="0x00000100"

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

echo_info "Creating boot image for Redmi Pad..."

# Check dependencies
if ! command -v mkbootimg &> /dev/null; then
    echo_error "mkbootimg not found. Install with: pip install mkbootimg"
    exit 1
fi

# Check if kernel exists
if [ ! -f "$KERNEL_IMAGE" ]; then
    echo_error "Kernel image not found at $KERNEL_IMAGE"
    echo_error "Please build kernel first: make kernel"
    exit 1
fi

# Create boot directory
mkdir -p "$BOOT_DIR"

# Create initramfs if it doesn't exist
if [ ! -f "$RAMDISK" ]; then
    echo_info "Creating initramfs..."
    
    # Create initramfs structure
    INITRAMFS_DIR="$BOOT_DIR/initramfs"
    rm -rf "$INITRAMFS_DIR"
    mkdir -p "$INITRAMFS_DIR"/{bin,sbin,etc,proc,sys,dev,tmp,lib,usr,mnt/root}
    
    # Copy busybox (if available)
    if command -v busybox &> /dev/null; then
        cp $(which busybox) "$INITRAMFS_DIR/bin/"
    else
        echo_warn "busybox not found, creating minimal init"
        # Will need to be built statically for aarch64
    fi
    
    # Create init script
    cat > "$INITRAMFS_DIR/init" << 'EOF'
#!/bin/busybox sh

# Mount essential filesystems
/bin/busybox mount -t proc none /proc
/bin/busybox mount -t sysfs none /sys
/bin/busybox mount -t devtmpfs none /dev

# Create device nodes if needed
[ -e /dev/null ] || /bin/busybox mknod -m 666 /dev/null c 1 3
[ -e /dev/console ] || /bin/busybox mknod -m 600 /dev/console c 5 1

# Load necessary modules
/bin/busybox modprobe ext4 2>/dev/null || true
/bin/busybox modprobe f2fs 2>/dev/null || true

# Wait for devices
/bin/busybox sleep 2

# Try to mount root filesystem
echo "Searching for root filesystem..."

# Try common root devices
for dev in mmcblk0p30 mmcblk0p29 mmcblk0p31 sda1 sda2; do
    if [ -e "/dev/$dev" ]; then
        echo "Trying /dev/$dev..."
        if /bin/busybox mount -t ext4 /dev/$dev /mnt/root 2>/dev/null; then
            echo "Mounted root from /dev/$dev"
            break
        fi
        if /bin/busybox mount -t f2fs /dev/$dev /mnt/root 2>/dev/null; then
            echo "Mounted root from /dev/$dev"
            break
        fi
    fi
done

# Check if root was mounted
if ! /bin/busybox mountpoint -q /mnt/root; then
    echo "ERROR: Could not mount root filesystem!"
    echo "Available block devices:"
    /bin/busybox ls -l /dev/mmcblk* /dev/sd* 2>/dev/null || true
    echo "Dropping to shell..."
    exec /bin/busybox sh
fi

# Cleanup
/bin/busybox umount /proc
/bin/busybox umount /sys

# Switch to real root
echo "Switching to root filesystem..."
exec /bin/busybox switch_root /mnt/root /sbin/init
EOF
    
    chmod +x "$INITRAMFS_DIR/init"
    
    # Create initramfs archive
    echo_info "Creating initramfs archive..."
    cd "$INITRAMFS_DIR"
    find . | cpio -o -H newc | gzip > "$RAMDISK"
    cd - > /dev/null
    
    echo_info "Initramfs created: $RAMDISK"
fi

# Build mkbootimg command
MKBOOTIMG_CMD="mkbootimg \
    --kernel $KERNEL_IMAGE \
    --ramdisk $RAMDISK \
    --cmdline \"$CMDLINE\" \
    --base $BASE \
    --pagesize $PAGESIZE \
    --kernel_offset $KERNEL_OFFSET \
    --ramdisk_offset $RAMDISK_OFFSET \
    --tags_offset $TAGS_OFFSET \
    --output $OUTPUT"

# Add DTB if it exists
if [ -f "$DTB_FILE" ]; then
    echo_info "Including device tree blob: $DTB_FILE"
    MKBOOTIMG_CMD="$MKBOOTIMG_CMD --dtb $DTB_FILE"
else
    echo_warn "Device tree blob not found at $DTB_FILE"
    echo_warn "Boot image will be created without DTB"
fi

# Create boot image
echo_info "Creating boot image..."
eval $MKBOOTIMG_CMD

# Verify boot image
if [ -f "$OUTPUT" ]; then
    echo_info "Boot image created successfully!"
    echo ""
    echo "===================================="
    echo "Boot Image Information"
    echo "===================================="
    echo "Output: $OUTPUT"
    echo "Size: $(du -h $OUTPUT | cut -f1)"
    echo "Kernel: $KERNEL_IMAGE"
    echo "Ramdisk: $RAMDISK"
    echo "Cmdline: $CMDLINE"
    [ -f "$DTB_FILE" ] && echo "DTB: $DTB_FILE" || echo "DTB: Not included"
    echo ""
    echo "File type:"
    file "$OUTPUT"
    echo ""
    echo "Next steps:"
    echo "1. Boot to fastboot mode on device"
    echo "2. Flash boot image:"
    echo "   fastboot flash boot $OUTPUT"
    echo "3. Reboot device"
    echo "===================================="
else
    echo_error "Failed to create boot image!"
    exit 1
fi
