#!/system/bin/sh
# Devine GitHub launcher — module-informed fast startup
BASE=https://raw.githubusercontent.com/DEVINESTREAMER/ROOT/main
DIR=/data/local/tmp/devine
BIN=$DIR/Devine2.5.sh
RESET=$DIR/reset_port.sh
LOG=$DIR/devine_runtime.log
export PATH=/system/bin:/system/xbin:/vendor/bin:/data/data/com.termux/files/usr/bin:$PATH
[ "$(id -u)" = 0 ] || { echo '[ERROR] Run as root'; exit 1; }
mkdir -p "$DIR" || exit 1
chmod 700 "$DIR"
port_up() { grep -qiE ':1F90 [0-9A-F:]+ 0A ' /proc/net/tcp /proc/net/tcp6 2>/dev/null; }
fetch() {
  url=$1; dest=$2; temp="$dest.part"; rm -f "$temp"
  if [ -x /data/data/com.termux/files/usr/bin/curl ]; then
    /data/data/com.termux/files/usr/bin/curl -fLsS --connect-timeout 7 --max-time 90 --retry 1 "$url" -o "$temp" || return 1
  elif command -v curl >/dev/null 2>&1; then
    curl -fLsS --connect-timeout 7 --max-time 90 "$url" -o "$temp" || return 1
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$temp" "$url" || return 1
  else echo '[ERROR] curl/wget unavailable'; return 1; fi
  [ -s "$temp" ] || return 1
  mv -f "$temp" "$dest"
}
open_browser() {
  URL=$1
  /system/bin/am start --user 0 -a android.intent.action.VIEW -d "$URL" >/dev/null 2>&1 || echo "[URL] $URL"
}
get_url() {
  sed 's/\033\[[0-9;]*[[:alpha:]]//g' "$LOG" 2>/dev/null | grep -Eo 'https?://([0-9]{1,3}\.){3}[0-9]{1,3}:[0-9]{2,5}(/[^[:space:]]*)?|https?://localhost:[0-9]{2,5}(/[^[:space:]]*)?' | head -1
}
echo '===== DEVINE FAST LAUNCHER ====='
# Do not kill another service on port 8080. An existing listener may already be Devine.
if port_up; then
  echo '[INFO] Port 8080 already listening. No reset or duplicate launch.'
  echo '[INFO] Open existing service (local): http://127.0.0.1:8080'
  open_browser http://127.0.0.1:8080
  exit 0
fi
# Download in parallel. A previously cached binary can still be used when network is unavailable.
fetch "$BASE/Devine2.5.sh" "$BIN" >"$DIR/download_bin.log" 2>&1 & P1=$!
fetch "$BASE/reset_port.sh" "$RESET" >"$DIR/download_reset.log" 2>&1 & P2=$!
wait "$P1"; R1=$?
wait "$P2"; R2=$?
[ "$R1" -eq 0 ] || { [ -s "$BIN" ] || { echo '[ERROR] Devine binary download failed'; cat "$DIR/download_bin.log"; exit 1; }; echo '[WARN] Using cached Devine binary'; }
[ "$R2" -eq 0 ] || echo '[WARN] reset_port.sh unavailable; safe port check used'
magic=$(od -An -tx1 -N4 "$BIN" 2>/dev/null | tr -d ' \n')
[ "$magic" = 7f454c46 ] || { echo '[ERROR] Devine binary is not ELF'; exit 1; }
chmod 700 "$BIN"
# Port is already free. Running opaque reset_port.sh would add delay and may terminate unrelated services.
echo '[OK] Port 8080 free — skipping reset_port.sh'
cd "$DIR" || exit 1
: > "$LOG"
"$BIN" >"$LOG" 2>&1 & PID=$!
echo "[INFO] Devine started (PID $PID); waiting for login URL..."
COUNT=0; FOUND=''
while [ "$COUNT" -lt 15 ]; do
  FOUND=$(get_url)
  [ -n "$FOUND" ] && break
  if port_up; then FOUND=http://127.0.0.1:8080; break; fi
  kill -0 "$PID" 2>/dev/null || break
  sleep 1
  COUNT=$((COUNT+1))
done
if [ -n "$FOUND" ]; then
  echo "[READY] $FOUND"
  open_browser "$FOUND"
else
  echo '[WARN] No URL detected in 15 seconds.'
  tail -n 20 "$LOG"
fi
echo "[INFO] Runtime log: $LOG"
# Keep process attached until it exits, while periodically showing log output.
tail -n +1 -f "$LOG" & TPID=$!
trap 'kill "$TPID" 2>/dev/null' EXIT INT TERM
wait "$PID"
