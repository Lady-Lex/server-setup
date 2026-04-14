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
echo "[1/5] Setting timezone to Asia/Shanghai..."
timedatectl set-timezone Asia/Shanghai

# 3. Disable systemd-timesyncd to prevent conflicts with chrony
echo "[2/5] Disabling systemd-timesyncd to avoid conflicts..."
systemctl disable --now systemd-timesyncd 2>/dev/null || true

# 4. Refresh package lists and install chrony
echo "[3/5] Installing chrony..."
apt-get update -qq
apt-get install -y chrony > /dev/null 2>&1

# 5. Enable chrony and start it at boot
echo "[4/5] Enabling chrony and starting it on boot..."
systemctl enable --now chrony > /dev/null 2>&1

# 6. Force an immediate step-sync (ignores the usual drift threshold)
echo "[5/5] Forcing an initial time step-sync..."
sleep 2  # Give chrony a moment to initialize before stepping
chronyc makestep > /dev/null 2>&1

echo "========== ✅ Configuration complete =========="

# Print final state for a quick sanity check
echo -e "\n⏱️  Current system time:"
date
echo -e "\n📡 Chrony sync status:"
chronyc tracking | grep -E "Reference ID|Leap status"
