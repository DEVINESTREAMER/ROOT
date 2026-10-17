#!/system/bin/sh
# DEVINE: animated one-click online launcher
BASE="https://raw.githubusercontent.com/DEVINESTREAMER/ROOT/main"
DIR="/data/local/tmp/devine"
RESET="$DIR/reset_port.sh"
MODULE="$DIR/Devine2.5.sh"
LOG="$DIR/reset_port.log"
export PATH="/system/bin:/system/xbin:/vendor/bin:/data/data/com.termux/files/usr/bin:$PATH"

if [ "$(id -u)" != 0 ]; then
  echo "[ERROR] Root access required."
  exit 1
fi
mkdir -p "$DIR" || exit 1
chmod 700 "$DIR"

if [ -x /data/data/com.termux/files/usr/bin/curl ]; then
  CURL=/data/data/com.termux/files/usr/bin/curl
elif command -v curl >/dev/null 2>&1; then
  CURL=$(command -v curl)
else
  CURL=""
fi

download() {
  url="$1"; out="$2"
  temp="$out.part"
  rm -f "$temp"
  if [ -n "$CURL" ]; then
    "$CURL" -fLsS --retry 1 --connect-timeout 8 --max-time 90 "$url" -o "$temp" || return 1
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$temp" "$url" || return 1
  else
    echo "No curl or wget" >&2
    return 1
  fi
  [ -s "$temp" ] || return 1
  mv -f "$temp" "$out"
}

animate_wait() {
  pid="$1"; label="$2"
  n=0
  printf '\033[?25l'
  while kill -0 "$pid" 2>/dev/null; do
    case $((n % 4)) in
      0) frame='|' ;;
      1) frame='/' ;;
      2) frame='-' ;;
      3) frame='\\' ;;
    esac
    printf '\r\033[1;36m[%s]\033[0m %s   ' "$frame" "$label"
    sleep 0.12
    n=$((n + 1))
  done
  wait "$pid"
  rc=$?
  if [ "$rc" -eq 0 ]; then
    printf '\r\033[1;32m[OK]\033[0m %s                \n' "$label"
  else
    printf '\r\033[1;31m[FAIL]\033[0m %s              \n' "$label"
  fi
  printf '\033[?25h'
  return "$rc"
}
trap 'printf "\033[?25h"' EXIT

printf '\033[1;35m'
printf '====================================\n'
printf '       D E V I N E   L O A D E R\n'
printf '====================================\n'
printf '\033[0m'

# Download concurrently to minimize network waiting time.
download "$BASE/reset_port.sh" "$RESET" >"$DIR/reset_download.log" 2>&1 &
P1=$!
download "$BASE/Devine2.5.sh" "$MODULE" >"$DIR/devine_download.log" 2>&1 &
P2=$!
animate_wait "$P1" "Downloading reset_port.sh" || {
  cat "$DIR/reset_download.log"
  exit 1
}
animate_wait "$P2" "Downloading Devine2.5.sh" || {
  cat "$DIR/devine_download.log"
  exit 1
}

magic=$(od -An -tx1 -N4 "$MODULE" | tr -d ' \n')
if [ "$magic" != "7f454c46" ]; then
  echo "[ERROR] Devine download is not an ELF executable."
  exit 1
fi
chmod 700 "$MODULE"

# The successful manual test used sh -x; capture all its output.
sh -x "$RESET" > "$LOG" 2>&1 &
PR=$!
animate_wait "$PR" "Preparing port 8080" || {
  echo "[ERROR] Reset failed; last log lines:"
  tail -n 12 "$LOG"
  exit 1
}

printf '\033[1;32m[READY]\033[0m Launching Devine...\n'
cd "$DIR" || exit 1
RUNLOG="$DIR/devine_runtime.log"
: > "$RUNLOG"
"$MODULE" > "$RUNLOG" 2>&1 &
DEVINE_PID=$!

# Keep Devine output visible while waiting for its actual generated URL.
tail -n +1 -f "$RUNLOG" &
TAIL_PID=$!
cleanup() {
  kill "$TAIL_PID" 2>/dev/null
  printf '\033[?25h'
}
trap cleanup EXIT INT TERM

echo "[INFO] Waiting for Devine login URL..."
COUNT=0
FOUND=""
while [ "$COUNT" -lt 120 ]; do
  # Strip ANSI terminal sequences before matching the URL.
  FOUND=$(sed 's/\033\[[0-9;]*[[:alpha:]]//g' "$RUNLOG" |
    grep -Eo 'https?://([0-9]{1,3}\.){3}[0-9]{1,3}:[0-9]{2,5}(/[^[:space:]]*)?|https?://(localhost|127\.0\.0\.1):[0-9]{2,5}(/[^[:space:]]*)?' |
    head -n 1)
  [ -n "$FOUND" ] && break
  kill -0 "$DEVINE_PID" 2>/dev/null || break
  sleep 1
  COUNT=$((COUNT + 1))
done

if [ -n "$FOUND" ]; then
  echo "[INFO] Opening default browser: $FOUND"
  if ! /system/bin/am start --user 0 -a android.intent.action.VIEW -d "$FOUND" >/dev/null 2>&1; then
    echo "[WARN] Browser could not be opened automatically."
    echo "[URL] $FOUND"
  fi
else
  echo "[WARN] Login URL not detected. Devine remains running."
  echo "[INFO] Log: $RUNLOG"
fi

wait "$DEVINE_PID"
STATUS=$?
exit "$STATUS"
