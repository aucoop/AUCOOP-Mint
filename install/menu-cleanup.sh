#!/bin/bash
# Reduce menu clutter without removing useful functionality.

echo "  Hiding duplicate and low-value menu entries..."

sudo mkdir -p /usr/local/share/applications

hide_launcher() {
  local source_file="$1"
  local target_file

  if [ ! -f "$source_file" ]; then
    return 0
  fi

  target_file="/usr/local/share/applications/$(basename "$source_file")"
  sudo cp "$source_file" "$target_file"
  sudo sed -i '/^NoDisplay=/d' "$target_file"
  printf 'NoDisplay=true\n' | sudo tee -a "$target_file" >/dev/null
}

# Keep the Word/Excel/PowerPoint launchers and hide the generic OnlyOffice entry.
hide_launcher /usr/share/applications/onlyoffice-desktopeditors.desktop

# Hide old Matrix webapp entry if it exists.
hide_launcher /usr/share/applications/webapp-OnlineChat4519.desktop

# Hide KDE duplicates on Cinnamon.
hide_launcher /usr/share/applications/mintinstall-kde.desktop
hide_launcher /usr/share/applications/mintstick-kde.desktop
hide_launcher /usr/share/applications/mintstick-format-kde.desktop
hide_launcher /usr/share/applications/mintupdate-kde.desktop

# Hide first-run clutter after setup is complete.
hide_launcher /usr/share/applications/mintwelcome.desktop
hide_launcher /usr/share/applications/mintbackup.desktop
hide_launcher /usr/share/applications/timeshift-gtk.desktop

# Disable Mint Welcome autostart explicitly.
if [ -f /etc/xdg/autostart/mintwelcome.desktop ]; then
  sudo cp /etc/xdg/autostart/mintwelcome.desktop /etc/xdg/autostart/mintwelcome.desktop.bak 2>/dev/null || true
  sudo sed -i '/^Hidden=/d' /etc/xdg/autostart/mintwelcome.desktop
  printf 'Hidden=true\n' | sudo tee -a /etc/xdg/autostart/mintwelcome.desktop >/dev/null
fi

sudo update-desktop-database /usr/local/share/applications 2>/dev/null || true
