#!/bin/bash
# Replace Software Manager (mintinstall) icon with a download-arrow icon
#
# The default mintinstall icon looks like a shopping bag — confusing.
# We replace it with a recognizable download-arrow icon across all sizes
# in the Mint-Y icon theme (which Mint-Y-Blue inherits from).
#
# Pre-generated icon sizes are stored at assets/software-manager-icon-sizes/.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICON_ASSETS_DIR="$SCRIPT_DIR/assets/software-manager-icon-sizes"
ICON_THEME_DIR="/usr/share/icons/Mint-Y"

if [ ! -d "$ICON_ASSETS_DIR" ]; then
  echo "  WARNING: Icon size assets not found at $ICON_ASSETS_DIR — skipping."
  return 0
fi

echo "  Replacing Software Manager icon in Mint-Y theme..."

# Standard sizes in the Mint-Y icon theme
SIZES=(16 22 24 32 48 64 96 128 256 512)

for size in "${SIZES[@]}"; do
  target_dir="$ICON_THEME_DIR/apps/$size"
  source_icon="$ICON_ASSETS_DIR/${size}.png"
  if [ -d "$target_dir" ] && [ -f "$source_icon" ]; then
    sudo cp "$source_icon" "$target_dir/mintinstall.png"
  fi

  # HiDPI @2x variant
  target_dir_2x="$ICON_THEME_DIR/apps/${size}@2x"
  source_icon_2x="$ICON_ASSETS_DIR/${size}@2x.png"
  if [ -d "$target_dir_2x" ] && [ -f "$source_icon_2x" ]; then
    sudo cp "$source_icon_2x" "$target_dir_2x/mintinstall.png"
  fi
done

# Refresh icon cache
sudo gtk-update-icon-cache -f "$ICON_THEME_DIR" 2>/dev/null || true
