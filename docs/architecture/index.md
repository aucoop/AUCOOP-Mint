# Architecture

AUCOOP Mint is a layer on top of Linux Mint, not a fork.

This means:

- Linux Mint handles installation, kernel, drivers, and system updates
- AUCOOP Mint applies configuration and apps on top
- Upgrades come from upstream Mint, not from us

---

## Layers

| Layer | Responsibility |
|-------|----------------|
| **Linux Mint** | Base OS, hardware support, security updates |
| **Provisioning scripts** | Remove bloat, install apps, configure desktop |
| **AUCOOP Welcome** | First-login setup: updates, drivers, optional modules |
| **Workbench** | Device registration for traceability |

---

## Why this approach

1. **No maintenance burden.** We don't maintain a distro. Mint does.
2. **Familiar upgrade path.** Users get normal Mint updates.
3. **Reproducible.** Same scripts, same result, every time.
4. **Transparent.** Everything is shell scripts you can read.

---

## Provisioning flow

```
Fresh Mint install
       ↓
   boot.sh / install.sh
       ↓
   Desktop configured, apps installed
       ↓
   First login → AUCOOP Welcome runs
       ↓
   Updates, codecs, drivers, optional extras
       ↓
   Ready to use
```

---

## What gets changed

**Removed:** Firefox, LibreOffice, Thunderbird, and other unused apps.

**Added:** Chrome, OnlyOffice, Flathub.

**Configured:** Light theme, Windows-like cursor, AUCOOP wallpaper, taskbar with pinned apps, familiar "Word/Excel/PowerPoint" launchers.

**Deferred to first login:** System updates, codecs, drivers, Kiwix, local AI, device registration.
