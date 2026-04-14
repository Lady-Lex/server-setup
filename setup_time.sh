#!/bin/bash
# Ubuntu VM Time Synchronization Setup Script (Chrony-based)
# Prerequisite: Network is already provided by the upstream router;
# this script uses the default NTP pool shipped with chrony.

# 1. Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run this script as root (use sudo)."
  exit 1
fi

echo "========== Starting time & timezone configuration =========="

# 2. Set the timezone to Asia/Shanghai
echo "[1/6] Setting timezone to Asia/Shanghai..."
timedatectl set-timezone Asia/Shanghai

# 3. Disable systemd-timesyncd to prevent conflicts with chrony
echo "[2/6] Disabling systemd-timesyncd to avoid conflicts..."
systemctl disable --now systemd-timesyncd 2>/dev/null || true

# 4. Refresh package lists and install chrony (+ hwclock if needed)
echo "[3/6] Installing chrony..."
apt-get update -qq
apt-get install -y chrony > /dev/null 2>&1

# hwclock lives in util-linux-extra on Ubuntu 24.04+ minimal/cloud images.
# On older releases the package doesn't exist, so we ignore failures.
if ! command -v hwclock >/dev/null 2>&1; then
  echo "       hwclock not found, attempting to install util-linux-extra..."
  apt-get install -y util-linux-extra > /dev/null 2>&1 || true
fi

# 5. Enable chrony and start it at boot
echo "[4/6] Enabling chrony and starting it on boot..."
systemctl enable --now chrony > /dev/null 2>&1

# 6. Force an immediate step-sync (ignores the usual drift threshold)
echo "[5/6] Forcing an initial time step-sync..."
sleep 2  # Give chrony a moment to initialize before stepping
chronyc makestep > /dev/null 2>&1

# 7. Write the corrected system time back to the hardware clock (RTC)
echo "[6/6] Writing current system time to the hardware clock (hwclock)..."
if command -v hwclock >/dev/null 2>&1; then
  hwclock --systohc
else
  echo "       ⚠️  hwclock unavailable, skipping RTC sync."
fi

echo "========== ✅ Configuration complete =========="

# Print final state for a quick sanity check
echo -e "\n⏱️  Current system time:"
date

echo -e "\n📡 Chrony sync status:"
chronyc tracking | grep -E "Reference ID|Leap status"
