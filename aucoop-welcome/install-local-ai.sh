#!/bin/bash

set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$APP_DIR/modules.json"
TARGET_DIR="/opt/aucoop-ai"
RUNNER_SCRIPT="$TARGET_DIR/run-local-ai.sh"
DESKTOP_FILE="/usr/share/applications/aucoop-local-ai.desktop"
DESKTOP_DIR="${SUDO_USER:+/home/$SUDO_USER/Desktop}"
ICON_SOURCE="$APP_DIR/assets/llamafile-icon.png"
ICON_TARGET="/usr/share/pixmaps/aucoop-local-ai.png"
REQUESTED_MODEL_ID="${1:-auto}"

readarray -t MODEL_INFO < <(python3 - "$CONFIG_FILE" "$REQUESTED_MODEL_ID" <<'PY'
import json
import re
import urllib.request
from pathlib import Path
import sys

cfg = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
requested_model_id = sys.argv[2]

mem_total_kb = 0
with open('/proc/meminfo', 'r', encoding='utf-8') as fh:
    for line in fh:
        if line.startswith('MemTotal:'):
            mem_total_kb = int(line.split()[1])
            break

ram_gb = mem_total_kb / 1024 / 1024
models = sorted(cfg['local_ai'].get('models', []), key=lambda m: m.get('min_ram_gb', 0))
selected = None

if requested_model_id != 'auto':
    for model in models:
        if model.get('id') == requested_model_id:
            selected = model
            break
else:
    for model in models:
        if ram_gb >= model.get('min_ram_gb', 0):
            selected = model
    if not selected and models:
        selected = models[0]

if not selected:
    raise SystemExit('No suitable local AI model configured for this machine.')

req = urllib.request.Request('https://api.github.com/repos/Mozilla-Ocho/llamafile/releases/latest')
with urllib.request.urlopen(req) as resp:
    release_data = json.loads(resp.read().decode('utf-8'))

runtime_url = None
runtime_filename = None
for asset in release_data.get('assets', []):
    if re.fullmatch(r'llamafile-[0-9.]+', asset.get('name', '')):
        runtime_url = asset['browser_download_url']
        runtime_filename = asset['name']
        break

if not runtime_url or not runtime_filename:
    raise SystemExit('Could not find latest standalone llamafile runtime.')

print(selected['name'])
print(runtime_url)
print(runtime_filename)
print(selected['model_url'])
print(selected['model_filename'])
print(str(selected.get('port', 8091)))
PY
)

MODEL_NAME="${MODEL_INFO[0]}"
RUNTIME_URL="${MODEL_INFO[1]}"
RUNTIME_FILENAME="${MODEL_INFO[2]}"
MODEL_URL="${MODEL_INFO[3]}"
MODEL_FILENAME="${MODEL_INFO[4]}"
PORT="${MODEL_INFO[5]}"
RUNTIME_PATH="$TARGET_DIR/llamafile"
MODEL_PATH="$TARGET_DIR/$MODEL_FILENAME"

echo "Installing local AI assistant: $MODEL_NAME"

mkdir -p "$TARGET_DIR"
pkill -f "$TARGET_DIR/" 2>/dev/null || true
find "$TARGET_DIR" -maxdepth 1 -type f \( -name '*.gguf' -o -name '*.llamafile' -o -name 'llamafile-*' -o -name 'llamafile' \) -delete

curl -L "$RUNTIME_URL" -o "$TARGET_DIR/$RUNTIME_FILENAME"
install -m 755 "$TARGET_DIR/$RUNTIME_FILENAME" "$RUNTIME_PATH"
rm -f "$TARGET_DIR/$RUNTIME_FILENAME"

curl -L "$MODEL_URL" -o "$MODEL_PATH"

cat > "$RUNNER_SCRIPT" <<EOF
#!/bin/bash
set -euo pipefail
pkill -f '$RUNTIME_PATH -m $MODEL_PATH --server' 2>/dev/null || true
nohup '$RUNTIME_PATH' -m '$MODEL_PATH' --ctx-size 4096 --server --host 127.0.0.1 --port $PORT >/tmp/aucoop-local-ai.log 2>&1 < /dev/null &
sleep 3
xdg-open 'http://127.0.0.1:$PORT'
EOF

chmod +x "$RUNNER_SCRIPT"

if [ -f "$ICON_SOURCE" ]; then
  install -m 644 "$ICON_SOURCE" "$ICON_TARGET"
fi

cat > /tmp/aucoop-local-ai.desktop <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Offline AI assistant
Comment=Run a local AI assistant in AUCOOP Mint
Exec=$RUNNER_SCRIPT
Icon=$ICON_TARGET
Terminal=false
Categories=Utility;Education;
Keywords=ai;assistant;offline;chat;llamafile;aucoop;
EOF

install -m 644 /tmp/aucoop-local-ai.desktop "$DESKTOP_FILE"
update-desktop-database /usr/share/applications >/dev/null 2>&1 || true

if [ -n "${DESKTOP_DIR:-}" ]; then
  mkdir -p "$DESKTOP_DIR"
  cp "$DESKTOP_FILE" "$DESKTOP_DIR/aucoop-local-ai.desktop"
  chown "$SUDO_USER:$SUDO_USER" "$DESKTOP_DIR/aucoop-local-ai.desktop"
  chmod +x "$DESKTOP_DIR/aucoop-local-ai.desktop"
  sudo -u "$SUDO_USER" gio set "$DESKTOP_DIR/aucoop-local-ai.desktop" metadata::trusted true 2>/dev/null || true
fi

echo "Installed local AI assistant launcher."
