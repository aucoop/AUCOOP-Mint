# AUCOOP Deployment

Build scripts and configuration for deploying Linux Mint 22.3 (Cinnamon) to refurbished Lenovo laptops for the [AUCOOP](https://aucoop.eu) / [Labdoo](https://www.labdoo.org) project.

## Overview

This project provides two deployment methods:

1. **USB Recovery ISO** -- a bootable USB that provides "Try AUCOOP" (live session) and "Install AUCOOP" (Clonezilla restore) options
2. **PXE Network Deployment** -- mass deployment of the image to multiple machines over the network using a PXE server with DHCP + TFTP + NFS + Clonezilla

## Target Hardware

- 7x Lenovo ThinkPad T460
- 2x Lenovo ThinkPad X260
- All: Intel i5-6200U, 8GB DDR4, Intel HD 520
- Mixed storage: ~466GB HDD (SATA) and ~238GB SSD (SATA or NVMe)

## Base Image

- Linux Mint 22.3 "Xia" (Cinnamon edition)
- Kernel 6.14.0-37-generic
- Default user: `aucoop` / password: `aucoop`
- ~12GB disk usage, compresses to ~3GB squashfs / ~3.6GB Clonezilla image

## Prerequisites

```bash
sudo apt-get install squashfs-tools xorriso syslinux-common isolinux clonezilla drbl partclone
```

For PXE deployment, additionally:

```bash
sudo apt-get install isc-dhcp-server tftpd-hpa nfs-kernel-server grub-efi-amd64-bin
```

## Method 1: USB Recovery ISO

### Building the ISO

You need:
1. A Clonezilla image directory (captured with `ocs-sr`)
2. A Clonezilla live ISO (used as the base template)

```bash
sudo ./build-iso.sh \
    /path/to/clonezilla-images/aucoop-mint22.3-small \
    /path/to/debian-live-for-ocs.iso \
    /path/to/output/aucoop-recovery.iso
```

The output ISO (~8GB) can be flashed to a USB drive with:

```bash
sudo dd if=aucoop-recovery.iso of=/dev/sdX bs=4M status=progress
```

Or use [Balena Etcher](https://etcher.balena.io/).

### Boot Menu

The ISO boots with a clean menu:

- **Try AUCOOP Linux Image** (default) -- live session via casper/squashfs
- **Install AUCOOP** -- Clonezilla restore with safety prompts
- **Local operating system** -- boot from internal disk
- **Advanced options** -- failsafe mode, RAM loading, memtester, iPXE

## Method 2: PXE Network Deployment

For deploying to many machines at once over an isolated Ethernet network.

### Setup

1. Connect a PXE server and all target laptops to a dedicated Ethernet switch
2. Assign a static IP to the server's Ethernet interface (e.g., `10.0.0.1/24`)
3. Install the required services (`isc-dhcp-server`, `tftpd-hpa`, `nfs-kernel-server`, `grub-efi-amd64-bin`)
4. Extract Clonezilla Live files from the ISO into the TFTP and NFS directories
5. Generate a GRUB netboot binary with `grub-mknetdir`
6. Place the Clonezilla disk image in `/home/partimag/`
7. Place `configs/auto-restore.sh` in `/home/partimag/`
8. Place `configs/grub-pxe.cfg` at `/tftpboot/nbi_img/grub/grub.cfg`
9. **Disable Secure Boot** on all target machines (the unsigned GRUB binary will be silently rejected otherwise)
10. PXE boot the target machines -- they will auto-detect their disk and restore

For the full step-by-step guide, see the [Community Network Handbook -- Laptop Deployment Guide](https://github.com/aucoop/Community-Network-Handbook).

### PXE Server File Layout

```
/tftpboot/
├── nbi_img/                          # TFTP root
│   ├── bootx64.efi                   # GRUB EFI binary (from grub-mknetdir)
│   ├── grub/
│   │   ├── grub.cfg                  # PXE boot menu (use configs/grub-pxe.cfg)
│   │   ├── fonts/unicode.pf2
│   │   └── x86_64-efi/              # GRUB modules
│   └── clonezilla/live/
│       ├── vmlinuz                   # Clonezilla kernel (TFTP copy)
│       └── initrd.img               # Clonezilla initrd (TFTP copy)
└── clonezilla/live/                  # NFS-exported Clonezilla root
    ├── vmlinuz
    ├── initrd.img
    └── filesystem.squashfs

/home/partimag/                       # NFS-exported image repository
├── aucoop-mint22.3-small/            # Clonezilla disk image
│   ├── sda-pt.parted
│   ├── sda-gpt.sgdisk
│   ├── sda1.vfat-ptcl-img.gz
│   ├── sda2.ext4-ptcl-img.gz
│   └── ...
└── auto-restore.sh                   # Auto-detect disk script
```

## Important: Disk Size Compatibility

The Clonezilla image stores the source partition layout. When restoring to target disks, the source partition must be **smaller than or equal to** the smallest target disk.

If the golden master was captured from a large disk (e.g., 466GB), restoring to a smaller disk (e.g., 238GB) will fail even if the actual data is only 12GB. This is because the filesystem (ext4) scatters metadata and data blocks across the entire partition, and `partclone` will fail when seeking beyond the target partition boundary.

**Solution:** Before capturing the Clonezilla image, shrink the source filesystem and partition:

```bash
# 1. Connect the disk image (or use the real disk)
sudo modprobe nbd max_part=8
sudo qemu-nbd --connect=/dev/nbd0 disk-image.qcow2

# 2. Check and shrink the filesystem
sudo e2fsck -fy /dev/nbd0p2
sudo resize2fs /dev/nbd0p2 20G    # Must be larger than actual data usage

# 3. Shrink the partition to match
sudo parted /dev/nbd0 resizepart 2 22100MB  # Slightly larger than filesystem

# 4. Verify
sudo e2fsck -fy /dev/nbd0p2

# 5. Disconnect
sudo qemu-nbd --disconnect /dev/nbd0
```

Then capture the Clonezilla image from this resized disk. The `-k1` flag in `ocs-sr` will proportionally expand the partitions to fill the target disk during restore.

## Repository Structure

```
.
├── build-iso.sh           # Main ISO build script
├── configs/
│   ├── grub.cfg           # UEFI boot menu for USB ISO (GRUB)
│   ├── syslinux.cfg       # Legacy BIOS boot menu for USB ISO (syslinux)
│   ├── custom-ocs         # Clonezilla restore script with double confirmation (USB)
│   ├── grub-pxe.cfg       # GRUB boot menu for PXE server
│   └── auto-restore.sh    # Auto-detect disk script for PXE deployment
└── README.md
```

## Key Flags for ocs-sr

| Flag | Purpose |
|------|---------|
| `-k1` | Proportionally resize partitions to fill the target disk |
| `-icds` | Skip the "destination disk too small" check (required when source image disk > target, but source partitions fit) |
| `-scr` | Skip checking if the image is restorable |
| `-j2` | Clone hidden data between MBR and first partition |
| `-e1 auto` | Auto-set EFI boot entry |
| `-e2` | Auto-set EFI boot in the target disk |
| `-p reboot` | Reboot after restore completes |

## License

The scripts and configuration in this repository are released under the MIT License.
The Linux Mint operating system and all included software retain their original licenses.
