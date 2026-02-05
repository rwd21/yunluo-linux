#!/bin/bash
# Build Arch Linux ARM root filesystem for Redmi Pad

set -e

# Configuration
ROOTFS_DIR="rootfs/archlinux-arm"
BUILD_DIR="build"
ARCH="aarch64"
ROOTFS_SIZE="4G"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo_error "This script must be run as root (use sudo)"
    exit 1
fi

echo_info "Building Arch Linux ARM root filesystem..."

# Create directories
mkdir -p "$ROOTFS_DIR"
mkdir -p "$BUILD_DIR"

# Download Arch Linux ARM base if not exists
TARBALL="ArchLinuxARM-aarch64-latest.tar.gz"
if [ ! -f "$BUILD_DIR/$TARBALL" ]; then
    echo_info "Downloading Arch Linux ARM base..."
    wget -O "$BUILD_DIR/$TARBALL" \
        "http://os.archlinuxarm.org/os/$TARBALL"
else
    echo_info "Using cached Arch Linux ARM base"
fi

# Extract rootfs
echo_info "Extracting root filesystem..."
rm -rf "$ROOTFS_DIR"
mkdir -p "$ROOTFS_DIR"
tar -xpf "$BUILD_DIR/$TARBALL" -C "$ROOTFS_DIR"

# Setup QEMU for chroot
echo_info "Setting up QEMU for cross-architecture chroot..."
if [ -f /usr/bin/qemu-aarch64-static ]; then
    cp /usr/bin/qemu-aarch64-static "$ROOTFS_DIR/usr/bin/"
else
    echo_error "qemu-aarch64-static not found. Install qemu-user-static"
    exit 1
fi

# Mount necessary filesystems
echo_info "Mounting filesystems for chroot..."
mount --bind /dev "$ROOTFS_DIR/dev"
mount --bind /proc "$ROOTFS_DIR/proc"
mount --bind /sys "$ROOTFS_DIR/sys"

# Create cleanup function
cleanup() {
    echo_info "Cleaning up..."
    umount "$ROOTFS_DIR/dev" 2>/dev/null || true
    umount "$ROOTFS_DIR/proc" 2>/dev/null || true
    umount "$ROOTFS_DIR/sys" 2>/dev/null || true
    rm -f "$ROOTFS_DIR/usr/bin/qemu-aarch64-static"
}
trap cleanup EXIT

# Configure system in chroot
echo_info "Configuring system..."
cat > "$ROOTFS_DIR/tmp/setup.sh" << 'CHROOT_SCRIPT'
#!/bin/bash
set -e

# Initialize pacman keyring
pacman-key --init
pacman-key --populate archlinuxarm

# Update system
pacman -Syu --noconfirm

# Install essential packages
pacman -S --noconfirm \
    base-devel \
    linux-firmware \
    networkmanager \
    sudo \
    openssh \
    vim \
    nano \
    htop \
    wget \
    curl \
    git

# Enable NetworkManager
systemctl enable NetworkManager

# Enable SSH
systemctl enable sshd

# Create default user (alarm)
if ! id -u alarm > /dev/null 2>&1; then
    useradd -m -G wheel,audio,video,storage -s /bin/bash alarm
    echo "alarm:alarm" | chpasswd
fi

# Set root password
echo "root:root" | chpasswd

# Configure sudo
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Set timezone (UTC by default)
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# Set locale
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set hostname
echo "yunluo-arch" > /etc/hostname

# Configure hosts
cat > /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   yunluo-arch.localdomain yunluo-arch
EOF

# Configure fstab
cat > /etc/fstab << EOF
# /etc/fstab: static file system information
# <file system> <mount point> <type> <options> <dump> <pass>
/dev/mmcblk0p30  /       ext4    defaults,noatime    0   1
tmpfs            /tmp    tmpfs   defaults,noatime    0   0
EOF

echo "System configured successfully"
CHROOT_SCRIPT

chmod +x "$ROOTFS_DIR/tmp/setup.sh"

# Run configuration in chroot
echo_info "Running configuration in chroot..."
chroot "$ROOTFS_DIR" /usr/bin/qemu-aarch64-static /bin/bash /tmp/setup.sh

# Copy device-specific configurations
echo_info "Copying device-specific configurations..."
if [ -d "config/rootfs" ]; then
    cp -r config/rootfs/* "$ROOTFS_DIR/" || true
fi

# Copy kernel modules if they exist
echo_info "Copying kernel modules..."
if [ -d "$BUILD_DIR/rootfs/lib/modules" ]; then
    cp -r "$BUILD_DIR/rootfs/lib/modules"/* "$ROOTFS_DIR/lib/modules/" || true
fi

# Create device-specific directories
mkdir -p "$ROOTFS_DIR/lib/firmware"
mkdir -p "$ROOTFS_DIR/etc/yunluo"

# Create a marker file
echo "Built on $(date)" > "$ROOTFS_DIR/etc/yunluo/build-info"
echo "Device: Redmi Pad (yunluo)" >> "$ROOTFS_DIR/etc/yunluo/build-info"
echo "Architecture: aarch64" >> "$ROOTFS_DIR/etc/yunluo/build-info"

# Cleanup chroot script
rm -f "$ROOTFS_DIR/tmp/setup.sh"

# Create tarball
echo_info "Creating root filesystem archive..."
cd "$ROOTFS_DIR"
tar czf "../../$BUILD_DIR/rootfs-yunluo.tar.gz" .
cd ../..

echo_info "Root filesystem built successfully!"
echo_info "Output: $BUILD_DIR/rootfs-yunluo.tar.gz"
echo_info "Size: $(du -h $BUILD_DIR/rootfs-yunluo.tar.gz | cut -f1)"

# Show summary
echo ""
echo "===================================="
echo "Root Filesystem Build Complete"
echo "===================================="
echo "Location: $BUILD_DIR/rootfs-yunluo.tar.gz"
echo ""
echo "Default credentials:"
echo "  root / root"
echo "  alarm / alarm (user with sudo)"
echo ""
echo "Next steps:"
echo "1. Build kernel (make kernel)"
echo "2. Create boot image (make bootimg)"
echo "3. Flash to device (see INSTALLATION.md)"
echo "===================================="
