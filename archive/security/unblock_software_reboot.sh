#!/bin/bash

# Unmask systemd targets
echo "Unmasking reboot, poweroff, and halt targets..."
systemctl unmask reboot.target poweroff.target halt.target

# Unmask Ctrl+Alt+Del combo
echo "Re-enabling Ctrl+Alt+Del reboot combo..."
systemctl unmask ctrl-alt-del.target

# Reset permissions on reboot-related binaries (if they exist)
echo "Restoring execute permissions on shutdown-related binaries..."
for bin in /sbin/reboot /sbin/shutdown /sbin/poweroff; do
    if [ -f "$bin" ]; then
        chmod 755 "$bin"
    else
        echo "  Skipping $bin (not found)"
    fi
done

# Restore default dnf-automatic settings (if installed)
if [ -f /etc/dnf/automatic.conf ]; then
    echo "Restoring dnf-automatic settings..."
    sed -i 's/^apply_updates.*/apply_updates = yes/' /etc/dnf/automatic.conf
    sed -i 's/^reboot.*/reboot = true/' /etc/dnf/automatic.conf
    systemctl enable dnf-automatic.timer 2>/dev/null
else
    echo "dnf-automatic not installed. Skipping config restore."
fi

# Restore kernel panic reboot behavior
echo "Restoring default kernel panic behavior..."
sysctl -w kernel.panic=10
sysctl -w kernel.panic_on_oops=1

# Clean up sysctl.conf entries
sed -i '/^kernel.panic\s*=\s*0/d' /etc/sysctl.conf
sed -i '/^kernel.panic_on_oops\s*=\s*0/d' /etc/sysctl.conf
echo "kernel.panic = 10" >> /etc/sysctl.conf
echo "kernel.panic_on_oops = 1" >> /etc/sysctl.conf

echo "✅ Reboot permissions and behavior restored to default."


