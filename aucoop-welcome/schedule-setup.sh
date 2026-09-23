#!/bin/bash
#
# Run essential-setup.sh tonight at 22:00, as root, with nobody at the
# computer. For slow connections, where downloading the updates during
# the day would take hours.
#
# - If the computer is off at 22:00, it runs the next time it is switched on.
# - It wakes the computer from sleep for it, where the hardware allows, and
#   keeps it from sleeping while it runs.
# - essential-setup.sh removes the timer once it succeeds; after a failure
#   it tries again the next night.

set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")" && pwd)"
UNIT_DIR="/etc/systemd/system"

cat > "$UNIT_DIR/aucoop-essential-setup.service" <<EOF
[Unit]
Description=AUCOOP Mint essential setup (scheduled)
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/systemd-inhibit --what=sleep:idle --who="AUCOOP Mint" --why="Installing updates" $APP_DIR/essential-setup.sh
StandardOutput=append:/var/log/aucoop-essential-setup.log
StandardError=inherit
EOF

cat > "$UNIT_DIR/aucoop-essential-setup.timer" <<EOF
[Unit]
Description=Run AUCOOP Mint essential setup tonight

[Timer]
OnCalendar=*-*-* 22:00:00
Persistent=true
WakeSystem=true

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now aucoop-essential-setup.timer
echo "Essential setup scheduled for 22:00."
