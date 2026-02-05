# Yunluo Linux - Master Makefile
# Build automation for Arch Linux on Redmi Pad

# Configuration
ARCH := arm64
CROSS_COMPILE := aarch64-linux-gnu-
KERNEL_VERSION := 6.6
DEVICE := yunluo
SOC := mt6789

# Directories
BUILD_DIR := build
KERNEL_DIR := kernel/linux-$(KERNEL_VERSION)
ROOTFS_DIR := rootfs/archlinux-arm
CONFIG_DIR := config
SCRIPTS_DIR := scripts
FIRMWARE_DIR := firmware
DT_DIR := device-tree

# Output files
BOOT_IMG := $(BUILD_DIR)/boot-$(DEVICE).img
ROOTFS_IMG := $(BUILD_DIR)/rootfs-$(DEVICE).tar.gz
KERNEL_IMG := $(BUILD_DIR)/kernel/Image.gz
DTB_FILE := $(BUILD_DIR)/kernel/$(SOC)-$(DEVICE).dtb

# Build flags
KERNEL_DEFCONFIG := $(CONFIG_DIR)/kernel/yunluo_defconfig
NPROC := $(shell nproc)

.PHONY: all clean kernel rootfs bootimg firmware image help

# Default target
all: help

help:
	@echo "Yunluo Linux Build System"
	@echo "=========================="
	@echo ""
	@echo "Available targets:"
	@echo "  make kernel      - Build Linux kernel"
	@echo "  make rootfs      - Build Arch Linux ARM rootfs"
	@echo "  make bootimg     - Create boot image"
	@echo "  make firmware    - Extract firmware from Android"
	@echo "  make image       - Build complete flashable image"
	@echo "  make all-build   - Build kernel + rootfs + bootimg"
	@echo "  make clean       - Clean build artifacts"
	@echo "  make distclean   - Clean everything including downloads"
	@echo "  make help        - Show this help message"
	@echo ""
	@echo "Prerequisites:"
	@echo "  - Install build dependencies (see BUILDING.md)"
	@echo "  - Download kernel source to kernel/ directory"
	@echo "  - Have Android platform tools (fastboot, mkbootimg)"

# Build everything
all-build: kernel rootfs bootimg
	@echo "Build complete! Output in $(BUILD_DIR)/"

# Build kernel
kernel: $(KERNEL_IMG) $(DTB_FILE)

$(KERNEL_IMG): $(KERNEL_DIR)/.config
	@echo "Building kernel..."
	$(MAKE) -C $(KERNEL_DIR) \
		ARCH=$(ARCH) \
		CROSS_COMPILE=$(CROSS_COMPILE) \
		-j$(NPROC)
	@echo "Installing kernel modules..."
	$(MAKE) -C $(KERNEL_DIR) \
		ARCH=$(ARCH) \
		CROSS_COMPILE=$(CROSS_COMPILE) \
		INSTALL_MOD_PATH=$(BUILD_DIR)/rootfs \
		modules_install
	@mkdir -p $(BUILD_DIR)/kernel
	@cp $(KERNEL_DIR)/arch/$(ARCH)/boot/Image.gz $(KERNEL_IMG)
	@echo "Kernel built: $(KERNEL_IMG)"

$(DTB_FILE): $(KERNEL_DIR)/.config
	@echo "Building device tree..."
	$(MAKE) -C $(KERNEL_DIR) \
		ARCH=$(ARCH) \
		CROSS_COMPILE=$(CROSS_COMPILE) \
		dtbs
	@mkdir -p $(BUILD_DIR)/kernel
	@cp $(KERNEL_DIR)/arch/$(ARCH)/boot/dts/mediatek/$(SOC)-$(DEVICE).dtb $(DTB_FILE) || \
		echo "Warning: DTB not found, you may need to create device tree"
	@echo "Device tree built: $(DTB_FILE)"

$(KERNEL_DIR)/.config:
	@if [ ! -d $(KERNEL_DIR) ]; then \
		echo "Error: Kernel source not found at $(KERNEL_DIR)"; \
		echo "Please download kernel source first"; \
		exit 1; \
	fi
	@if [ -f $(KERNEL_DEFCONFIG) ]; then \
		cp $(KERNEL_DEFCONFIG) $(KERNEL_DIR)/.config; \
		$(MAKE) -C $(KERNEL_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) olddefconfig; \
	else \
		echo "Using default config..."; \
		$(MAKE) -C $(KERNEL_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) defconfig; \
	fi

# Configure kernel interactively
menuconfig:
	@if [ ! -d $(KERNEL_DIR) ]; then \
		echo "Error: Kernel source not found"; \
		exit 1; \
	fi
	$(MAKE) -C $(KERNEL_DIR) \
		ARCH=$(ARCH) \
		CROSS_COMPILE=$(CROSS_COMPILE) \
		menuconfig
	@cp $(KERNEL_DIR)/.config $(KERNEL_DEFCONFIG)
	@echo "Configuration saved to $(KERNEL_DEFCONFIG)"

# Build root filesystem
rootfs: $(ROOTFS_IMG)

$(ROOTFS_IMG):
	@echo "Building root filesystem..."
	@$(SCRIPTS_DIR)/build-rootfs.sh
	@echo "Root filesystem built: $(ROOTFS_IMG)"

# Create boot image
bootimg: $(BOOT_IMG)

$(BOOT_IMG): $(KERNEL_IMG)
	@echo "Creating boot image..."
	@$(SCRIPTS_DIR)/create-bootimg.sh
	@echo "Boot image created: $(BOOT_IMG)"

# Extract firmware
firmware:
	@echo "Extracting firmware from Android ROM..."
	@$(SCRIPTS_DIR)/extract-firmware.sh
	@echo "Firmware extracted to $(FIRMWARE_DIR)/"

# Create complete flashable image
image: all-build firmware
	@echo "Creating flashable image..."
	@mkdir -p $(BUILD_DIR)/flashable
	@cp $(BOOT_IMG) $(BUILD_DIR)/flashable/
	@cp $(ROOTFS_IMG) $(BUILD_DIR)/flashable/
	@cp -r $(FIRMWARE_DIR) $(BUILD_DIR)/flashable/
	@echo "Creating flash script..."
	@cat > $(BUILD_DIR)/flashable/flash.sh << 'EOF'
#!/bin/bash
echo "Flashing Yunluo Linux..."
fastboot flash boot boot-yunluo.img
echo "Boot image flashed. Now install rootfs via recovery."
echo "See INSTALLATION.md for complete instructions."
EOF
	@chmod +x $(BUILD_DIR)/flashable/flash.sh
	@echo "Flashable image ready in $(BUILD_DIR)/flashable/"

# Download kernel source
download-kernel:
	@echo "Downloading kernel source..."
	@mkdir -p kernel
	@cd kernel && \
		wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$(KERNEL_VERSION).tar.xz && \
		tar xf linux-$(KERNEL_VERSION).tar.xz
	@echo "Kernel source downloaded to kernel/linux-$(KERNEL_VERSION)/"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@if [ -d $(KERNEL_DIR) ]; then \
		$(MAKE) -C $(KERNEL_DIR) clean; \
	fi
	@rm -rf $(ROOTFS_DIR)
	@echo "Clean complete"

# Deep clean including downloads
distclean: clean
	@echo "Deep cleaning..."
	@rm -rf kernel/linux-*
	@rm -f kernel/*.tar.xz
	@echo "Distclean complete"

# Install build dependencies (Arch Linux)
deps-arch:
	@echo "Installing build dependencies for Arch Linux..."
	sudo pacman -S --needed base-devel git wget curl android-tools \
		dtc bc aarch64-linux-gnu-gcc aarch64-linux-gnu-binutils \
		qemu-user-static-binfmt arch-install-scripts python-pip
	pip install mkbootimg
	@echo "Dependencies installed"

# Install build dependencies (Debian/Ubuntu)
deps-debian:
	@echo "Installing build dependencies for Debian/Ubuntu..."
	sudo apt-get update
	sudo apt-get install -y build-essential git wget curl adb fastboot \
		device-tree-compiler bc gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu \
		qemu-user-static binfmt-support debootstrap python3-pip
	pip3 install mkbootimg
	@echo "Dependencies installed"

# Testing targets
test-boot:
	@echo "Testing boot image..."
	@if [ -f $(BOOT_IMG) ]; then \
		file $(BOOT_IMG); \
		echo "Boot image looks valid"; \
	else \
		echo "Error: Boot image not found"; \
		exit 1; \
	fi

# Show build info
info:
	@echo "Build Configuration"
	@echo "==================="
	@echo "Architecture:     $(ARCH)"
	@echo "Cross Compiler:   $(CROSS_COMPILE)"
	@echo "Kernel Version:   $(KERNEL_VERSION)"
	@echo "Device:           $(DEVICE)"
	@echo "SoC:              $(SOC)"
	@echo "Build Directory:  $(BUILD_DIR)"
	@echo ""
	@echo "Toolchain Check:"
	@which $(CROSS_COMPILE)gcc > /dev/null 2>&1 && \
		echo "  ✓ Cross compiler found: $$($(CROSS_COMPILE)gcc --version | head -1)" || \
		echo "  ✗ Cross compiler not found"
	@which fastboot > /dev/null 2>&1 && \
		echo "  ✓ fastboot found" || \
		echo "  ✗ fastboot not found"
	@which mkbootimg > /dev/null 2>&1 && \
		echo "  ✓ mkbootimg found" || \
		echo "  ✗ mkbootimg not found"
