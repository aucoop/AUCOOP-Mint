#!/bin/bash
#
# AUCOOP Mint installer
#
# Takes a fresh Linux Mint 22.x (Cinnamon) install and applies all
# AUCOOP customizations: removes bloat, installs apps, sets theme,
# wallpaper, cursor, desktop shortcuts, and branding.
#
# Can be run standalone or via boot.sh (curl one-liner).
#
# On a terminal it shows an animated progress screen (lib/ui.sh) and writes
# all command output to a log file; press D to see it live. Pass --verbose
# to get the raw output instead.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$SCRIPT_DIR/install"
LOG_DIR="$HOME/.local/state/aucoop-mint"
LOG_FILE="$LOG_DIR/install.log"

VERBOSE=0
[ "${1:-}" = "--verbose" ] && VERBOSE=1

# When run via "wget ... | bash", stdin is the pipe, so questions must be
# read from the terminal directly.
TTY_IN=/dev/tty
[ -r /dev/tty ] || TTY_IN=/dev/stdin

# Animated screen only on a real terminal.
FANCY=0
if [ "$VERBOSE" -eq 0 ] && [ -t 1 ] && [ -r /dev/tty ] && [ "${TERM:-dumb}" != "dumb" ]; then
  FANCY=1
fi

# Texts in the system language (lib/i18n.sh).
source "$SCRIPT_DIR/lib/i18n.sh"
i18n_load

# ── Steps ─────────────────────────────────────────────────────────
#
# "id|expected seconds|script script ...". Scripts run in order. The label
# is L_STEP[id] from lib/i18n.sh; the expected time only drives the
# progress bar.

STEPS=(
  "remove|20|remove-apps"
  "chrome|25|chrome"
  "office|60|onlyoffice"
  "store|5|flathub"
  "look|12|theme wallpaper cursor software-manager-icon update-manager"
  "layout|5|desktop-shortcuts panel search-aliases menu-cleanup branding menu-button"
  "tools|12|aucoop-workbench aucoop-welcome mint-welcome"
)

STEP_LABELS=()
STEP_EXPECT=()
STEP_SCRIPTS=()
for entry in "${STEPS[@]}"; do
  IFS='|' read -r id expect scripts <<< "$entry"
  STEP_LABELS+=("${L_STEP[$id]}")
  STEP_EXPECT+=("$expect")
  STEP_SCRIPTS+=("$scripts")
done
STEP_TIMES=()

# ── Helpers ───────────────────────────────────────────────────────

say() { printf '%s\n' "$*"; }

ask() {
  # ask "Question" default(Y|N) -> returns 0 for yes
  local prompt="$1" default="$2" reply hint="$L_NO_YES"
  [ "$default" = "Y" ] && hint="$L_YES_NO"
  printf '%s %s ' "$prompt" "$hint"
  # No terminal to answer from: never assume yes (this may mean a reboot).
  if ! read -r reply < "$TTY_IN"; then
    echo ""
    return 1
  fi
  reply="${reply:-$default}"
  # Yes, sí/sim, oui.
  [[ "$reply" =~ ^[YySsOo]$ ]]
}

cleanup() {
  [ -n "${SUDO_KEEPALIVE_PID:-}" ] && kill "$SUDO_KEEPALIVE_PID" 2>/dev/null
  [ -n "${STEP_PID:-}" ] && kill "$STEP_PID" 2>/dev/null
  [ "$FANCY" -eq 1 ] && ui_restore
  return 0
}
trap cleanup EXIT
trap 'cleanup; printf "\n\n  %s\n\n" "$L_CANCELLED"; exit 130' INT TERM

# Run the scripts of one step. Sourced (they use "return") but inside a
# subshell, so one step cannot affect the next.
run_scripts() {
  local script
  for script in "$@"; do
    echo ""
    echo "── $script ──────────────────────────────────"
    source "$INSTALL_DIR/$script.sh"
  done
}

run_step() {
  local scripts
  read -ra scripts <<< "${STEP_SCRIPTS[$1]}"
  ( set -e; run_scripts "${scripts[@]}" ) >> "$LOG_FILE" 2>&1 < /dev/null
}

# ── Preflight checks ──────────────────────────────────────────────

if [ ! -f /etc/linuxmint/info ]; then
  say "$L_ONLY_MINT"
  exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
  say "$L_NO_ROOT"
  exit 1
fi

MINT_VERSION=$(grep '^RELEASE=' /etc/linuxmint/info | cut -d= -f2)

mkdir -p "$LOG_DIR"
: > "$LOG_FILE"
echo "AUCOOP Mint install started $(date) on Linux Mint $MINT_VERSION" >> "$LOG_FILE"

if [ "$FANCY" -eq 1 ]; then
  # From here on the animated path checks every result itself.
  set +e
  source "$SCRIPT_DIR/lib/ui.sh"
  printf '\e]0;AUCOOP Mint\a'
  ui_init
  ui_intro
  ui_restore
fi

if [[ ! "$MINT_VERSION" =~ ^22\. ]]; then
  say ""
  # shellcheck disable=SC2059
  printf "  $L_VERSION\n" "$MINT_VERSION"
  ask "  $L_CONTINUE" N || exit 1
fi

# ── Internet ──────────────────────────────────────────────────────
#
# Everything below downloads. Say so now, instead of failing halfway.

online() {
  command -v nmcli >/dev/null 2>&1 || return 0
  case "$(nmcli networking connectivity check 2>/dev/null)" in
    none|limited|portal) return 1 ;;
  esac
  return 0
}

if ! online; then
  if [ "$FANCY" -eq 1 ]; then
    ui_message "$C_RED$C_BOLD$L_OFFLINE"
  else
    say "$L_OFFLINE"
  fi
  exit 1
fi

# ── Password ──────────────────────────────────────────────────────

if ! sudo -n true 2>/dev/null; then
  if [ "$FANCY" -eq 1 ]; then
    ui_message \
      "$C_WHITE$L_INTRO1" \
      "$C_WHITE$L_INTRO2" \
      "" \
      "$C_WHITE$C_BOLD$L_PW1" \
      "$C_GRAY$L_PW2" \
      ""
  else
    say "$L_PLAIN_START"
  fi
  if ! sudo -v -p "  $L_PW_PROMPT" < "$TTY_IN"; then
    say ""
    say "  $L_PW_BAD"
    say ""
    exit 1
  fi
fi

# Keep sudo alive for the whole install so no step stops to ask again.
( while true; do sudo -n true 2>/dev/null; sleep 50; done ) &
SUDO_KEEPALIVE_PID=$!

# ── Run steps ─────────────────────────────────────────────────────

if [ "$FANCY" -eq 0 ]; then
  # Plain mode: raw output (verbose) or simple progress lines (no terminal).
  for ((i = 0; i < ${#STEP_LABELS[@]}; i++)); do
    echo "[$((i + 1))/${#STEP_LABELS[@]}] ${STEP_LABELS[i]}"
    set +e
    if [ "$VERBOSE" -eq 1 ]; then
      read -ra scripts <<< "${STEP_SCRIPTS[i]}"
      ( set -e; run_scripts "${scripts[@]}" ) 2>&1 | tee -a "$LOG_FILE"
      status=${PIPESTATUS[0]}
    else
      run_step "$i"
      status=$?
    fi
    set -e
    if [ "$status" -ne 0 ]; then
      echo ""
      # shellcheck disable=SC2059
      printf "$L_PLAIN_FAIL\n" "${STEP_LABELS[i]}"
      # shellcheck disable=SC2059
      printf "$L_PLAIN_LOG\n" "$LOG_FILE"
      tail -n 12 "$LOG_FILE"
      exit 1
    fi
  done
else
  ui_quiet
  total_expect=0
  for e in "${STEP_EXPECT[@]}"; do total_expect=$((total_expect + e)); done
  done_expect=0
  install_start=$SECONDS
  UI_TICK=0

  for ((i = 0; i < ${#STEP_LABELS[@]}; i++)); do
    run_step "$i" &
    STEP_PID=$!
    step_start=$SECONDS
    expect=${STEP_EXPECT[i]}

    while kill -0 "$STEP_PID" 2>/dev/null; do
      UI_STEP_ELAPSED=$((SECONDS - step_start))
      UI_TOTAL_ELAPSED=$((SECONDS - install_start))
      # Move smoothly through this step's share of the bar, slowing down
      # instead of stopping if it takes longer than expected.
      e=$UI_STEP_ELAPSED
      if [ "$e" -lt "$expect" ]; then
        part=$((e * 900 / expect))
      else
        part=$((990 - 90 * expect / (e + 1)))
      fi
      permille=$(((done_expect * 1000 + expect * part) / total_expect))
      ui_progress_screen "$i" running "$permille"
      ui_poll_keys
      UI_TICK=$((UI_TICK + 1))
    done

    wait "$STEP_PID"
    status=$?
    STEP_PID=""
    STEP_TIMES[i]=$((SECONDS - step_start))
    UI_TOTAL_ELAPSED=$((SECONDS - install_start))

    if [ "$status" -ne 0 ]; then
      ui_restore
      ui_failed_screen "$i"
      exit 1
    fi
    done_expect=$((done_expect + expect))
  done

fi

echo "AUCOOP Mint install finished $(date)" >> "$LOG_FILE"

# ── Done ──────────────────────────────────────────────────────────

restart_wanted=1
if [ "$FANCY" -eq 1 ]; then
  # Keeps the logo cycling colours while it waits for the answer.
  ui_done_prompt
  restart_wanted=$?
  ui_restore
  printf '\n'
else
  say ""
  say "$L_PLAIN_DONE"
  ask "    $L_RESTART_Q" Y
  restart_wanted=$?
fi

if [ "$restart_wanted" -eq 0 ]; then
  say ""
  say "    $L_RESTARTING"
  sleep 2
  systemctl reboot || sudo reboot
else
  say ""
  say "    $L_REMEMBER"
  say ""
fi
