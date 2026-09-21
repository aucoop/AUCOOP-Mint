#!/bin/bash

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <module-id>"
  exit 1
fi

MODULE_ID="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODULES_JSON="$SCRIPT_DIR/modules.json"
# Welcome runs this through pkexec, which sets PKEXEC_UID rather than SUDO_USER.
TARGET_USER="${SUDO_USER:-}"
if [ -z "$TARGET_USER" ] && [ -n "${PKEXEC_UID:-}" ]; then
  TARGET_USER="$(id -nu "$PKEXEC_UID")"
fi
DESKTOP_DIR="${TARGET_USER:+/home/$TARGET_USER/Desktop}"
mapfile -t packages < <(python3 - "$MODULES_JSON" "$MODULE_ID" <<'PY'
import json
import sys

config_path = sys.argv[1]
module_id = sys.argv[2]

with open(config_path, 'r', encoding='utf-8') as fh:
    data = json.load(fh)

for module in data.get('optional_modules', []):
    if module.get('id') == module_id:
        for pkg in module.get('install', {}).get('packages', []):
            print(pkg)
        break
PY
)

if [ ${#packages[@]} -eq 0 ]; then
  echo "No installable packages found for module: $MODULE_ID"
  exit 1
fi

apt-get update -qq
apt-get install -y "${packages[@]}"

# The Ubuntu 24.04 kiwix package ships org.kiwix.desktop.desktop.
KIWIX_LAUNCHER=""
for candidate in /usr/share/applications/org.kiwix.desktop.desktop /usr/share/applications/kiwix.desktop; do
  if [ -f "$candidate" ]; then
    KIWIX_LAUNCHER="$candidate"
    break
  fi
done

if [ "$MODULE_ID" = "kiwix" ] && [ -n "${DESKTOP_DIR:-}" ] && [ -n "$KIWIX_LAUNCHER" ]; then
  mkdir -p "$DESKTOP_DIR"
  cp "$KIWIX_LAUNCHER" "$DESKTOP_DIR/kiwix.desktop"
  chown "$TARGET_USER:$TARGET_USER" "$DESKTOP_DIR/kiwix.desktop"
  chmod +x "$DESKTOP_DIR/kiwix.desktop"
  sudo -u "$TARGET_USER" gio set "$DESKTOP_DIR/kiwix.desktop" metadata::trusted true 2>/dev/null || true
fi
