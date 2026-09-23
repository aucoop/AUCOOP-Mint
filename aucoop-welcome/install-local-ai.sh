#!/bin/bash
#
# Install the offline AI assistant: the llamafile runtime plus one model,
# and a launcher for it. Run as root (AUCOOP Welcome calls it via pkexec).
#
# Usage: install-local-ai.sh [model-id|auto]

set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$APP_DIR/modules.json"
TARGET_DIR="/opt/aucoop-ai"
RUNNER_SCRIPT="$TARGET_DIR/run-local-ai.sh"
WATCHDOG_SCRIPT="$TARGET_DIR/idle-watchdog.sh"
DESKTOP_FILE="/usr/share/applications/aucoop-local-ai.desktop"
# Welcome runs this through pkexec, which sets PKEXEC_UID rather than SUDO_USER.
TARGET_USER="${SUDO_USER:-}"
if [ -z "$TARGET_USER" ] && [ -n "${PKEXEC_UID:-}" ]; then
  TARGET_USER="$(id -nu "$PKEXEC_UID")"
fi
DESKTOP_DIR="${TARGET_USER:+/home/$TARGET_USER/Desktop}"
ICON_SOURCE="$APP_DIR/assets/aucoop-local-ai.png"
[ -f "$ICON_SOURCE" ] || ICON_SOURCE="$APP_DIR/assets/llamafile-icon.png"
ICON_TARGET="/usr/share/pixmaps/aucoop-local-ai.png"
REQUESTED_MODEL_ID="${1:-auto}"

# Everything about the model and the runtime comes from modules.json, which
# pins the runtime version and the checksum of every file we download.
readarray -t MODEL_INFO < <(python3 - "$CONFIG_FILE" "$REQUESTED_MODEL_ID" <<'PY'
import json
from pathlib import Path
import sys

cfg = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))['local_ai']
requested_model_id = sys.argv[2]

mem_total_kb = 0
with open('/proc/meminfo', 'r', encoding='utf-8') as fh:
    for line in fh:
        if line.startswith('MemTotal:'):
            mem_total_kb = int(line.split()[1])
            break

ram_gb = mem_total_kb / 1024 / 1024
models = sorted(cfg.get('models', []), key=lambda m: m.get('min_ram_gb', 0))
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

runtime = cfg['runtime']
for value in (selected['name'], runtime['url'], runtime['filename'], runtime['sha256'],
              runtime['size_bytes'], selected['model_url'], selected['model_filename'],
              selected['sha256'], selected['size_bytes'], selected.get('port', 8091),
              selected.get('min_ram_gb', 0), round(ram_gb, 1),
              # "8 GB" machines report ~7.8 GB, so allow half a gigabyte.
              int(ram_gb + 0.5 >= selected.get('min_ram_gb', 0))):
    print(value)
PY
)

MODEL_NAME="${MODEL_INFO[0]}"
RUNTIME_URL="${MODEL_INFO[1]}"
RUNTIME_FILENAME="${MODEL_INFO[2]}"
RUNTIME_SHA256="${MODEL_INFO[3]}"
RUNTIME_SIZE="${MODEL_INFO[4]}"
MODEL_URL="${MODEL_INFO[5]}"
MODEL_FILENAME="${MODEL_INFO[6]}"
MODEL_SHA256="${MODEL_INFO[7]}"
MODEL_SIZE="${MODEL_INFO[8]}"
PORT="${MODEL_INFO[9]}"
MODEL_MIN_RAM="${MODEL_INFO[10]}"
RAM_GB="${MODEL_INFO[11]}"
RAM_OK="${MODEL_INFO[12]}"
RUNTIME_PATH="$TARGET_DIR/llamafile"
MODEL_PATH="$TARGET_DIR/$MODEL_FILENAME"
RUNTIME_STAMP="$TARGET_DIR/.runtime-version"

echo "Installing local AI assistant: $MODEL_NAME"

# ── Can this computer actually run and store it? ──────────────────

if [ "$RAM_OK" != "1" ]; then
  echo "ERROR: $MODEL_NAME needs about $MODEL_MIN_RAM GB of memory, this computer has $RAM_GB GB." >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"

NEEDED=$MODEL_SIZE
[ -f "$MODEL_PATH" ] && NEEDED=0
if [ ! -x "$RUNTIME_PATH" ] || [ "$(cat "$RUNTIME_STAMP" 2>/dev/null)" != "$RUNTIME_FILENAME" ]; then
  NEEDED=$((NEEDED + RUNTIME_SIZE))
fi
# A tenth on top, so the disk doesn't end up completely full.
NEEDED=$((NEEDED + NEEDED / 10))
FREE=$(($(stat -f -c '%a * %S' "$TARGET_DIR")))
if [ "$FREE" -lt "$NEEDED" ]; then
  echo "ERROR: not enough disk space. Need about $((NEEDED / 1000000)) MB, $((FREE / 1000000)) MB free." >&2
  exit 1
fi

# Stop a running assistant, matching the exact command we start it with:
# "$TARGET_DIR/" alone would also kill a terminal that merely mentions the path.
pkill -f "$RUNTIME_PATH -m " 2>/dev/null || true

# Remove other models and runtimes, but keep this model and any partial
# downloads, so a retry on a slow connection continues where it stopped.
find "$TARGET_DIR" -maxdepth 1 -type f \( -name '*.gguf' -o -name '*.llamafile' -o -name 'llamafile-*' \) \
  ! -name "$MODEL_FILENAME" ! -name "$RUNTIME_FILENAME" -delete

# ── Download, resume and verify ───────────────────────────────────

# download url path sha256: resumes a partial download, retries on dropped
# connections, and checks the file before giving it its final name.
download() {
  local url="$1" path="$2" sha="$3" got
  if [ -f "$path" ]; then
    return 0
  fi
  curl -fL -C - --retry 10 --retry-delay 5 --retry-all-errors -o "$path.part" "$url"
  got="$(sha256sum "$path.part" | cut -d' ' -f1)"
  if [ "$got" != "$sha" ]; then
    # A resumed download of a file that changed on the server ends up here.
    rm -f "$path.part"
    echo "ERROR: downloaded file does not match its checksum: $(basename "$path")" >&2
    echo "       Run the installation again to download it cleanly." >&2
    exit 1
  fi
  mv "$path.part" "$path"
}

# The runtime is ~370 MB: only download it when the pinned version changed.
if [ ! -x "$RUNTIME_PATH" ] || [ "$(cat "$RUNTIME_STAMP" 2>/dev/null)" != "$RUNTIME_FILENAME" ]; then
  download "$RUNTIME_URL" "$TARGET_DIR/$RUNTIME_FILENAME" "$RUNTIME_SHA256"
  mv "$TARGET_DIR/$RUNTIME_FILENAME" "$RUNTIME_PATH"
  chmod 755 "$RUNTIME_PATH"
  echo "$RUNTIME_FILENAME" > "$RUNTIME_STAMP"
fi

download "$MODEL_URL" "$MODEL_PATH" "$MODEL_SHA256"

# ── Launcher ──────────────────────────────────────────────────────

cat > "$RUNNER_SCRIPT" <<EOF
#!/bin/bash
#
# Generated by install-local-ai.sh. Starts the offline AI assistant, waits
# until it really answers, then opens it in the browser. Stops it again once
# nobody has used it for a while, because it holds a lot of memory.

RUNTIME='$RUNTIME_PATH'
MODEL='$MODEL_PATH'
ICON='$ICON_TARGET'
PORT=$PORT
IDLE_MINUTES=10
WATCHDOG='$WATCHDOG_SCRIPT'
LOG=/tmp/aucoop-local-ai.log
EOF
cat >> "$RUNNER_SCRIPT" <<'EOF'

case "${LANG%%[_.]*}" in
  es) T_SLOW="Abriendo el asistente de IA. Tarda un poco la primera vez."
      T_FAIL="El asistente de IA no ha podido arrancar. Prueba a reiniciar el ordenador." ;;
  ca) T_SLOW="Obrint l'assistent d'IA. La primera vegada triga una mica."
      T_FAIL="L'assistent d'IA no ha pogut arrencar. Prova de reiniciar l'ordinador." ;;
  fr) T_SLOW="Ouverture de l'assistant IA. C'est un peu long la première fois."
      T_FAIL="L'assistant IA n'a pas pu démarrer. Essayez de redémarrer l'ordinateur." ;;
  pt) T_SLOW="A abrir o assistente de IA. Da primeira vez demora um pouco."
      T_FAIL="O assistente de IA não conseguiu arrancar. Tente reiniciar o computador." ;;
  *)  T_SLOW="Opening the AI assistant. The first time takes a moment."
      T_FAIL="The AI assistant could not start. Try restarting the computer." ;;
esac

# Quiet on purpose: while the model loads the server answers 503.
answers() { curl -fs -m 2 -o /dev/null "http://127.0.0.1:$1/v1/models"; }

# Already running? Just open it again.
if answers "$PORT"; then
  exec xdg-open "http://127.0.0.1:$PORT"
fi

# Something else on that port: take the next free one.
for offset in 0 1 2 3 4 5 6 7 8 9; do
  if ! ss -ltnH "( sport = :$((PORT + offset)) )" | grep -q .; then
    PORT=$((PORT + offset))
    break
  fi
done

nohup "$RUNTIME" -m "$MODEL" --ctx-size 4096 --server --host 127.0.0.1 --port "$PORT" \
  > "$LOG" 2>&1 < /dev/null &
SERVER_PID=$!

# Big models on old disks can take minutes, so wait for a real answer.
ready=""
for i in $(seq 1 600); do
  if answers "$PORT"; then ready=1; break; fi
  kill -0 "$SERVER_PID" 2>/dev/null || break
  [ "$i" = 6 ] && notify-send -i "$ICON" "AUCOOP" "$T_SLOW" 2>/dev/null
  sleep 0.5
done

if [ -z "$ready" ]; then
  notify-send -u critical -i "$ICON" "AUCOOP" "$T_FAIL" 2>/dev/null
  exit 1
fi

xdg-open "http://127.0.0.1:$PORT"

# Free the memory once nobody is using it any more. Detached, so the
# launcher (and any terminal that started it) returns straight away.
setsid "$WATCHDOG" "$SERVER_PID" "$PORT" "$IDLE_MINUTES" >/dev/null 2>&1 < /dev/null &
EOF

# The assistant holds 0.7-9 GB of memory, so it should not stay loaded after
# the last browser tab is gone.
cat > "$WATCHDOG_SCRIPT" <<'EOF'
#!/bin/bash
# idle-watchdog.sh <server-pid> <port> <idle-minutes>
SERVER_PID="$1"
PORT="$2"
IDLE_MINUTES="$3"

idle=0
while kill -0 "$SERVER_PID" 2>/dev/null; do
  sleep 60
  if ss -tnH state established "( sport = :$PORT )" | grep -q .; then
    idle=0
  else
    idle=$((idle + 1))
  fi
  if [ "$idle" -ge "$IDLE_MINUTES" ]; then
    kill "$SERVER_PID" 2>/dev/null
    break
  fi
done
EOF

chmod +x "$WATCHDOG_SCRIPT"

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
  chown "$TARGET_USER:$TARGET_USER" "$DESKTOP_DIR/aucoop-local-ai.desktop"
  chmod +x "$DESKTOP_DIR/aucoop-local-ai.desktop"
  sudo -u "$TARGET_USER" gio set "$DESKTOP_DIR/aucoop-local-ai.desktop" metadata::trusted true 2>/dev/null || true
fi

echo "Installed local AI assistant launcher."
