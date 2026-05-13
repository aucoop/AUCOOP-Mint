# Repository Map

| Path | What it contains |
|---|---|
| [`install/`](https://github.com/aucoop/AUCOOP-Mint/tree/master/install) | Provisioning modules applied to fresh Mint installs |
| [`aucoop-welcome/`](https://github.com/aucoop/AUCOOP-Mint/tree/master/aucoop-welcome) | GTK first-login setup application |
| [`aucoop-workbench/`](https://github.com/aucoop/AUCOOP-Mint/tree/master/aucoop-workbench) | Device registration tooling submodule |
| [`vm/`](https://github.com/aucoop/AUCOOP-Mint/tree/master/vm) | QEMU-based test workflow |
| [`configs/`](https://github.com/aucoop/AUCOOP-Mint/tree/master/configs) | Recovery ISO and PXE deployment config |
| [`docs/technical-reference.md`](../technical-reference.md) | Full technical reference |

## Main entrypoints

- `boot.sh`: bootstrap entrypoint for a fresh Linux Mint machine
- `install.sh`: main AUCOOP provisioning entrypoint
- `build-iso.sh`: recovery ISO builder

## Documentation layout

- `docs/index.md`: docs landing page
- `docs/architecture/`: architecture and repository structure
- `docs/deployment/`: installation and deployment docs
- `docs/testing/`: test workflows
- `docs/technical-reference.md`: detailed long-form reference
