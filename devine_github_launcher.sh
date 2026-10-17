#!/system/bin/sh
# DEVINE AURA: visual launcher, non-destructive port handling
BASE=https://raw.githubusercontent.com/DEVINESTREAMER/ROOT/main
DIR=/data/local/tmp/devine
BIN=$DIR/Devine2.5.sh
LOG=$DIR/devine_runtime.log
PATH=/system/bin:/system/xbin:/vendor/bin:/data/data/com.termux/files/usr/bin:$PATH
export PATH
[ "$(id -u)" = 0 ] || { echo 'Root required'; exit 1; }
# Prefer the installed module to preserve its driver and lifecycle management.
MODULE=/data/adb/modules/devine_ksu_shinobi
if [ -f "$MODULE/scripts/start_full.sh" ]; then
  printf '\033[1;35m✦ Installed root module detected — safe start\033[0m\n'
  sh "$MODULE/scripts/start_full.sh"
  RC=$?
  [ "$RC" -eq 2 ] && { echo 'Port 8080 is busy; no service was stopped.'; exit 2; }
  [ "$RC" -ne 0 ] && exit "$RC"
  /system/bin/am start --user 0 -a android.intent.action.VIEW -d http://127.0.0.1:8080 >/dev/null 2>&1 || true
  exit 0
fi
mkdir -p "$DIR" || exit 1
chmod 700 "$DIR"
cleanup(){ printf '\033[?25h\033[0m\n'; [ -n "$TAILPID" ] && kill "$TAILPID" 2>/dev/null; }
trap cleanup EXIT
C='\033[1;36m'; G='\033[1;32m'; P='\033[1;35m'; Y='\033[1;33m'; N='\033[0m'
printf '\033[2J\033[H'
printf "${P}╔══════════════════════════════════════╗\n║         D E V I N E  A U R A        ║\n║       ✦  NEON ROOT LAUNCHER  ✦      ║\n╚══════════════════════════════════════╝${N}\n"
printf "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}\n"
printf '  ◆ GitHub live loader   ◆ Port-safe start\n'
printf "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}\n\n"
port_up(){ awk 'NR>1 && $2 ~ /:1F90$/ && $4=="0A" {found=1} END{exit !found}' /proc/net/tcp /proc/net/tcp6 2>/dev/null; }
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
printf "${P}◆ STEP 01${N}  Port 8080 status\n"
if port_up; then
  printf "${G}  ✔ Existing listener detected; untouched.${N}\n"
  echo "Port belongs to an unknown service; not touching it."
  exit 2
fi
printf "${G}  ✔ Port available; no process will be killed.${N}\n\n"
printf "${P}◆ STEP 02${N}  Secure download\n"
fetch >"$DIR/download.log" 2>&1 & DL=$!
if ! spin "$DL" 'Fetching Devine from GitHub'; then
  if [ -s "$BIN" ]; then printf "${Y}  ! Using cached binary${N}\n"; else cat "$DIR/download.log"; exit 1; fi
fi
magic=$(od -An -tx1 -N4 "$BIN" 2>/dev/null | tr -d ' \n')
[ "$magic" = 7f454c46 ] || { echo 'Invalid ELF download'; exit 1; }
chmod 700 "$BIN"
if port_up; then echo "Port 8080 became occupied; not touching it."; exit 2; fi
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
