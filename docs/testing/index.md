# Testing

Test changes in a VM before deploying to real hardware.

---

## Setup

Use QEMU with overlay disks. This lets you reset to a clean state instantly.

### 1. Create base disk

```bash
./vm/create-base-disk.sh ~/vms/mint-base.qcow2 40G
```

### 2. Install Mint

```bash
./vm/install-mint.sh ~/Downloads/linuxmint-22.3-cinnamon-64bit.iso ~/vms/mint-base.qcow2
```

During install:
- Create user `aucoop` with password `aucoop`
- After first boot: `sudo apt install openssh-server`

### 3. Create test overlay

```bash
./vm/create-overlay.sh ~/vms/mint-base.qcow2 ~/vms/test.qcow2
```

### 4. Run test VM

```bash
./vm/run-overlay.sh ~/vms/test.qcow2 2222
```

### 5. SSH in and test

```bash
ssh -p 2222 aucoop@127.0.0.1
```

---

## Reset

Delete the overlay and create a new one. Base disk stays clean.

```bash
rm ~/vms/test.qcow2
./vm/create-overlay.sh ~/vms/mint-base.qcow2 ~/vms/test.qcow2
```

---

## Why not cloud images?

AUCOOP Mint modifies the Cinnamon desktop: themes, icons, launchers, wallpaper. Cloud images don't have a desktop session. Use the real Mint ISO.
