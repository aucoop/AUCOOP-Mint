#!/bin/bash
# Stop Mint's own Welcome window from opening at login.
#
# AUCOOP Welcome replaces it, and two welcome windows at first login are
# confusing. This writes the same flag as Mint Welcome's own
# "Show this dialog at startup" checkbox, so it stays in the menu.

NORUN_FLAG="$HOME/.linuxmint/mintwelcome/norun.flag"

echo "  Hiding Mint Welcome at startup..."
mkdir -p "$(dirname "$NORUN_FLAG")"
touch "$NORUN_FLAG"
