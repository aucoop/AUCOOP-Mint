#!/bin/bash
# AUCOOP Recovery ISO Builder
#
# This script builds the AUCOOP recovery ISO from a Clonezilla image.
# The resulting ISO provides two boot options:
#   1. "Try AUCOOP" - Live session (boots from squashfs, no disk changes)
#   2. "Install AUCOOP" - Restores Clonezilla image to internal disk
#
# Prerequisites:
#   - A Clonezilla image directory (captured with ocs-sr)
#   - A Clonezilla live ISO (used as the base for the recovery environment)
#   - Root access (sudo) for loop-mounting and squashfs creation
#   - Packages: squashfs-tools, xorriso, syslinux-common, isolinux, clonezilla, drbl
#
# Usage:
#   sudo ./build-iso.sh <clonezilla-image-dir> <clonezilla-live-iso> <output-iso>
#
# Example:
#   sudo ./build-iso.sh \
#     /home/sergio/clonezilla-images/aucoop-mint22.3-2026-03 \
#     /home/sergio/mystuff/aucoop_iso/debian-live-for-ocs.iso \
#     /home/sergio/mystuff/aucoop_iso/aucoop-recovery.iso

set -euo pipefail

# ----- Configuration -----
IMAGE_NAME="aucoop-mint22.3-2026-03"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIGS_DIR="$SCRIPT_DIR/configs"
WORK_DIR=""
CLEANUP_DIRS=()
CLEANUP_MOUNTS=()

# ----- Helpers -----
die() { echo "ERROR: $*" >&2; exit 1; }

cleanup() {
    echo "Cleaning up..."
    for mnt in "${CLEANUP_MOUNTS[@]:-}"; do
        umount "$mnt" 2>/dev/null || true
    done
    for dir in "${CLEANUP_DIRS[@]:-}"; do
        rm -rf "$dir" 2>/dev/null || true
    done
}
trap cleanup EXIT

check_deps() {
    local missing=()
    for cmd in mksquashfs xorriso ocs-iso; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done
    if [ -f /usr/lib/ISOLINUX/isohdpfx.bin ]; then
        : # ok
    else
        missing+=("isolinux (isohdpfx.bin)")
    fi
    if [ ${#missing[@]} -gt 0 ]; then
        die "Missing dependencies: ${missing[*]}
Install with: sudo apt-get install squashfs-tools xorriso syslinux-common isolinux clonezilla drbl"
    fi
}

# ----- Parse arguments -----
if [ "$(id -u)" -ne 0 ]; then
    die "This script must be run as root (sudo)."
fi

if [ $# -lt 3 ]; then
    echo "Usage: $0 <clonezilla-image-dir> <clonezilla-live-iso> <output-iso>"
    echo ""
    echo "  clonezilla-image-dir  Path to the Clonezilla image directory"
    echo "  clonezilla-live-iso   Path to a Clonezilla live ISO (template)"
    echo "  output-iso            Path for the output recovery ISO"
    exit 1
fi

CLONEZILLA_IMAGE_DIR="$1"
CLONEZILLA_LIVE_ISO="$2"
OUTPUT_ISO="$3"

# ----- Validate inputs -----
[ -d "$CLONEZILLA_IMAGE_DIR" ] || die "Clonezilla image directory not found: $CLONEZILLA_IMAGE_DIR"
[ -f "$CLONEZILLA_LIVE_ISO" ] || die "Clonezilla live ISO not found: $CLONEZILLA_LIVE_ISO"
[ -f "$CONFIGS_DIR/grub.cfg" ] || die "grub.cfg not found in $CONFIGS_DIR"
[ -f "$CONFIGS_DIR/syslinux.cfg" ] || die "syslinux.cfg not found in $CONFIGS_DIR"
[ -f "$CONFIGS_DIR/custom-ocs" ] || die "custom-ocs not found in $CONFIGS_DIR"

check_deps

# ----- Step 1: Build base Clonezilla recovery ISO with ocs-iso -----
echo "============================================="
echo " Step 1/5: Building base Clonezilla ISO"
echo "============================================="

OCS_WORK_DIR=$(mktemp -d /tmp/aucoop-build.XXXXXX)
CLEANUP_DIRS+=("$OCS_WORK_DIR")

# Use ocs-iso to create the base recovery ISO
ocs-iso \
    -g en_US.UTF-8 \
    -k NONE \
    -s -x --restore-only \
    -j "$CLONEZILLA_LIVE_ISO" \
    -e "-x --restore-only" \
    -p reboot \
    -i "$CLONEZILLA_IMAGE_DIR" \
    "$IMAGE_NAME"

# ocs-iso creates the ISO in /tmp or current dir, find it
BASE_ISO=$(find /tmp /root -maxdepth 2 -name "*.iso" -newer "$CLONEZILLA_LIVE_ISO" 2>/dev/null | head -1)
if [ -z "$BASE_ISO" ]; then
    die "ocs-iso did not produce an ISO file"
fi
echo "Base ISO: $BASE_ISO"

# ----- Step 2: Extract base ISO for remastering -----
echo ""
echo "============================================="
echo " Step 2/5: Extracting base ISO"
echo "============================================="

ISO_MOUNT="$OCS_WORK_DIR/iso-mount"
ISO_REMASTER="$OCS_WORK_DIR/iso-remaster"
mkdir -p "$ISO_MOUNT" "$ISO_REMASTER"

mount -o loop,ro "$BASE_ISO" "$ISO_MOUNT"
CLEANUP_MOUNTS+=("$ISO_MOUNT")

rsync -a "$ISO_MOUNT/" "$ISO_REMASTER/"
chmod -R u+w "$ISO_REMASTER/"

umount "$ISO_MOUNT"
CLEANUP_MOUNTS=("${CLEANUP_MOUNTS[@]/$ISO_MOUNT}")

# Install custom-ocs script
cp "$CONFIGS_DIR/custom-ocs" "$ISO_REMASTER/pkg/custom-ocs"
chmod +x "$ISO_REMASTER/pkg/custom-ocs"

echo "Base ISO extracted and custom-ocs installed."

# ----- Step 3: Build squashfs for live "Try" mode -----
echo ""
echo "============================================="
echo " Step 3/5: Building live squashfs"
echo "============================================="

# Find the root partition in the Clonezilla image and rebuild a raw image
# to extract the filesystem. This requires partclone and the image metadata.
RAW_MOUNT="$OCS_WORK_DIR/raw-mount"
RAW_IMAGE="$OCS_WORK_DIR/root.raw"
mkdir -p "$RAW_MOUNT"

# Restore root partition from Clonezilla image using partclone
ROOT_IMG=$(find "$CLONEZILLA_IMAGE_DIR" -name "*.ext4-ptcl-img.gz*" | head -1)
if [ -z "$ROOT_IMG" ]; then
    die "Cannot find ext4 partclone image in $CLONEZILLA_IMAGE_DIR"
fi

echo "Restoring root partition from Clonezilla image..."
# Handle multi-part or single-part images
if ls "$CLONEZILLA_IMAGE_DIR"/*ext4-ptcl-img.gz.* >/dev/null 2>&1; then
    cat "$CLONEZILLA_IMAGE_DIR"/*ext4-ptcl-img.gz.* | gzip -dc | partclone.restore -C -s - -o "$RAW_IMAGE"
else
    gzip -dc "$ROOT_IMG" | partclone.restore -C -s - -o "$RAW_IMAGE"
fi

echo "Mounting restored root filesystem..."
mount -o ro,loop "$RAW_IMAGE" "$RAW_MOUNT"
CLEANUP_MOUNTS+=("$RAW_MOUNT")

# Extract kernel and initrd
mkdir -p "$ISO_REMASTER/casper"
KERNEL=$(ls "$RAW_MOUNT"/boot/vmlinuz-* 2>/dev/null | sort -V | tail -1)
INITRD=$(ls "$RAW_MOUNT"/boot/initrd.img-* 2>/dev/null | sort -V | tail -1)

if [ -z "$KERNEL" ] || [ -z "$INITRD" ]; then
    die "Cannot find kernel/initrd in $RAW_MOUNT/boot/"
fi

cp "$KERNEL" "$ISO_REMASTER/casper/vmlinuz"
cp "$INITRD" "$ISO_REMASTER/casper/initrd.img"
echo "Kernel: $(basename "$KERNEL")"
echo "Initrd: $(basename "$INITRD")"

# Build squashfs (exclude swapfile, lost+found, cdrom, tmp junk)
echo "Building squashfs (this may take several minutes)..."
mksquashfs "$RAW_MOUNT" "$ISO_REMASTER/casper/filesystem.squashfs" \
    -comp xz \
    -e "$RAW_MOUNT/swapfile" \
       "$RAW_MOUNT/lost+found" \
       "$RAW_MOUNT/cdrom" \
    -noappend

umount "$RAW_MOUNT"
CLEANUP_MOUNTS=("${CLEANUP_MOUNTS[@]/$RAW_MOUNT}")
rm -f "$RAW_IMAGE"

SQFS_SIZE=$(du -h "$ISO_REMASTER/casper/filesystem.squashfs" | cut -f1)
echo "Squashfs built: $SQFS_SIZE"

# ----- Step 4: Install boot menu configs -----
echo ""
echo "============================================="
echo " Step 4/5: Installing boot menu configs"
echo "============================================="

cp "$CONFIGS_DIR/grub.cfg" "$ISO_REMASTER/boot/grub/grub.cfg"
cp "$CONFIGS_DIR/syslinux.cfg" "$ISO_REMASTER/syslinux/syslinux.cfg"
cp "$CONFIGS_DIR/syslinux.cfg" "$ISO_REMASTER/syslinux/isolinux.cfg"

echo "GRUB and syslinux configs installed."

# ----- Step 5: Build final ISO -----
echo ""
echo "============================================="
echo " Step 5/5: Building final ISO"
echo "============================================="

xorriso -as mkisofs \
    -R -r -J -joliet-long -l -iso-level 3 \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -partition_offset 16 \
    -A "AUCOOP Recovery" \
    -V "AUCOOP-Recovery" \
    -b syslinux/isolinux.bin \
    -c syslinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
    -isohybrid-gpt-basdat \
    -isohybrid-apm-hfsplus \
    -o "$OUTPUT_ISO" \
    "$ISO_REMASTER/"

ISO_SIZE=$(du -h "$OUTPUT_ISO" | cut -f1)
echo ""
echo "============================================="
echo " Done!"
echo "============================================="
echo ""
echo "Output ISO: $OUTPUT_ISO ($ISO_SIZE)"
echo ""
echo "Boot menu options:"
echo "  1. Try AUCOOP Linux Image (live session)"
echo "  2. Install AUCOOP (restore image to disk)"
echo ""
echo "Flash to USB with:"
echo "  sudo dd if=$OUTPUT_ISO of=/dev/sdX bs=4M status=progress"
echo "  (or use Balena Etcher)"
