#!/bin/bash

set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <devicehub-url> <token>"
  exit 1
fi

DEVICEHUB_URL="$1"
TOKEN="$2"
WORKBENCH_DIR="${WORKBENCH_DIR:-/opt/aucoop-workbench}"
REQUIRED_COMMANDS=(python3 smartctl dmidecode inxi qrencode lsblk)

if [ "$(id -u)" -ne 0 ]; then
  echo "Workbench registration must run as root."
  exit 1
fi

if [ ! -f "$WORKBENCH_DIR/workbench-script.py" ]; then
  echo "Workbench not found at $WORKBENCH_DIR"
  exit 1
fi

missing_commands=()
for cmd in "${REQUIRED_COMMANDS[@]}"; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    missing_commands+=("$cmd")
  fi
done

if [ ${#missing_commands[@]} -gt 0 ]; then
  echo "Missing Workbench dependencies: ${missing_commands[*]}"
  echo "AUCOOP Mint must install Workbench dependencies before registration can run."
  exit 1
fi

# Ensure TERM is set to a sane value. Under pkexec/SSH, TERM may be "unknown"
# which causes inxi's --output json --output-file print to fail with
# "Error 1: You can't run option help in an IRC client!"
export TERM="${TERM:-xterm}"
if [ "$TERM" = "unknown" ] || [ "$TERM" = "dumb" ]; then
  export TERM="xterm"
fi

TMP_DIR="$(mktemp -d)"
CONFIG_FILE="$TMP_DIR/settings.ini"

cat > "$CONFIG_FILE" <<EOF
[settings]
url = $DEVICEHUB_URL
token = $TOKEN
http_max_retries = 3
http_retry_delay = 3
disable_qr = False
path = $TMP_DIR
EOF

cd "$WORKBENCH_DIR"
python3 workbench-script.py --config "$CONFIG_FILE"
