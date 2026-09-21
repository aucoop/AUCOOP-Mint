#!/bin/bash

set -euo pipefail

echo "Installing initial updates..."
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
echo "Installing multimedia codecs..."
DEBIAN_FRONTEND=noninteractive apt-get install -y mint-meta-codecs

if command -v ubuntu-drivers >/dev/null 2>&1; then
  echo "Installing recommended hardware drivers..."
  ubuntu-drivers autoinstall || true
fi

echo "Essential AUCOOP setup is complete."
