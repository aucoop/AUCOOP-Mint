# Architecture Overview

AUCOOP Mint stays layered on top of upstream Linux Mint instead of replacing it.

| Layer | Role |
|---|---|
| **Linux Mint** | Installer, kernel, drivers, repositories, upgrades |
| **`install.sh` + `install/*.sh`** | Base AUCOOP provisioning |
| **AUCOOP Welcome** | First-login setup and optional modules |
| **Workbench** | Device registration and circular tracking |
| **Recovery / PXE tooling** | Batch deployment paths for real operations |

## Provisioning modules

Provisioning is split into small scripts with one clear responsibility each:

| Script | Purpose |
|---|---|
| `remove-apps.sh` | Remove default software that adds noise |
| `chrome.sh` | Install Chrome and set it as default browser |
| `onlyoffice.sh` | Install office apps with familiar document associations |
| `theme.sh`, `cursor.sh`, `wallpaper.sh` | Make desktop feel consistent and familiar |
| `panel.sh`, `menu-button.sh`, `search-aliases.sh` | Reduce navigation friction |
| `branding.sh` | Add AUCOOP identity to the system |
| `aucoop-welcome.sh` | Install first-login setup app |
| `aucoop-workbench.sh` | Install registration tooling |

## First-login completion

After provisioning, AUCOOP Welcome completes:

- system updates
- multimedia codecs
- recommended drivers
- optional Kiwix and local AI modules
- device registration handoff
