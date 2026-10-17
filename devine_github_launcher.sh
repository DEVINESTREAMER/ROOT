#!/system/bin/sh
# DEVINE AURA: visual launcher, non-destructive port handling
BASE=https://raw.githubusercontent.com/DEVINESTREAMER/ROOT/main
DIR=/data/local/tmp/devine
BIN=$DIR/Devine2.5.sh
LOG=$DIR/devine_runtime.log
PATH=/system/bin:/system/xbin:/vendor/bin:/data/data/com.termux/files/usr/bin:$PATH
export PATH
[ "$(id -u)" = 0 ] || { echo 'Root required'; exit 1; }
mkdir -p "$DIR" || exit 1
chmod 700 "$DIR"
# Bundled auto-fix is stored locally and invoked as a separate shell script.
cat > "$DIR/devine_auto_fix.sh" <<'DEVINE_AUTOFIX'
#!/system/bin/sh
[ "$(id -u)" = 0 ] || { echo '[ERROR] Root required'; exit 1; }
echo '=== DEVINE AUTO FIX ==='
# These are real device settings changes, not a spoof of security-check results.
settings put global adb_enabled 0 2>/dev/null
settings put global adb_wifi_enabled 0 2>/dev/null
settings put global development_settings_enabled 0 2>/dev/null
setprop ctl.stop adbd 2>/dev/null
unset LD_PRELOAD
for name in frida dobby pcapdroid; do
  if ps -A 2>/dev/null | grep -i "$name" | grep -v grep >/dev/null; then
    echo "[DETECTED] $name"
  else
    echo "[NOT FOUND] $name"
  fi
done
for key in adb_enabled adb_wifi_enabled development_settings_enabled; do
  echo "$key = $(settings get global "$key" 2>/dev/null)"
done
echo 'HOOK, RWX, CANARY and CAPTURE need application-level diagnostics.'
DEVINE_AUTOFIX
chmod 700 "$DIR/devine_auto_fix.sh"
cleanup(){ printf '\033[?25h\033[0m\n'; [ -n "$TAILPID" ] && kill "$TAILPID" 2>/dev/null; }
trap cleanup EXIT
C='\033[1;36m'; G='\033[1;32m'; P='\033[1;35m'; Y='\033[1;33m'; N='\033[0m'
printf '\033[2J\033[H'
printf "${P}╔══════════════════════════════════════╗\n║         D E V I N E  A U R A        ║\n║       ✦  NEON ROOT LAUNCHER  ✦      ║\n╚══════════════════════════════════════╝${N}\n"
printf "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}\n"
printf '  ◆ GitHub live loader   ◆ Driver support\n'
printf "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}\n\n"
port_up(){ grep -qiE ':1F90[[:space:]]+[0-9A-Fa-f:]+[[:space:]]+0A([[:space:]]|$)' /proc/net/tcp /proc/net/tcp6 2>/dev/null; }
fetch(){
  tmp="$BIN.part.$$"
  if [ -x /data/data/com.termux/files/usr/bin/curl ]; then
    /data/data/com.termux/files/usr/bin/curl -fLsS --connect-timeout 7 --max-time 90 --retry 1 "$BASE/Devine2.5.sh" -o "$tmp"
  elif command -v curl >/dev/null 2>&1; then
    curl -fLsS --connect-timeout 7 --max-time 90 --retry 1 "$BASE/Devine2.5.sh" -o "$tmp"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$tmp" "$BASE/Devine2.5.sh"
  else return 127; fi
  status=$?
  if [ "$status" -eq 0 ] && [ -s "$tmp" ]; then mv -f "$tmp" "$BIN"; else rm -f "$tmp"; return 1; fi
}
spin(){
  spid=$1; label=$2; i=0
  printf '\033[?25l'
  while kill -0 "$spid" 2>/dev/null; do
    case $((i%8)) in 0) s='◐';; 1) s='◓';; 2) s='◑';; 3) s='◒';; 4) s='◐';; 5) s='◓';; 6) s='◑';; 7) s='◒';; esac
    printf "\r${C}  %s${N}  %-32s" "$s" "$label"
    i=$((i+1)); sleep 0.18
  done
  wait "$spid"; result=$?
  if [ "$result" -eq 0 ]; then printf "\r${G}  ✔${N}  %-32s\n" "$label"; else printf "\r${Y}  !${N}  %-32s\n" "$label"; fi
  printf '\033[?25h'
  return "$result"
}
open_page(){ /system/bin/am start --user 0 -a android.intent.action.VIEW -d "$1" >/dev/null 2>&1 || printf 'Open manually: %s\n' "$1"; }
get_url(){ sed 's/\033\[[0-9;]*[[:alpha:]]//g' "$LOG" 2>/dev/null | grep -Eo 'https?://([0-9]{1,3}\.){3}[0-9]{1,3}:[0-9]{2,5}(/[^[:space:]]*)?|https?://localhost:[0-9]{2,5}(/[^[:space:]]*)?' | head -n 1; }
# Reuse the local listener without stopping it or trusting a stale log URL.
reuse_running(){
  printf "${G}  Already running on port 8080.${N}\n"
  printf '  URL: http://127.0.0.1:8080\n'
  open_page 'http://127.0.0.1:8080'
  exit 0
}
# Check before compatibility cleanup, driver prompts or downloads.
if port_up; then reuse_running; fi
if [ -x /data/data/com.termux/files/usr/bin/curl ]; then
  /data/data/com.termux/files/usr/bin/curl -fLsS --connect-timeout 3 --max-time 8 "$BASE/devine_check_diagnostics.sh" -o "$DIR/devine_check_diagnostics.sh" 2>/dev/null || :
fi

# Optional driver installer. Provide a local file path only when driver is missing.
DRIVER_INPUT=${1:-${DRIVER_PATH:-}}
MODDIR=''
for m in /data/adb/modules/devine_ksu_shinobi /data/adb/modules_update/devine_ksu_shinobi; do
  [ -f "$m/scripts/driver_loader.sh" ] && { MODDIR=$m; break; }
done
driver_ready(){
  [ -e /dev/bing_rw ] && return 0
  for n in /dev/bing* /dev/devine* /dev/ksu_*; do [ -e "$n" ] && return 0; done
  return 1
}
run_driver(){
  dp=$1
  [ -f "$dp" ] || { printf "${Y}  ! Driver file not found: %s${N}\n" "$dp"; return 1; }
  case "$dp" in /*) ;; *) printf "${Y}  ! Use absolute file path (/storage/... or /data/...)${N}\n"; return 1;; esac
  # Stage an explicitly supplied trusted local file into /data/local/tmp.
  # Avoid overwriting source; never run arbitrary downloaded drivers automatically.
  case "$dp" in "$DIR"/*) staged="$dp";; *)
    staged="$DIR/driver_local_$$.${dp##*/}"
    cp "$dp" "$staged" || { echo 'Cannot copy driver to local tmp'; return 1; }
    chmod 700 "$staged" || return 1
  ;; esac
  dp="$staged"
  printf '  Staged driver: %s\n' "$dp"
  if [ -n "$MODDIR" ]; then
    printf '%s\n' "$dp" > "$MODDIR/driver_path.conf" || return 1
    sh "$MODDIR/scripts/driver_loader.sh" > "$DIR/driver_setup.log" 2>&1 & DPID=$!
    spin "$DPID" 'Installing driver via module loader' || { tail -n 12 "$DIR/driver_setup.log"; return 1; }
  else
    case "$dp" in
      *.ko|*.kpm) printf "${Y}  ! .ko/.kpm requires installed module loader${N}\n"; return 1;;
      *)
        magic=$(od -An -tx1 -N4 "$dp" 2>/dev/null | tr -d ' \n')
        if [ "$magic" = 7f454c46 ]; then
          chmod 700 "$dp"; "$dp" > "$DIR/driver_setup.log" 2>&1 &
        else
          sh "$dp" > "$DIR/driver_setup.log" 2>&1 &
        fi
        DPID=$!
        sleep 2
        if ! kill -0 "$DPID" 2>/dev/null; then wait "$DPID"; rc=$?; [ "$rc" -eq 0 ] || { tail -n 12 "$DIR/driver_setup.log"; return "$rc"; }; fi
      ;;
    esac
  fi
  return 0
}
# Run requested device-side compatibility cleanup before driver and Devine checks.
# WARNING: stopping adbd can disconnect a USB/ADB shell.
printf "${P}◆ AUTO FIX${N}  Device compatibility checks\n"
if [ -f "$DIR/devine_auto_fix.sh" ]; then
  sh "$DIR/devine_auto_fix.sh" > "$DIR/auto_fix.log" 2>&1
  FIXRC=$?
  if [ "$FIXRC" -eq 0 ]; then printf "${G}  ✔ Compatibility cleanup completed${N}\n"; else printf "${Y}  ! Cleanup returned %s; see %s${N}\n" "$FIXRC" "$DIR/auto_fix.log"; fi
fi
printf '\n'
printf "${P}◆ DRIVER CHECK${N}  Kernel driver status\n"
if driver_ready; then
  printf "${G}  ✔ Driver node already present${N}\n\n"
else
  printf "${Y}  ! Driver node not detected${N}\n"
  if [ -z "$DRIVER_INPUT" ] && [ -n "$MODDIR" ] && [ -s "$MODDIR/driver_path.conf" ]; then
    DRIVER_INPUT=$(head -n 1 "$MODDIR/driver_path.conf" | tr -d '\r')
    printf '  Saved driver: %s\n' "$DRIVER_INPUT"
  fi
  if [ -z "$DRIVER_INPUT" ] && [ -t 0 ]; then
    printf '  Enter local driver file path (Enter to skip): '
    IFS= read -r DRIVER_INPUT
  fi
  if [ -n "$DRIVER_INPUT" ]; then
    run_driver "$DRIVER_INPUT" || printf "${Y}  ! Driver setup failed; see log${N}\n"
    if driver_ready; then printf "${G}  ✔ Driver node detected${N}\n"; else printf "${Y}  ! Driver node still not detected${N}\n"; fi
  else
    printf '  Driver setup skipped. Pass path as first launcher argument to install.\n'
  fi
  printf '\n'
fi

printf "${P}◆ STEP 01${N}  Port 8080 status\n"
if port_up; then reuse_running; fi
printf "${G}  Port available; starting Devine.${N}\n\n"
printf "${P}◆ STEP 02${N}  Secure download\n"
fetch >"$DIR/download.log" 2>&1 & DL=$!
if ! spin "$DL" 'Fetching Devine from GitHub'; then
  if [ -s "$BIN" ]; then printf "${Y}  ! Using cached binary${N}\n"; else cat "$DIR/download.log"; exit 1; fi
fi
magic=$(od -An -tx1 -N4 "$BIN" 2>/dev/null | tr -d ' \n')
[ "$magic" = 7f454c46 ] || { echo 'Invalid ELF download'; exit 1; }
chmod 700 "$BIN"
if port_up; then reuse_running; fi
printf "\n${P}◆ STEP 03${N}  Launch sequence\n"
cd "$DIR" || exit 1
: > "$LOG"
"$BIN" >"$LOG" 2>&1 & PID=$!
tail -n +1 -f "$LOG" & TAILPID=$!
i=0; FOUND=''
while [ "$i" -lt 15 ]; do
  FOUND=$(get_url)
  [ -n "$FOUND" ] && break
  if port_up; then FOUND=http://127.0.0.1:8080; break; fi
  kill -0 "$PID" 2>/dev/null || break
  case $((i%4)) in 0) s='◴';; 1) s='◷';; 2) s='◶';; 3) s='◵';; esac
  printf "\r${C}  %s${N}  Booting Devine · %02ds / 15s" "$s" "$i"
  sleep 1; i=$((i+1))
done
printf '\n'
if [ -n "$FOUND" ]; then
  printf "${G}╔══════════════════════════════════════╗\n║         SERVICE IS READY             ║\n╚══════════════════════════════════════╝${N}\n"
  printf '  URL: %s\n' "$FOUND"
  open_page "$FOUND"
else
  printf "${Y}  ! URL not detected yet; check runtime log.${N}\n"
fi
printf '  Log: %s\n' "$LOG"
wait "$PID"
RC=$?
if grep -qiE 'blocked:|ADB[[:space:]]+FAIL' "$LOG" 2>/dev/null; then
  printf '\033[1;33m  ! Check failed; saving read-only diagnostics.\033[0m\n'
  DIAG="$DIR/check_diagnostics.txt"
  if [ -f "$DIR/devine_check_diagnostics.sh" ]; then
    sh "$DIR/devine_check_diagnostics.sh" "$LOG" >"$DIAG" 2>&1
  else
    grep -Ei 'FAIL|blocked:' "$LOG" | tail -n 20 >"$DIAG"
  fi
  printf '  Diagnostics: %s\n' "$DIAG"
fi
exit "$RC"
