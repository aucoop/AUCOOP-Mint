# Quick Start

## One command

On a fresh Linux Mint 22.x Cinnamon install:

```bash
wget -qO- https://raw.githubusercontent.com/aucoop/AUCOOP-Mint/master/boot.sh | bash
```

That's it. Reboot when done.

---

## Manual install

```bash
git clone https://github.com/aucoop/AUCOOP-Mint.git
cd AUCOOP-Mint
git submodule update --init --recursive
bash install.sh
```

---

## What happens

1. **Provisioning** — Removes bloat, installs Chrome and OnlyOffice, applies desktop config.
2. **First login** — AUCOOP Welcome opens automatically to finish setup.
3. **Done** — Machine is ready to hand over.

---

## Requirements

- Linux Mint 22.x Cinnamon (fresh install)
- Internet connection during setup
- Run as desktop user, not root

---

## After install

AUCOOP Welcome handles:

- System updates
- Multimedia codecs
- Recommended drivers
- Optional: Kiwix (offline Wikipedia), local AI
- Optional: Device registration
