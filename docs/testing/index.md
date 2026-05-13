# QEMU Testing Workflow

QEMU helpers live in [`vm/`](https://github.com/aucoop/AUCOOP-Mint/tree/master/vm) so changes can be tested on clean disposable overlays.

## Commands

```bash
./vm/create-base-disk.sh ~/vms/mint-base.qcow2 40G
./vm/install-mint.sh ~/Downloads/linuxmint-22.3-cinnamon-64bit.iso ~/vms/mint-base.qcow2
./vm/create-overlay.sh ~/vms/mint-base.qcow2 ~/vms/test.qcow2
./vm/run-overlay.sh ~/vms/test.qcow2 2222
```

Full flow: [`vm/README.md`](https://github.com/aucoop/AUCOOP-Mint/blob/master/vm/README.md)

## Why overlays

- repeatable test runs
- fast reset between installation attempts
- closer to real Mint desktop installs than cloud images
