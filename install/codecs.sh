#!/bin/bash
# Install the standard Linux Mint multimedia codecs so common audio/video
# formats work out of the box.

if dpkg -l mint-meta-codecs 2>/dev/null | grep -q '^ii'; then
  echo "  Multimedia codecs are already installed."
else
  echo "  Installing multimedia codecs..."
  sudo apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mint-meta-codecs
fi
