#!/bin/bash
# Quick setup script for Yunluo Linux development environment

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo ""
echo "==========================================="
echo "  Yunluo Linux Development Setup"
echo "==========================================="
echo ""

# Detect OS
if [ -f /etc/arch-release ]; then
    OS="arch"
elif [ -f /etc/debian_version ]; then
    OS="debian"
else
    OS="unknown"
fi

echo_info "Detected OS: $OS"

# Install dependencies
echo ""
echo_info "Installing build dependencies..."

case $OS in
    arch)
        sudo pacman -S --needed base-devel git wget curl android-tools \
            dtc bc aarch64-linux-gnu-gcc aarch64-linux-gnu-binutils \
            qemu-user-static-binfmt arch-install-scripts python-pip
        ;;
    debian)
        sudo apt-get update
        sudo apt-get install -y build-essential git wget curl adb fastboot \
            device-tree-compiler bc gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu \
            qemu-user-static binfmt-support debootstrap python3-pip
        ;;
    *)
        echo_warn "Unknown OS. Please install dependencies manually."
        echo "See BUILDING.md for required packages."
        ;;
esac

# Install Python tools
echo_info "Installing Python build tools..."
pip install mkbootimg || pip3 install mkbootimg

# Create build directories
echo_info "Creating build directories..."
mkdir -p build/{kernel,rootfs,boot,firmware}
mkdir -p downloads

# Check toolchain
echo ""
echo_info "Checking toolchain..."
if command -v aarch64-linux-gnu-gcc &> /dev/null; then
    echo_info "✓ Cross compiler: $(aarch64-linux-gnu-gcc --version | head -1)"
else
    echo_warn "✗ Cross compiler not found"
fi

if command -v fastboot &> /dev/null; then
    echo_info "✓ fastboot found"
else
    echo_warn "✗ fastboot not found"
fi

if command -v mkbootimg &> /dev/null; then
    echo_info "✓ mkbootimg found"
else
    echo_warn "✗ mkbootimg not found"
fi

# Optional: Download kernel source
echo ""
read -p "Download kernel source (Linux 6.6)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo_info "Downloading kernel source..."
    make download-kernel
fi

echo ""
echo "==========================================="
echo "  Setup Complete!"
echo "==========================================="
echo ""
echo "Next steps:"
echo "  1. Review BUILDING.md for build instructions"
echo "  2. Extract firmware from your device:"
echo "     ./scripts/extract-firmware.sh --from-device"
echo "  3. Build the project:"
echo "     make all-build"
echo ""
echo "For help:"
echo "  make help"
echo "  cat BUILDING.md"
echo ""
