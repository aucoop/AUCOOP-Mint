#!/bin/bash

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <essential-setup|schedule-setup|install-module|install-local-ai|uninstall-local-ai> [args...]"
  exit 1
fi

APP_DIR="$(cd "$(dirname "$0")" && pwd)"
ACTION="$1"
shift

case "$ACTION" in
  essential-setup)
    exec "$APP_DIR/essential-setup.sh" "$@"
    ;;
  schedule-setup)
    exec "$APP_DIR/schedule-setup.sh" "$@"
    ;;
  install-module)
    exec "$APP_DIR/install-module.sh" "$@"
    ;;
  install-local-ai)
    exec "$APP_DIR/install-local-ai.sh" "$@"
    ;;
  uninstall-local-ai)
    exec "$APP_DIR/uninstall-local-ai.sh" "$@"
    ;;
  *)
    echo "Unknown action: $ACTION"
    exit 1
    ;;
esac
