DEVINE ROOT — MODULE-INFORMED FAST LAUNCHER
===========================================
Repository: https://github.com/DEVINESTREAMER/ROOT
Upload these three files to the ROOT of the public main branch:
- Devine2.5.sh (ELF executable)
- reset_port.sh (original encrypted reset script, included for compatibility)
- devine_github_launcher.sh (updated standalone launcher)

The launcher checks port 8080 first. If it is already listening, it opens
http://127.0.0.1:8080 instead of killing any existing service. If the port is
free, it skips the opaque reset script and starts the Devine binary directly.
It polls for the login URL/port for at most 15 seconds, then leaves Devine
running if no URL is found. Logs: /data/local/tmp/devine/devine_runtime.log

IMPORTANT: A port-8080 listener is not proof it belongs to Devine. The launcher
will not kill it. If a different application owns that port, stop that app
manually and rerun the launcher.

Termux command (after files are uploaded):
curl -fL https://raw.githubusercontent.com/DEVINESTREAMER/ROOT/main/devine_github_launcher.sh -o "$HOME/devine.sh" && su -c "sh /data/data/com.termux/files/home/devine.sh"

Security: Both original binaries and the encrypted reset script were provided
by the user. Do not run untrusted root binaries/scripts without auditing them.
