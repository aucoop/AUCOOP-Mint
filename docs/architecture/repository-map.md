# Repository Map

Quick reference for contributors.

---

## Key directories

| Path | Purpose |
|------|---------|
| `install/` | Shell scripts that configure the system |
| `assets/` | Wallpaper, icons, branding images |
| `aucoop-welcome/` | First-login GTK app |
| `aucoop-workbench/` | Device registration (git submodule) |
| `vm/` | QEMU test helpers |
| `configs/` | ISO and PXE boot configs |
| `docs/` | This documentation |

---

## Key files

| File | Purpose |
|------|---------|
| `boot.sh` | One-liner bootstrap for fresh Mint installs |
| `install.sh` | Main provisioning entrypoint |
| `build-iso.sh` | Create recovery ISO from Clonezilla image |
| `mkdocs.yml` | Documentation site config |

---

## Provisioning scripts

All in `install/`:

| Script | What it does |
|--------|--------------|
| `remove-apps.sh` | Uninstall default apps we don't need |
| `chrome.sh` | Install Chrome, set as default browser |
| `onlyoffice.sh` | Install OnlyOffice, set file associations |
| `theme.sh` | Light theme |
| `cursor.sh` | Windows-like cursor |
| `wallpaper.sh` | AUCOOP wallpaper |
| `panel.sh` | Pin apps to taskbar |
| `branding.sh` | AUCOOP logo and user avatar |
| `aucoop-welcome.sh` | Install first-login app |
| `aucoop-workbench.sh` | Install device registration tool |
