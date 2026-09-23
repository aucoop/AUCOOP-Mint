#!/bin/bash
#
# AUCOOP Mint bootstrap
#
# Run on a fresh Linux Mint 22.x install:
#   wget -qO- https://raw.githubusercontent.com/aucoop/AUCOOP-Mint/master/boot.sh | bash
#

set -e

REPO_URL="https://github.com/aucoop/AUCOOP-Mint.git"
INSTALL_DIR="$HOME/.aucoop-mint"

# Ensure git is available (should be on Mint by default)
echo ""
echo "  Downloading AUCOOP Mint..."

if ! command -v git &>/dev/null; then
  sudo apt-get update -qq && sudo apt-get install -y -qq git >/dev/null
fi

# Clone or update the repo
if [ -d "$INSTALL_DIR" ]; then
  git -C "$INSTALL_DIR" pull -q --ff-only
else
  git clone -q --recurse-submodules "$REPO_URL" "$INSTALL_DIR"
fi

# Ensure submodules are initialized and up to date.
git -C "$INSTALL_DIR" submodule update -q --init --recursive

# Hand off to install.sh
cd "$INSTALL_DIR"
bash install.sh
