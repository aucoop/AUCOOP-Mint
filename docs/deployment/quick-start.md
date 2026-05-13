# Quick Start

On a fresh Linux Mint 22.x Cinnamon install, run:

```bash
wget -qO- https://raw.githubusercontent.com/aucoop/AUCOOP-Mint/master/boot.sh | bash
```

Manual install:

```bash
git clone https://github.com/aucoop/AUCOOP-Mint.git
cd AUCOOP-Mint
git submodule update --init --recursive
bash install.sh
```

## Flow

1. Install Linux Mint 22.x Cinnamon.
2. Run `boot.sh` or `install.sh`.
3. Log in and let AUCOOP Welcome finish setup.
4. Reboot when setup completes.

## Notes

- Run `install.sh` as the desktop user, not as root.
- Installer uses `sudo` when needed.
- AUCOOP Welcome handles hardware-sensitive and optional steps after login.
