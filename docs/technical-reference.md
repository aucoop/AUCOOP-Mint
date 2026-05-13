# Technical Reference

Deep details for contributors and advanced users.

---

## Design principles

1. **Less is more.** Remove apps that don't add value. Fewer surprises = faster adoption.
2. **Lightweight.** Must run well on old hardware.
3. **Windows-like.** Most recipients know Windows. Match that mental model.

---

## Why Linux Mint?

| Criteria | Windows | Ubuntu | Linux Mint |
|----------|---------|--------|------------|
| Open source | No | Yes | Yes |
| Lightweight | No | Yes | Yes |
| Windows-like UI | Yes | No | Yes |

Linux Mint with Cinnamon is the closest to Windows without being Windows.

---

## Apps removed

- Firefox → replaced by Chrome
- LibreOffice → replaced by OnlyOffice
- Thunderbird, HexChat, Mint Chat, Warpinator, Webapp Manager
- Transmission, Seahorse, Hypnotix

## Apps installed

- **Chrome** — default browser
- **OnlyOffice** — handles .doc, .docx, .xls, .xlsx, .ppt, .pptx, .odt, .ods, .odp
- **Flathub** — added to Software Manager

---

## Desktop customization

| Setting | Value |
|---------|-------|
| Theme | Mint-Y-Blue (light) |
| Cursor | DMZ-White |
| Wallpaper | AUCOOP branded |
| Panel | Chrome, Word, Excel, PowerPoint, Software Manager |
| Menu search | "app store", "download" → Software Manager |

Office launchers use familiar names: Word, Excel, PowerPoint.

---

## First-boot tasks (AUCOOP Welcome)

These run after provisioning, on first login:

- System updates
- Multimedia codecs
- Hardware drivers (`ubuntu-drivers autoinstall`)
- Optional: Kiwix, local AI
- Optional: Workbench device registration

AUCOOP Welcome removes its autostart entry after completing essential setup.

---

## Deployment workflows

### Single machine

1. Install Linux Mint 22.x Cinnamon
2. Run `boot.sh`
3. Log in, let AUCOOP Welcome finish
4. Reboot

### Batch deployment (Clonezilla)

1. Prepare one reference machine with AUCOOP Mint
2. Capture Clonezilla image
3. Deploy to target machines via USB or PXE

### Recovery ISO

```bash
sudo apt install squashfs-tools xorriso syslinux-common isolinux clonezilla drbl partclone

sudo ./build-iso.sh \
    /path/to/clonezilla-image \
    /path/to/debian-live-for-ocs.iso \
    /path/to/output.iso
```

### PXE deployment

For deploying over network to many machines. See: [Community Network Handbook](https://github.com/aucoop/Community-Network-Handbook)

---

## Base image specs

- Linux Mint 22.3 "Xia" (Cinnamon)
- Default user: `aucoop` / `aucoop`
- Disk usage: ~12GB
- Compressed image: ~3.6GB

---

## License

Scripts and configuration: MIT License.

Linux Mint and bundled software retain their original licenses.
