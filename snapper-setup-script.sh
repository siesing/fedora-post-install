#!/bin/bash

# Snapper Setup Script for Fedora 42
# This script automates the installation and configuration of Snapper with Btrfs
# Author: System Administrator
# Version: 1.0

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

check_btrfs() {
    if ! findmnt -n -o FSTYPE / | grep -q btrfs; then
        print_error "Root filesystem is not Btrfs. Snapper requires Btrfs."
        exit 1
    fi
}

# Main script
clear
echo "================================================"
echo "   Snapper Setup Script for Fedora 42"
echo "================================================"
echo ""

# Check prerequisites
check_root
check_btrfs

# Get username for permissions
if [ -n "${SUDO_USER:-}" ]; then
    USERNAME="$SUDO_USER"
else
    read -p "Enter your username: " USERNAME
fi

# Step 1: Install necessary packages
echo ""
echo "Step 1: Installing necessary packages..."
echo "---------------------------------------"

dnf install -y snapper libdnf5-plugin-actions btrfs-assistant inotify-tools git make btrfs-progs || {
    print_error "Failed to install packages"
    exit 1
}
print_status "Packages installed"

# Step 2: Create Snapper configurations
echo ""
echo "Step 2: Creating Snapper configurations..."
echo "-----------------------------------------"

# Create root configuration
if ! snapper list-configs | grep -q "^root"; then
    snapper -c root create-config / || {
        print_error "Failed to create root configuration"
        exit 1
    }
    print_status "Root configuration created"
else
    print_warning "Root configuration already exists"
fi

# Set permissions for root config
snapper -c root set-config ALLOW_USERS="$USERNAME" SYNC_ACL=yes
print_status "User permissions configured for root"

# Ask about home configuration
# Why not recommended?
# 1. Take up significant disk space due to user files
# 2. Potentially cause data loss if a rollback is performed and recent user files are reverted
# 3. Create unnecessary clutter with frequent snapshots of changing user data
echo ""
read -p "Do you want to create snapshots for /home too? (not recommended) (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if ! snapper list-configs | grep -q "^home"; then
        if findmnt -n -o FSTYPE /home | grep -q btrfs; then
            snapper -c home create-config /home || {
                print_error "Failed to create home configuration"
            }
            snapper -c home set-config ALLOW_USERS="$USERNAME" SYNC_ACL=yes
            print_status "Home configuration created"
        else
            print_warning "/home is not a Btrfs subvolume, skipping"
        fi
    else
        print_warning "Home configuration already exists"
    fi
fi

# Step 3: Configure automatic snapshots for DNF
echo ""
echo "Step 3: Configuring automatic snapshots for DNF..."
echo "-----------------------------------------------------"

mkdir -p /etc/dnf/libdnf5-plugins/actions.d/

cat > /etc/dnf/libdnf5-plugins/actions.d/snapper.actions <<'EOF'
# Get snapshot description
pre_transaction::::/usr/bin/sh -c echo\ "tmp.cmd=$(ps\ -o\ command\ --no-headers\ -p\ '${pid}')"

# Creates pre snapshot before the transaction
pre_transaction::::/usr/bin/sh -c echo\ "tmp.snapper_pre_number=$(snapper\ create\ -t\ pre\ -c\ number\ -p\ -d\ '${tmp.cmd}')"

# Creates post snapshot after the transaction
post_transaction::::/usr/bin/sh -c [\ -n\ "${tmp.snapper_pre_number}"\ ]\ &&\ snapper\ create\ -t\ post\ --pre-number\ "${tmp.snapper_pre_number}"\ -c\ number\ -d\ "${tmp.cmd}"\ ;\ echo\ tmp.snapper_pre_number\ ;\ echo\ tmp.cmd
EOF

print_status "DNF integration configured"

# Step 4: Install and configure grub-btrfs
echo ""
echo "Step 4: Installing and configuring grub-btrfs..."
echo "---------------------------------------------------"

# Clone and install grub-btrfs
cd /tmp
if [ -d "grub-btrfs" ]; then
    rm -rf grub-btrfs
fi

git clone https://github.com/Antynea/grub-btrfs.git || {
    print_error "Failed to clone grub-btrfs"
    exit 1
}

cd grub-btrfs
make install || {
    print_error "Failed to install grub-btrfs"
    exit 1
}
cd ..
rm -rf grub-btrfs
print_status "grub-btrfs installed"

# Configure grub-btrfs
if [ -f /etc/default/grub-btrfs/config ]; then
    # Backup original config
    cp /etc/default/grub-btrfs/config /etc/default/grub-btrfs/config.bak
    
    # Update configuration
    sed -i 's|#GRUB_BTRFS_MKCONFIG=.*|GRUB_BTRFS_MKCONFIG="/usr/sbin/grub2-mkconfig"|' /etc/default/grub-btrfs/config
    sed -i 's|#GRUB_BTRFS_GRUB_DIRNAME=.*|GRUB_BTRFS_GRUB_DIRNAME="/boot/grub2"|' /etc/default/grub-btrfs/config
    sed -i 's|#GRUB_BTRFS_LIMIT=.*|GRUB_BTRFS_LIMIT="10"|' /etc/default/grub-btrfs/config
    
    print_status "grub-btrfs configured"
fi

# Update GRUB
grub2-mkconfig -o /boot/grub2/grub.cfg || {
    print_error "Failed to update GRUB"
    exit 1
}
print_status "GRUB updated"

# Enable grub-btrfs daemon
systemctl enable --now grub-btrfsd.service || {
    print_error "Failed to enable grub-btrfsd"
}
print_status "grub-btrfsd enabled"

# Step 5: Configure automatic timeline snapshots
echo ""
echo "Step 5: Configuring automatic timeline snapshots..."
echo "------------------------------------------------------"

# Increase kernel retention limit to avoid issues with rollbacks
echo ""
echo "Increasing kernel retention limit..."
if grep -q "^installonly_limit=" /etc/dnf/dnf.conf; then
    sudo sed -i 's/^installonly_limit=.*/installonly_limit=5/' /etc/dnf/dnf.conf
    print_status "Kernel retention limit updated to 5"
else
    echo "installonly_limit=5" >> /etc/dnf/dnf.conf
    print_status "Kernel retention limit set to 5"
fi

# Configure snapshot retention for root
snapper -c root set-config TIMELINE_LIMIT_HOURLY="5"
snapper -c root set-config TIMELINE_LIMIT_DAILY="7"
snapper -c root set-config TIMELINE_LIMIT_WEEKLY="4"
snapper -c root set-config TIMELINE_LIMIT_MONTHLY="6"
snapper -c root set-config TIMELINE_LIMIT_YEARLY="2"
print_status "Snapshot policy configured for root"

# Disable timeline for home if it exists
if snapper list-configs | grep -q "^home"; then
    snapper -c home set-config TIMELINE_CREATE="no"
    print_status "Timeline disabled for home"
fi

# Enable timers
systemctl enable --now snapper-timeline.timer || {
    print_error "Failed to enable snapper-timeline.timer"
}
systemctl enable --now snapper-cleanup.timer || {
    print_error "Failed to enable snapper-cleanup.timer"
}
print_status "Automatic timers enabled"

# Create initial snapshot
echo ""
echo "Creating initial snapshot..."
snapper -c root create -d "Initial snapshot after Snapper installation" || {
    print_warning "Could not create initial snapshot"
}

# Summary
echo ""
echo "================================================"
echo "   Installation completed!"
echo "================================================"
echo ""
print_status "Snapper is now configured and active"
echo ""
echo "Next steps:"
echo "1. Test DNF integration: sudo dnf install btop"
echo "2. List snapshots: snapper -c root list"
echo "3. Use GUI: btrfs-assistant"
echo "4. Reboot to see GRUB integration"
echo ""
echo "Tips: Run 'snapper -c root list' to see your snapshots"
echo "      Run 'sudo btrfs filesystem usage /' to see disk usage"
echo ""
print_warning "Remember: Snapshots are NOT backups! Have an external backup strategy."