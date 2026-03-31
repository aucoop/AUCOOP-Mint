# AUCOOP Mint

A lightweight, no-nonsense Linux Mint image for non-tech users with low-end refurbished hardware in mind. Built by [AUCOOP](https://aucoop.eu). 

## The idea

We take donated laptops, generally by the awesome [Labdoo](https://labdoo.org) project, refurbish them, and send them [where they're needed](https://aucoop.upc.edu/projectes-internacionals/). The software should get out of the way -- boot fast, feel familiar, and not confuse anyone. That's AUCOOP Mint.

## Principles

1. **Less is more.** No bloat, no clutter, no apps that don't add value. The fastest adoption curve is the one with the fewest surprises.
2. **Lightweight.** It has to run comfortably on every machine we deploy -- old and new alike.
3. **Windows-like UI.** Most of the people receiving these laptops know Windows. The desktop should feel familiar from day one.

## Why Linux Mint?

We considered the options:

| | Windows | Ubuntu | Linux Mint |
|---|---|---|---|
| Open Source | No | Yes | Yes |
| Lightweight | No | Yes | Yes |
| Windows-like UI | Yes | No | Yes |
| Office Desktop tools | Yes | Possible (open source) | Possible (open source) |

Linux Mint checks every box. It's open source, lightweight, and the Cinnamon desktop is the closest thing to Windows without being Windows. That makes it the right choice for our use case.

## What's on the desktop

The landing page is deliberately simple. Two things:

- **Google Chrome** -- the browser everyone already knows
- **OnlyOffice** (Document, Spreadsheet, Presentation) -- the office suite with the closest UI to Microsoft Office

We use custom desktop launchers with Microsoft-style iconography for the OnlyOffice apps, so users coming from Word, Excel, and PowerPoint see something they recognize.

Everything else follows from the principles: light mode always (windows default), Windows-like mouse cursor, and the Flatpak/Flathub app store available if someone wants to install more. But the default desktop is clean.

## Base image

- Linux Mint 22.3 "Xia" (Cinnamon edition)
- Kernel 6.14.0-37-generic
- Default user: `aucoop` / password: `aucoop`
- ~12GB disk usage, compresses to ~3.6GB Clonezilla image

## Deployment

This repo contains the build scripts and configs for deploying the image. Two methods:

### Method 1: USB Recovery ISO

A bootable USB with a clean boot menu:

- **Try AUCOOP Linux Image** (default) -- live session via casper/squashfs
- **Install AUCOOP** -- Clonezilla restore with safety prompts
- **Local operating system** -- boot from internal disk
- **Advanced options** -- failsafe mode, RAM loading, memtester, iPXE

Build it:

```bash
# Prerequisites
sudo apt-get install squashfs-tools xorriso syslinux-common isolinux clonezilla drbl partclone

# Build
sudo ./build-iso.sh \
    /path/to/clonezilla-images/aucoop-mint22.3-small \
    /path/to/debian-live-for-ocs.iso \
    /path/to/output/aucoop-recovery.iso
```

Flash to USB:

```bash
sudo dd if=aucoop-recovery.iso of=/dev/sdX bs=4M status=progress
```

Or use [Balena Etcher](https://etcher.balena.io/).

### Method 2: PXE Network Deployment

For deploying to many machines at once over an isolated Ethernet network. No USB drives, no manual steps -- just PXE boot and walk away.

Setup:

1. Connect a PXE server and all target laptops to a dedicated Ethernet switch
2. Assign a static IP to the server's Ethernet interface (e.g., `10.0.0.1/24`)
3. Install services: `isc-dhcp-server`, `tftpd-hpa`, `nfs-kernel-server`, `grub-efi-amd64-bin`
4. Extract Clonezilla Live files from the ISO into the TFTP and NFS directories
5. Generate a GRUB netboot binary with `grub-mknetdir`
6. Place the Clonezilla disk image in `/home/partimag/`
7. Place `configs/auto-restore.sh` in `/home/partimag/`
8. Place `configs/grub-pxe.cfg` at `/tftpboot/nbi_img/grub/grub.cfg`
9. **Disable Secure Boot** on all target machines (the unsigned GRUB binary is silently rejected otherwise -- no error, just falls through to IPv6)
10. PXE boot the target machines -- they auto-detect their disk and restore

Full step-by-step guide: [Community Network Handbook -- Laptop Deployment Guide](https://github.com/aucoop/Community-Network-Handbook)

#### PXE server file layout

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

## Disk size compatibility

This is a gotcha worth knowing about. The Clonezilla image stores the source partition layout. If the golden master was captured from a 466GB disk, restoring to a 238GB disk will fail -- even if the actual data is only 12GB. ext4 scatters blocks across the entire partition, and `partclone` fails when seeking beyond the target boundary.

**Fix:** Before capturing, shrink the source filesystem and partition:

```bash
# Connect the disk image
sudo modprobe nbd max_part=8
sudo qemu-nbd --connect=/dev/nbd0 disk-image.qcow2

# Shrink filesystem, then partition
sudo e2fsck -fy /dev/nbd0p2
sudo resize2fs /dev/nbd0p2 20G
sudo parted /dev/nbd0 resizepart 2 22100MB

# Verify and disconnect
sudo e2fsck -fy /dev/nbd0p2
sudo qemu-nbd --disconnect /dev/nbd0
```

Then capture the image. The `-k1` flag in `ocs-sr` proportionally expands partitions to fill the target disk during restore.

## Key ocs-sr flags

| Flag | Purpose |
|------|---------|
| `-k1` | Proportionally resize partitions to fill the target disk |
| `-icds` | Skip "destination disk too small" check (needed when source image disk > target, but partitions fit) |
| `-scr` | Skip checking if the image is restorable |
| `-j2` | Clone hidden data between MBR and first partition |
| `-e1 auto` | Auto-set EFI boot entry |
| `-e2` | Auto-set EFI boot in the target disk |
| `-p reboot` | Reboot after restore completes |

## Repository structure

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

## License

The scripts and configuration in this repository are released under the MIT License.
The Linux Mint operating system and all included software retain their original licenses.
