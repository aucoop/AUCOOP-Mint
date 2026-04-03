#!/bin/bash
# Create OnlyOffice launchers with Microsoft-style names and icons
#
# Three launchers for the application menu:
#   - Word
#   - Excel
#   - PowerPoint
#
# Custom icons should be placed in assets/icons/:
#   - onlyoffice-document.png   (Word-style)
#   - onlyoffice-spreadsheet.png (Excel-style)
#   - onlyoffice-presentation.png (PowerPoint-style)
#
# If custom icons are not available, falls back to the default OnlyOffice icon.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICONS_DIR="$SCRIPT_DIR/assets/icons"
SYSTEM_ICON_DIR="/usr/share/icons/aucoop"
APPLICATIONS_DIR="$HOME/.local/share/applications"

mkdir -p "$APPLICATIONS_DIR"

# Install custom icons system-wide if available
if [ -d "$ICONS_DIR" ]; then
  sudo mkdir -p "$SYSTEM_ICON_DIR"
  for icon_file in "$ICONS_DIR"/onlyoffice-*.png; do
    [ -f "$icon_file" ] && sudo cp "$icon_file" "$SYSTEM_ICON_DIR/"
  done
fi

# Helper to pick the right icon
pick_icon() {
  local name="$1"
  if [ -f "$SYSTEM_ICON_DIR/$name.png" ]; then
    echo "$SYSTEM_ICON_DIR/$name.png"
  else
    echo "onlyoffice-desktopeditors"
  fi
}

[ -d "$HOME/Desktop" ] && rm -f "$HOME/Desktop"/*.desktop 2>/dev/null || true
[ -f "$APPLICATIONS_DIR/word.desktop" ] && rm -f "$APPLICATIONS_DIR/word.desktop"
[ -f "$APPLICATIONS_DIR/excel.desktop" ] && rm -f "$APPLICATIONS_DIR/excel.desktop"
[ -f "$APPLICATIONS_DIR/powerpoint.desktop" ] && rm -f "$APPLICATIONS_DIR/powerpoint.desktop"

create_launcher() {
  local file_path="$1"
  local name="$2"
  local comment="$3"
  local exec_cmd="$4"
  local icon_name="$5"
  local categories="$6"
  local keywords="$7"

  cat > "$file_path" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$name
Comment=$comment
Exec=$exec_cmd
Icon=$(pick_icon "$icon_name")
Terminal=false
Categories=$categories
Keywords=$keywords
StartupWMClass=ONLYOFFICE
StartupNotify=true
EOF
}

create_launcher "$APPLICATIONS_DIR/onlyoffice-word.desktop" "Word" "Create or edit documents" "/usr/bin/onlyoffice-desktopeditors --new:word" "onlyoffice-document" "Office;WordProcessor;" "word;document;documents;doc;docx;writer;text;"
create_launcher "$APPLICATIONS_DIR/onlyoffice-excel.desktop" "Excel" "Create or edit spreadsheets" "/usr/bin/onlyoffice-desktopeditors --new:cell" "onlyoffice-spreadsheet" "Office;Spreadsheet;" "excel;spreadsheet;spreadsheets;xls;xlsx;calc;sheet;"
create_launcher "$APPLICATIONS_DIR/onlyoffice-powerpoint.desktop" "PowerPoint" "Create or edit presentations" "/usr/bin/onlyoffice-desktopeditors --new:slide" "onlyoffice-presentation" "Office;Presentation;" "powerpoint;ppt;pptx;presentation;presentations;slides;"

# Make them executable for menu indexing and launch.
for f in "$APPLICATIONS_DIR"/onlyoffice-word.desktop "$APPLICATIONS_DIR"/onlyoffice-excel.desktop "$APPLICATIONS_DIR"/onlyoffice-powerpoint.desktop; do
  chmod +x "$f"
done

update-desktop-database "$APPLICATIONS_DIR" 2>/dev/null || true

echo "  Created Word, Excel, and PowerPoint menu launchers."
