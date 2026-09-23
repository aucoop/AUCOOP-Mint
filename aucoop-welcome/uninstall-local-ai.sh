#!/bin/bash
#
# Remove the offline AI assistant and free the disk space it used
# (0.8 to 9.4 GB). Run as root; AUCOOP Welcome calls it via pkexec.

set -euo pipefail

TARGET_DIR="/opt/aucoop-ai"
RUNTIME_PATH="$TARGET_DIR/llamafile"
DESKTOP_FILE="/usr/share/applications/aucoop-local-ai.desktop"
ICON_TARGET="/usr/share/pixmaps/aucoop-local-ai.png"

TARGET_USER="${SUDO_USER:-}"
if [ -z "$TARGET_USER" ] && [ -n "${PKEXEC_UID:-}" ]; then
  TARGET_USER="$(id -nu "$PKEXEC_UID")"
fi

echo "Removing the offline AI assistant..."

# Match the exact command the assistant runs, not just the path.
pkill -f "$RUNTIME_PATH -m " 2>/dev/null || true
rm -rf "$TARGET_DIR"
rm -f "$DESKTOP_FILE" "$ICON_TARGET"
update-desktop-database /usr/share/applications >/dev/null 2>&1 || true

if [ -n "$TARGET_USER" ]; then
  rm -f "/home/$TARGET_USER/Desktop/aucoop-local-ai.desktop"
fi

echo "Offline AI assistant removed."
