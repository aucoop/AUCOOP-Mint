#!/bin/bash
#
# Wait until the computer is online, then remind the user to finish the
# setup and reopen AUCOOP Welcome. Started by Welcome in the background.
#
# Usage: remind-when-online.sh "title" "message" [--unmetered]
#   --unmetered  also wait until the connection is not mobile data

APP_DIR="$(cd "$(dirname "$0")" && pwd)"
TITLE="$1"
BODY="$2"
UNMETERED="${3:-}"
ICON="/usr/share/pixmaps/aucoop-symbol.png"

online() {
  [ "$(nmcli networking connectivity check 2>/dev/null)" = "full" ] || return 1
  if [ "$UNMETERED" = "--unmetered" ]; then
    local dev
    dev="$(nmcli -t -f DEVICE,STATE device | awk -F: '$2 == "connected" { print $1; exit }')"
    case "$(nmcli -g GENERAL.METERED device show "$dev" 2>/dev/null)" in
      yes*) return 1 ;;
    esac
  fi
  return 0
}

until online; do
  sleep 60
done

notify-send -i "$ICON" "$TITLE" "$BODY"
exec python3 "$APP_DIR/aucoop_welcome.py"
