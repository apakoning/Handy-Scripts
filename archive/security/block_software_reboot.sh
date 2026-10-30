#!/bin/bash

# Block systemd targets for reboot, poweroff, and halt
echo "Masking reboot, poweroff, and halt targets..."
systemctl mask reboot.target poweroff.target halt.target

# Mask Ctrl+Alt+Del to prevent accidental reboots
echo "Disabling Ctrl+Alt+Del combo..."
systemctl mask ctrl-alt-del.target

# Secure shutdown, reboot, and poweroff binaries (root-only execution)
echo "Restricting shutdown-related binaries to root..."
chmod 700 /sbin/reboot /sbin/shutdown /sbin/poweroff 2>/dev/null || echo "Warning: Binaries not found at /sbin, skipping chmod."

# Disable auto-reboot from dnf-automatic (if installed)
if [ -f /etc/dnf/automatic.conf ]; then
    echo "Disabling dnf-automatic reboots..."
    sed -i 's/^apply_updates.*/apply_updates = no/' /etc/dnf/automatic.conf
    sed -i 's/^reboot.*/reboot = false/' /etc/dnf/automatic.conf
    systemctl disable dnf-automatic.timer 2>/dev/null
else
    echo "dnf-automatic not installed. Skipping auto-update configuration."
fi

# Prevent kernel panics from rebooting the system
echo "Configuring kernel to not reboot on panic or oops..."
sysctl -w kernel.panic=0
sysctl -w kernel.panic_on_oops=0
echo "kernel.panic = 0" >> /etc/sysctl.conf
echo "kernel.panic_on_oops = 0" >> /etc/sysctl.conf

echo "✅ Software-triggered reboots are now blocked unless explicitly run by an admin."


