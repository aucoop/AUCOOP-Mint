#!/bin/bash
# AUCOOP PXE Auto-Restore Script
#
# This script auto-detects the target disk and runs Clonezilla restore.
# It is called from grub-pxe.cfg via the ocs_live_run kernel parameter.
#
# Place this script in /home/partimag/ on the PXE server (NFS-exported).

set -e

IMAGE_NAME="aucoop-mint22.3-small"

# Auto-detect target disk (NVMe first, then SATA, then virtio)
if [ -b /dev/nvme0n1 ]; then
  DISK=nvme0n1
elif [ -b /dev/sda ]; then
  DISK=sda
elif [ -b /dev/vda ]; then
  DISK=vda
else
  echo "ERROR: No suitable disk found!"
  lsblk
  read -p "Press Enter to continue..."
  exit 1
fi

echo "======================================"
echo "  Detected target disk: /dev/$DISK"
echo "======================================"
/usr/sbin/ocs-sr -g auto -e1 auto -e2 -r -j2 -icds -k1 -scr -p reboot restoredisk "$IMAGE_NAME" "$DISK"
