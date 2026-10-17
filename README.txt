DEVINE AURA - GitHub launcher v2

Upload devine_github_launcher.sh and Devine2.5.sh to the PUBLIC main branch of DEVINESTREAMER/ROOT.
Run in Termux:
curl -fL https://raw.githubusercontent.com/DEVINESTREAMER/ROOT/main/devine_github_launcher.sh -o "$HOME/devine.sh" && su -c "sh /data/data/com.termux/files/home/devine.sh"

Optional local driver path (absolute):
su -c 'sh /data/data/com.termux/files/home/devine.sh /sdcard/Download/driver.sh'

Driver input is copied to /data/local/tmp/devine/ before execution, unless already there.
.ko and .kpm require an installed compatible module loader.

The old supplied auto-fix runs before driver/startup checks: disables ADB, wireless ADB and Developer Options, stops adbd, and reports FRIDA/DOBBY/PCAPDROID process matches. It can disconnect an ADB shell and does not guarantee a PASS result for all checks. It does not remove third-party apps or bypass app-level checks.

No Android device test has been performed. Back up the module and verify the files before running as root.
