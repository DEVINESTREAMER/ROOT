#!/system/bin/sh

echo "================================"
echo " DEVINE AURA - CAPTURE DIAGNOSTIC"
echo "================================"

if [ "$(id -u)" != "0" ]; then
    echo "[ERROR] Root required"
    exit 1
fi

DIR=/data/local/tmp/devine
mkdir -p "$DIR"

echo "[1] Checking screen capture..."
CAPTURE=$(dumpsys media_projection 2>/dev/null)

if echo "$CAPTURE" | grep -q "Media Projection:"; then
    echo "$CAPTURE" | grep -A 3 "Media Projection:"
fi

echo "[2] Checking capture processes..."
ps -A | grep -Ei 'screenrecord|scrcpy|tcpdump|pcapdroid' \
    || echo "[OK] No matching processes"

echo "[3] Checking port 8080..."
ss -ltn 2>/dev/null | grep ':8080 ' \
    || echo "[OK] Port 8080 free"

echo "[4] Checking previous Devine error..."
if [ -f "$DIR/devine_runtime.log" ]; then
    grep -Ei 'CAPTURE|FAIL|WARN|terminated' \
        "$DIR/devine_runtime.log" | tail -n 15
fi

echo "================================"
echo " DIAGNOSTIC COMPLETED"
echo "================================"