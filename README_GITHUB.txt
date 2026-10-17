# DEVINE ROOT — GitHub upload package

Upload these THREE files individually to the root of the PUBLIC repository https://github.com/DEVINESTREAMER/ROOT on the `main` branch:

- Devine2.5.sh (Android ARM64 ELF executable; do NOT run using `sh`)
- reset_port.sh (shell script)
- devine_github_launcher.sh (root shell launcher)

The launcher downloads the first two from GitHub RAW, executes reset_port.sh and then launches Devine. It requires Android root and a working curl or wget. Its port-reset operation may terminate another process listening on port 8080. Only run files you trust.

Raw launcher URL after uploading:
https://raw.githubusercontent.com/DEVINESTREAMER/ROOT/main/devine_github_launcher.sh

Example: download launcher in Termux, then run from root shell (adjust paths for your environment):
`curl -fL https://raw.githubusercontent.com/DEVINESTREAMER/ROOT/main/devine_github_launcher.sh -o /sdcard/Download/devine_github_launcher.sh`
`su -c 'sh /sdcard/Download/devine_github_launcher.sh'`

Note: Android may restrict execution or shell access to /sdcard on some devices; copy to /data/local/tmp if needed. No GitHub upload has been performed by this package.
