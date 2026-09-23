#!/bin/bash
#
# Updates, codecs and drivers. Run as root, either by AUCOOP Welcome
# (through pkexec) or at night by the timer from schedule-setup.sh.

set -euo pipefail

STATUS_FILE="/var/lib/aucoop-welcome/essential-setup-complete"
TIMER_UNIT="aucoop-essential-setup.timer"
UNIT_DIR="/etc/systemd/system"

export DEBIAN_FRONTEND=noninteractive

# A power cut during a previous run can leave packages half-installed.
# Finish them first so running this again repairs the system.
echo "Checking for unfinished updates..."
dpkg --configure -a
apt-get install -f -y

echo "Installing initial updates..."
apt-get update -qq
apt-get upgrade -y
echo "Installing multimedia codecs..."
apt-get install -y mint-meta-codecs

if command -v ubuntu-drivers >/dev/null 2>&1; then
  echo "Installing recommended hardware drivers..."
  ubuntu-drivers autoinstall || true
fi

# Tell AUCOOP Welcome it's done, even if nobody was logged in.
mkdir -p "$(dirname "$STATUS_FILE")"
date -Iseconds > "$STATUS_FILE"

# A night-time run is no longer needed once this has succeeded.
if [ -f "$UNIT_DIR/$TIMER_UNIT" ]; then
  systemctl disable --now "$TIMER_UNIT" >/dev/null 2>&1 || true
  rm -f "$UNIT_DIR/$TIMER_UNIT" "$UNIT_DIR/aucoop-essential-setup.service"
  systemctl daemon-reload || true
fi

echo "Essential AUCOOP setup is complete."
