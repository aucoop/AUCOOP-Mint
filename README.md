# AUCOOP Deployment

Build scripts and configuration for deploying Linux Mint 22.3 (Cinnamon) to refurbished Lenovo laptops for the [AUCOOP](https://aucoop.eu) / [Labdoo](https://www.labdoo.org) project.

## Overview

This project creates a bootable USB recovery ISO that provides:

1. **Try AUCOOP Linux Image** -- boots a live session from the USB (no changes to disk)
2. **Install AUCOOP** -- restores a Clonezilla disk image to the internal hard drive (with double confirmation prompts)

## Target Hardware

- 7x Lenovo ThinkPad T460
- 2x Lenovo ThinkPad X260
- All: Intel i5-6200U, 8GB DDR4, Intel HD 520, ~466GB HDD (one 238GB SSD)

## Base Image

- Linux Mint 22.3 "Xia" (Cinnamon edition)
- Kernel 6.14.0-37-generic
- Default user: `aucoop` / password: `aucoop`
- ~12GB disk usage, compresses to ~3GB squashfs / ~4.4GB Clonezilla image

## Prerequisites

```bash
sudo apt-get install squashfs-tools xorriso syslinux-common isolinux clonezilla drbl partclone
```

## Building the ISO

You need:
1. A Clonezilla image directory (captured with `ocs-sr`)
2. A Clonezilla live ISO (used as the base template)

```bash
sudo ./build-iso.sh \
    /path/to/clonezilla-images/aucoop-mint22.3-2026-03 \
    /path/to/debian-live-for-ocs.iso \
    /path/to/output/aucoop-recovery.iso
```

The output ISO (~8GB) can be flashed to a USB drive with:

```bash
sudo dd if=aucoop-recovery.iso of=/dev/sdX bs=4M status=progress
```

Or use [Balena Etcher](https://etcher.balena.io/).

## Repository Structure

```
.
├── build-iso.sh           # Main build script
├── configs/
│   ├── grub.cfg           # UEFI boot menu (GRUB)
│   ├── syslinux.cfg       # Legacy BIOS boot menu (syslinux)
│   └── custom-ocs         # Clonezilla restore script with double confirmation
└── README.md
```

## Boot Menu

The ISO boots with a clean menu:

- **Try AUCOOP Linux Image** (default) -- live session via casper/squashfs
- **Install AUCOOP** -- Clonezilla restore with safety prompts
- **Local operating system** -- boot from internal disk
- **Advanced options** -- failsafe mode, RAM loading, memtester, iPXE

## PXE Deployment

For mass deployment to multiple machines, the Clonezilla image can also be served via PXE using DRBL/Clonezilla SE. See the [DRBL documentation](https://drbl.org/) for setup instructions.

## License

The scripts and configuration in this repository are released under the MIT License.
The Linux Mint operating system and all included software retain their original licenses.
