#!/bin/bash
# Install a packaged copy of Workbench for AUCOOP Mint.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$SCRIPT_DIR/aucoop-workbench"
TARGET_DIR="/opt/aucoop-workbench"

echo "  Installing AUCOOP Workbench..."

sudo mkdir -p "$TARGET_DIR"
sudo cp -r "$SOURCE_DIR"/* "$TARGET_DIR/"
sudo chmod +x "$TARGET_DIR/workbench-script.py"

# Runtime dependencies needed by workbench-script.py to gather evidence.
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  smartmontools \
  lshw \
  hwinfo \
  dmidecode \
  inxi \
  qrencode \
  pciutils
