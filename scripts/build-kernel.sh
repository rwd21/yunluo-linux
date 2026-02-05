#!/bin/bash
# Build Linux kernel for Redmi Pad

set -e

# Configuration
ARCH="arm64"
CROSS_COMPILE="aarch64-linux-gnu-"
KERNEL_VERSION="6.6"
KERNEL_DIR="kernel/linux-${KERNEL_VERSION}"
CONFIG_DIR="config/kernel"
PATCHES_DIR="patches/kernel"
BUILD_DIR="build/kernel"
NPROC=$(nproc)

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kernel source exists
if [ ! -d "$KERNEL_DIR" ]; then
    echo_error "Kernel source not found at $KERNEL_DIR"
    echo_info "Download kernel source first:"
    echo "  make download-kernel"
    exit 1
fi

# Check cross compiler
if ! command -v ${CROSS_COMPILE}gcc &> /dev/null; then
    echo_error "Cross compiler not found: ${CROSS_COMPILE}gcc"
    echo_info "Install cross compiler:"
    echo "  sudo pacman -S aarch64-linux-gnu-gcc  # Arch Linux"
    echo "  sudo apt install gcc-aarch64-linux-gnu  # Debian/Ubuntu"
    exit 1
fi

echo_info "Building kernel for Redmi Pad (yunluo)..."

# Apply patches
if [ -d "$PATCHES_DIR" ] && [ "$(ls -A $PATCHES_DIR/*.patch 2>/dev/null)" ]; then
    echo_info "Applying kernel patches..."
    cd "$KERNEL_DIR"
    for patch in ../../$PATCHES_DIR/*.patch; do
        if [ -f "$patch" ]; then
            echo_info "Applying $(basename $patch)..."
            patch -p1 < "$patch" || echo_error "Failed to apply patch: $(basename $patch)"
        fi
    done
    cd ../..
else
    echo_info "No patches to apply"
fi

# Configure kernel
echo_info "Configuring kernel..."
if [ -f "$CONFIG_DIR/yunluo_defconfig" ]; then
    cp "$CONFIG_DIR/yunluo_defconfig" "$KERNEL_DIR/.config"
    make -C "$KERNEL_DIR" ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE olddefconfig
else
    echo_error "Config not found: $CONFIG_DIR/yunluo_defconfig"
    make -C "$KERNEL_DIR" ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE defconfig
fi

# Build kernel
echo_info "Building kernel image..."
make -C "$KERNEL_DIR" \
    ARCH=$ARCH \
    CROSS_COMPILE=$CROSS_COMPILE \
    -j$NPROC \
    Image.gz

# Build device tree
echo_info "Building device tree..."
make -C "$KERNEL_DIR" \
    ARCH=$ARCH \
    CROSS_COMPILE=$CROSS_COMPILE \
    dtbs || echo_error "Warning: DTB build may have failed"

# Build modules
echo_info "Building kernel modules..."
make -C "$KERNEL_DIR" \
    ARCH=$ARCH \
    CROSS_COMPILE=$CROSS_COMPILE \
    -j$NPROC \
    modules

# Install modules
echo_info "Installing kernel modules..."
mkdir -p "$BUILD_DIR/modules"
make -C "$KERNEL_DIR" \
    ARCH=$ARCH \
    CROSS_COMPILE=$CROSS_COMPILE \
    INSTALL_MOD_PATH="../../$BUILD_DIR/modules" \
    modules_install

# Copy outputs
echo_info "Copying build artifacts..."
mkdir -p "$BUILD_DIR"
cp "$KERNEL_DIR/arch/$ARCH/boot/Image.gz" "$BUILD_DIR/"

# Copy DTB if it exists
if [ -f "$KERNEL_DIR/arch/$ARCH/boot/dts/mediatek/mt6789-yunluo.dtb" ]; then
    cp "$KERNEL_DIR/arch/$ARCH/boot/dts/mediatek/mt6789-yunluo.dtb" "$BUILD_DIR/"
else
    echo_error "Warning: Device tree blob not found"
    echo_info "You may need to create device-tree/mt6789-yunluo.dts"
fi

echo_info "Kernel build complete!"
echo ""
echo "Build artifacts:"
echo "  Kernel: $BUILD_DIR/Image.gz"
echo "  DTB: $BUILD_DIR/mt6789-yunluo.dtb (if available)"
echo "  Modules: $BUILD_DIR/modules/"
echo ""
echo "Next steps:"
echo "  make bootimg    # Create boot image"
echo "  make rootfs     # Build root filesystem"
