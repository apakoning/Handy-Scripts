#!/bin/bash
echo "=== USB Link Speeds ==="
lsusb -t | grep -E "M$"
echo ""
echo "=== Connected USB Devices ==="
lsusb
echo ""
echo "=== Power Roles / Current ==="
cat /sys/class/typec/*/power_role 2>/dev/null
cat /sys/class/typec/*/current_max 2>/dev/null

