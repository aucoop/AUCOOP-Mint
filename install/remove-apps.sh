#!/bin/bash
# Remove unwanted default apps
#
# These are either redundant (replaced by Chrome/OnlyOffice),
# not useful for the target audience, or clutter.

REMOVE_PACKAGES=(
  # Replaced by Chrome
  firefox

  # Replaced by OnlyOffice
  libreoffice-common
  libreoffice-core
  libreoffice-calc
  libreoffice-writer
  libreoffice-impress
  libreoffice-draw
  libreoffice-math
  libreoffice-base-core
  libreoffice-gnome
  libreoffice-gtk3
  libreoffice-help-common
  libreoffice-style-colibre

  # Not useful for target audience
  transmission-gtk        # torrent client
  seahorse                # password/keyring manager GUI
  hypnotix                # IPTV player

  # Removed in earlier manual setup
  hexchat
  element-desktop
  matrix-synapse
  thunderbird
  mintchat
  warpinator
  webapp-manager
)

echo "Removing unwanted packages..."

# Build list of packages that are actually installed
TO_REMOVE=()
for pkg in "${REMOVE_PACKAGES[@]}"; do
  if dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
    TO_REMOVE+=("$pkg")
  fi
done

if [ ${#TO_REMOVE[@]} -eq 0 ]; then
  echo "  No unwanted packages found — already clean."
else
  echo "  Removing: ${TO_REMOVE[*]}"
  sudo apt-get purge -y "${TO_REMOVE[@]}"
  sudo apt-get autoremove -y
fi

# Keep ImageMagick CLI available but hide its desktop app launcher.
if [ -f /usr/share/applications/display-im6.q16.desktop ]; then
  echo "  Hiding ImageMagick desktop launcher..."
  sudo mkdir -p /usr/local/share/applications
  sudo cp /usr/share/applications/display-im6.q16.desktop /usr/local/share/applications/display-im6.q16.desktop
  sudo sed -i '/^NoDisplay=/d' /usr/local/share/applications/display-im6.q16.desktop
  printf 'NoDisplay=true\n' | sudo tee -a /usr/local/share/applications/display-im6.q16.desktop >/dev/null
  sudo update-desktop-database /usr/local/share/applications 2>/dev/null || true
fi
