# shellcheck shell=bash
#
# Terminal UI for the AUCOOP Mint installer: animated logo, step list,
# progress bar, rotating messages and an optional technical details panel.
#
# The installer sources this file and runs its screens with "set +e", so
# every function here handles its own errors.
#
# Each frame is drawn from the top-left corner in a single write, so the
# screen never flickers or scrolls.

UI_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$UI_LIB_DIR/logo.sh"

# Texts come from lib/i18n.sh (L_TAGLINE, L_QUIPS, ...).
source "$UI_LIB_DIR/i18n.sh"
[ -n "${L_TAGLINE:-}" ] || i18n_load

# ── Setup ─────────────────────────────────────────────────────────

ui_init() {
  UI_DETAILS=0
  UI_STTY="$(stty -g < /dev/tty 2>/dev/null)"
  ui_size
  trap ui_size WINCH
}

ui_size() {
  local size
  size="$(stty size < /dev/tty 2>/dev/null)"
  UI_ROWS="${size% *}"
  UI_COLS="${size#* }"
  [[ "$UI_ROWS" =~ ^[0-9]+$ ]] || UI_ROWS=24
  [[ "$UI_COLS" =~ ^[0-9]+$ ]] || UI_COLS=80

  # Pick the biggest logo that fits the terminal.
  if [ "$UI_COLS" -ge 74 ] && [ "$UI_ROWS" -ge 23 ]; then
    UI_LOGO=("${LOGO_BIG[@]}")
  elif [ "$UI_COLS" -ge 48 ] && [ "$UI_ROWS" -ge 20 ]; then
    UI_LOGO=("${LOGO_SMALL[@]}")
  else
    UI_LOGO=()
  fi
  UI_LOGO_H=${#UI_LOGO[@]}
  UI_LOGO_W=0
  [ "$UI_LOGO_H" -gt 0 ] && UI_LOGO_W=${#UI_LOGO[0]}
}

# Hide typed keys and the cursor while animating; restore for questions.
ui_quiet() {
  stty -echo -icanon < /dev/tty 2>/dev/null
  printf '\e[?25l'
}

ui_restore() {
  [ -n "${UI_STTY:-}" ] && stty "$UI_STTY" < /dev/tty 2>/dev/null
  printf '\e[0m\e[?25h'
}

# ── Colors ────────────────────────────────────────────────────────

UI_TRUECOLOR=0
[[ "${COLORTERM:-}" =~ ^(truecolor|24bit)$ ]] && UI_TRUECOLOR=1

# ui_rgb fg|bg r g b -> sets REPLY to the escape sequence.
ui_rgb() {
  local layer=38
  [ "$1" = "bg" ] && layer=48
  if [ "$UI_TRUECOLOR" -eq 1 ]; then
    REPLY=$'\e['"$layer;2;$2;$3;$4m"
  else
    REPLY=$'\e['"$layer;5;$((16 + 36 * ($2 * 5 / 255) + 6 * ($3 * 5 / 255) + $4 * 5 / 255))m"
  fi
}

# ui_hue h (0-359) -> sets R G B to a bright color on the color wheel.
ui_hue() {
  local h=$(($1 % 360)) f
  f=$((h % 60 * 255 / 60))
  case $((h / 60)) in
    0) R=255; G=$f; B=0 ;;
    1) R=$((255 - f)); G=255; B=0 ;;
    2) R=0; G=255; B=$f ;;
    3) R=0; G=$((255 - f)); B=255 ;;
    4) R=$f; G=0; B=255 ;;
    *) R=255; G=0; B=$((255 - f)) ;;
  esac
}

ui_rgb fg 0 156 210; C_BLUE="$REPLY"
ui_rgb fg 120 215 245; C_SKY="$REPLY"
ui_rgb fg 235 235 235; C_WHITE="$REPLY"
ui_rgb fg 150 150 150; C_GRAY="$REPLY"
ui_rgb fg 95 95 95; C_DIM="$REPLY"
ui_rgb fg 60 60 60; C_DARK="$REPLY"
ui_rgb fg 110 210 130; C_GREEN="$REPLY"
ui_rgb fg 240 100 100; C_RED="$REPLY"
C_BOLD=$'\e[1m'
C_ITALIC=$'\e[3m'
C_RESET=$'\e[0m'

# ── Logo ──────────────────────────────────────────────────────────

# ui_pixel class x mode tick -> sets R G B for one logo pixel.
#   class: 1 = the black parts of the logo, 2 = the blue loop
#   mode:  static | shimmer | reveal | rainbow | gray
ui_pixel() {
  local class=$1 x=$2 mode=$3 tick=$4 d glow
  case "$mode" in
    rainbow)
      ui_hue $((x * 5 + tick * 18))
      return
      ;;
    gray)
      if [ "$class" -eq 2 ]; then R=110; G=110; B=110; else R=70; G=70; B=70; fi
      return
      ;;
    reveal)
      # A bright edge sweeping to the right.
      if [ "$x" -ge $((tick - 2)) ]; then R=255; G=255; B=255; return; fi
      ;;
  esac
  if [ "$class" -eq 1 ]; then
    R=235; G=235; B=235
    return
  fi
  R=0; G=156; B=210
  if [ "$mode" = "shimmer" ]; then
    # A soft gleam travelling along the blue loop.
    d=$((x - (tick * 2 % (UI_LOGO_W + 30)) + 10))
    [ "$d" -lt 0 ] && d=$((-d))
    if [ "$d" -lt 8 ]; then
      glow=$((8 - d))
      R=$((R + (170 - R) * glow / 8))
      G=$((G + (235 - G) * glow / 8))
      B=$((B + (255 - B) * glow / 8))
    fi
  fi
}

# ui_logo_rows mode tick -> appends the logo lines to UI_FRAME.
ui_logo_rows() {
  local mode=$1 tick=$2 pad row y x c top bottom line fg bg
  pad=$(((UI_COLS - UI_LOGO_W) / 2))
  for ((y = 0; y < UI_LOGO_H; y++)); do
    row="${UI_LOGO[y]}"
    printf -v line '%*s' "$pad" ''
    for ((x = 0; x < UI_LOGO_W; x++)); do
      c=${row:x:1}
      top=$((c / 3)); bottom=$((c % 3))
      if [ "$mode" = "reveal" ] && [ "$x" -gt "$tick" ]; then
        line+=' '
        continue
      fi
      if [ "$top" -eq 0 ] && [ "$bottom" -eq 0 ]; then
        if [ "$mode" = "rainbow" ] && [ $((RANDOM % 70)) -eq 0 ]; then
          ui_hue $((RANDOM % 360)); ui_rgb fg "$R" "$G" "$B"
          line+="$REPLY${UI_SPARKS:RANDOM%4:1}$C_RESET"
        else
          line+=' '
        fi
        continue
      fi
      if [ "$top" -ne 0 ] && [ "$bottom" -ne 0 ] && [ "$top" -eq "$bottom" ]; then
        ui_pixel "$top" "$x" "$mode" "$tick"; ui_rgb fg "$R" "$G" "$B"
        line+="$REPLY█"
      elif [ "$bottom" -eq 0 ]; then
        ui_pixel "$top" "$x" "$mode" "$tick"; ui_rgb fg "$R" "$G" "$B"
        line+="$REPLY▀"
      elif [ "$top" -eq 0 ]; then
        ui_pixel "$bottom" "$x" "$mode" "$tick"; ui_rgb fg "$R" "$G" "$B"
        line+="$REPLY▄"
      else
        ui_pixel "$top" "$x" "$mode" "$tick"; ui_rgb fg "$R" "$G" "$B"; fg="$REPLY"
        ui_pixel "$bottom" "$x" "$mode" "$tick"; ui_rgb bg "$R" "$G" "$B"; bg="$REPLY"
        line+="$fg$bg▀$C_RESET"
      fi
    done
    ui_add "$line$C_RESET"
  done
}
UI_SPARKS="✦✧⋆·"

# ── Frame helpers ─────────────────────────────────────────────────

ui_begin() { UI_FRAME=""; UI_LINES=0; }

# ui_add colored_text -> one screen line.
ui_add() {
  UI_FRAME+="$1"$'\e[0m\e[K\n'
  UI_LINES=$((UI_LINES + 1))
}

# ui_center plain_text [color] -> centered line.
ui_center() {
  local text="$1" color="${2:-}" pad
  text="${text:0:UI_COLS}"
  pad=$(((UI_COLS - ${#text}) / 2))
  [ "$pad" -lt 0 ] && pad=0
  printf -v pad '%*s' "$pad" ''
  ui_add "$pad$color$text"
}

ui_flush() {
  # Blank the rest of the screen, then write everything at once.
  printf '\e[H%s\e[J' "${UI_FRAME%$'\n'}"
}

ui_header() {
  # ui_header logo_mode tick [tagline_chars]
  local shown="${3:-${#L_TAGLINE}}"
  ui_add ""
  if [ "$UI_LOGO_H" -gt 0 ]; then
    ui_logo_rows "$1" "$2"
  else
    ui_center "A U C O O P   M I N T" "$C_BOLD$C_BLUE"
  fi
  ui_add ""
  ui_center "${L_TAGLINE:0:shown}" "$C_ITALIC$C_GRAY"
  ui_add ""
}

# ui_pad text width -> REPLY padded with spaces. Counts characters, unlike
# printf, which pads by bytes and misaligns accented text.
ui_pad() {
  local n=$(($2 - ${#1}))
  REPLY="$1"
  [ "$n" -gt 0 ] && printf -v REPLY '%s%*s' "$1" "$n" ''
  return 0
}

fmt_clock() { printf -v REPLY '%d:%02d' $(($1 / 60)) $(($1 % 60)); }

# ── Screens ───────────────────────────────────────────────────────

# The logo sweeps in and the tagline types itself.
ui_intro() {
  local k
  ui_quiet
  printf '\e[2J'
  if [ "$UI_LOGO_H" -gt 0 ]; then
    for ((k = 0; k <= UI_LOGO_W + 3; k += 3)); do
      ui_begin; ui_header reveal "$k" 0; ui_flush
      sleep 0.02
    done
  fi
  for ((k = 0; k <= ${#L_TAGLINE}; k++)); do
    ui_begin; ui_header static 0 "$k"; ui_flush
    sleep 0.025
  done
}

# Static header plus a few plain lines, used before asking for the password.
# ui_message line...
ui_message() {
  local l
  ui_begin
  ui_header static 0
  for l in "$@"; do
    ui_add "  $l"
  done
  ui_flush
  printf '\n'
}

# ui_steps_rows current_index status_of_current -> the step list.
# Uses STEP_LABELS, STEP_TIMES (seconds for finished steps), UI_TICK.
ui_steps_rows() {
  local cur=$1 state=$2 i icon label time width
  width=$((UI_COLS - 14))
  [ "$width" -gt 58 ] && width=58
  for ((i = 0; i < ${#STEP_LABELS[@]}; i++)); do
    label="${STEP_LABELS[i]:0:width}"
    time=""
    if [ "$i" -lt "$cur" ] || { [ "$i" -eq "$cur" ] && [ "$state" = "done" ]; }; then
      icon="$C_BLUE✔"; fmt_clock "${STEP_TIMES[i]}"; time="$REPLY"
      ui_pad "$label" "$width"; label="$REPLY"
      ui_add "    $icon  $C_WHITE$label  $C_DIM$time"
    elif [ "$i" -eq "$cur" ] && [ "$state" = "failed" ]; then
      fmt_clock "${STEP_TIMES[i]}"; time="$REPLY"
      ui_pad "$label" "$width"; label="$REPLY"
      ui_add "    $C_RED✘  $C_BOLD$C_RED$label  $C_DIM$time"
    elif [ "$i" -eq "$cur" ]; then
      icon="${UI_SPINNER:UI_TICK % ${#UI_SPINNER}:1}"
      fmt_clock "$UI_STEP_ELAPSED"; time="$REPLY"
      ui_pad "$label" "$width"; label="$REPLY"
      ui_add "    $C_SKY$icon  $C_BOLD$C_WHITE$label  $C_GRAY$time"
    else
      ui_add "    $C_DARK○  $C_DIM$label"
    fi
  done
}
UI_SPINNER="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"

# ui_bar permille -> gradient progress bar line.
ui_bar() {
  local permille=$1 width filled i r g b bar="" pct
  width=$((UI_COLS - 22))
  [ "$width" -gt 50 ] && width=50
  [ "$width" -lt 10 ] && width=10
  filled=$((permille * width / 1000))
  for ((i = 0; i < width; i++)); do
    if [ "$i" -lt "$filled" ]; then
      r=$((0 + 120 * i / width)); g=$((156 + 60 * i / width)); b=$((210 + 35 * i / width))
      ui_rgb fg "$r" "$g" "$b"
      bar+="$REPLY━"
    else
      bar+="$C_DARK━"
    fi
  done
  pct=$((permille / 10))
  fmt_clock "$UI_TOTAL_ELAPSED"
  printf -v pct '%3d%%' "$pct"
  ui_add "    $bar  $C_WHITE$C_BOLD$pct$C_RESET  $C_DIM$REPLY"
}

# ui_details_rows count -> last lines of the log in a quiet box.
ui_details_rows() {
  local count=$1 width line
  width=$((UI_COLS - 8))
  ui_add "    $C_DIM── $L_DETAILS_TITLE ──"
  while IFS= read -r line; do
    line="${line//$'\r'/}"
    line="${line//$'\t'/  }"
    ui_add "    $C_DIM${line:0:width}"
  done < <(tail -n "$count" "$LOG_FILE" 2>/dev/null)
  for ((line = $(tail -n "$count" "$LOG_FILE" 2>/dev/null | wc -l); line < count; line++)); do
    ui_add ""
  done
}

# ui_progress_screen current_index state permille
ui_progress_screen() {
  local cur=$1 state=$2 permille=$3 fixed room quip
  ui_begin
  ui_header shimmer "$UI_TICK"

  # Everything except the step list and the details box.
  fixed=$((UI_LINES + 5))
  room=$((UI_ROWS - fixed))

  if [ "$UI_DETAILS" -eq 0 ] || [ "$room" -ge $((${#STEP_LABELS[@]} + 7)) ]; then
    ui_steps_rows "$cur" "$state"
    ui_add ""
    room=$((room - ${#STEP_LABELS[@]} - 1))
  fi

  ui_bar "$permille"
  quip="${L_QUIPS[UI_TOTAL_ELAPSED / 7 % ${#L_QUIPS[@]}]}"
  ui_add "    $C_ITALIC$C_GRAY$quip"
  ui_add ""

  if [ "$UI_DETAILS" -eq 1 ] && [ "$room" -ge 3 ]; then
    ui_details_rows $((room - 2))
  fi

  if [ "$UI_DETAILS" -eq 1 ]; then
    ui_center "$L_DETAILS_HIDE" "$C_DARK"
  else
    ui_center "$L_DETAILS_SHOW" "$C_DARK"
  fi
  ui_flush
}

# Wait up to 0.1s for a key; D toggles the details panel.
ui_poll_keys() {
  local key
  if read -rsn1 -t 0.1 key < /dev/tty 2>/dev/null; then
    case "$key" in
      d|D) UI_DETAILS=$((1 - UI_DETAILS)) ;;
    esac
  fi
}

# Rainbow logo with sparkles, then the final summary.
ui_finale() {
  local k
  for ((k = 0; k < 40; k++)); do
    ui_begin
    ui_header rainbow "$k"
    ui_steps_rows "${#STEP_LABELS[@]}" done
    ui_flush
    sleep 0.05
  done
}

ui_done_screen() {
  local total
  fmt_clock "$UI_TOTAL_ELAPSED"
  # shellcheck disable=SC2059
  printf -v total "$L_DONE_IN" "$REPLY"
  ui_begin
  ui_header static 0
  ui_steps_rows "${#STEP_LABELS[@]}" done
  ui_add ""
  ui_add "    $C_GREEN$C_BOLD$L_READY$C_RESET  $C_GRAY$total"
  ui_add "    $C_WHITE$L_RESTART_HINT"
  ui_add ""
  ui_flush
  printf '\n'
}

# Only the failed step is listed, so the message and log fit on 80x24.
ui_failed_screen() {
  local cur=$1 line width room time
  width=$((UI_COLS - 8))
  fmt_clock "${STEP_TIMES[cur]}"; time="$REPLY"
  room=$((UI_COLS - 14))
  [ "$room" -gt 58 ] && room=58
  ui_pad "${STEP_LABELS[cur]:0:room}" "$room"; line="$REPLY"
  ui_begin
  ui_header gray 0
  ui_add "    $C_RED✘  $C_BOLD$C_RED$line  $C_DIM$time"
  ui_add ""
  ui_add "    $C_RED$C_BOLD$L_OOPS1$C_RESET $C_WHITE$L_OOPS2"
  ui_add "    $C_WHITE$L_OOPS3"
  ui_add "    $C_GRAY$L_SEND_LOG"
  ui_add "    $C_WHITE$LOG_FILE"
  room=$((UI_ROWS - UI_LINES - 3))
  [ "$room" -gt 8 ] && room=8
  if [ "$room" -gt 0 ]; then
    ui_add ""
    while IFS= read -r line; do
      line="${line//$'\r'/}"
      ui_add "    $C_DIM${line:0:width}"
    done < <(tail -n "$room" "$LOG_FILE" 2>/dev/null)
  fi
  printf '\e[H%s\e[J\n' "${UI_FRAME%$'\n'}"
}
