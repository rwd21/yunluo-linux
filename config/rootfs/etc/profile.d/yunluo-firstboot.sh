#!/bin/bash
# First boot setup script for Yunluo Linux

if [ -f /etc/yunluo/.firstboot-done ]; then
    exit 0
fi

echo "Welcome to Yunluo Linux (Arch Linux on Redmi Pad)"
echo "=================================================="
echo ""
echo "This is the first boot. Please complete the following setup:"
echo ""
echo "1. Change root password:"
echo "   passwd root"
echo ""
echo "2. Create a user account:"
echo "   useradd -m -G wheel,audio,video,storage -s /bin/bash USERNAME"
echo "   passwd USERNAME"
echo ""
echo "3. Configure network (if WiFi isn't working):"
echo "   nmtui"
echo ""
echo "4. Update system:"
echo "   pacman -Syu"
echo ""
echo "5. Install desktop environment (optional):"
echo "   pacman -S xfce4 lightdm lightdm-gtk-greeter"
echo "   systemctl enable lightdm"
echo ""
echo "For more information, see:"
echo "  - /etc/yunluo/README"
echo "  - https://github.com/rwd21/yunluo-linux"
echo ""

# Create marker to not show this again
touch /etc/yunluo/.firstboot-done 2>/dev/null || true
