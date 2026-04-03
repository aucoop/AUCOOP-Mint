#!/bin/bash
# Install recommended hardware drivers automatically.

if ! command -v ubuntu-drivers >/dev/null 2>&1; then
  echo "  ubuntu-drivers not available — skipping driver auto-install."
  return 0
fi

echo "  Installing recommended hardware drivers..."
sudo ubuntu-drivers autoinstall || true
