DEVINE AURA ROOT + GITHUB LAUNCHER

1. Flash DEVINE_AURA_MAGISK_KERNELSU_MODULE.zip using Magisk/KernelSU/APatch module installer; reboot.
2. Upload devine_github_launcher.sh and Devine2.5.sh to PUBLIC GitHub DEVINESTREAMER/ROOT main branch.
3. Launcher: curl -fL https://raw.githubusercontent.com/DEVINESTREAMER/ROOT/main/devine_github_launcher.sh -o /data/local/tmp/devine_launcher.sh && su -c 'sh /data/local/tmp/devine_launcher.sh'
   If Termux cannot write /data/local/tmp, download to $HOME then copy with su.

Changes: preserve existing service, no automatic port 8080 killing, no long fixed startup retries, bounded startup checks, preserve driver setup and watchdog. Existing anti-detection checks remain unchanged, no forced PASS.
IMPORTANT: Driver and ELF code have not been independently audited; installing root modules is high risk. Test on backup device first. Not live-tested on Android.
