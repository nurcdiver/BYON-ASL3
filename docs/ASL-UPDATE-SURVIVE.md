# Surviving ASL3 / Debian package updates

ASL packages often rewrite stock files under `/etc/asterisk/`
(`pjsip.conf`, `extensions.conf`, `modules.conf`, `manager.conf`).

## What BYON does

1. **Additive files we own** (usually survive apt):
   - `pjsip_magicptt_byon.conf`
   - `extensions_magicptt_byon.conf`
   - `manager_magicptt_byon.conf` (when installed with `--ami-password`)

2. **One-line `#include`s** in stock parents — these get wiped.  
   `install.sh` registers:
   - apt hook: `/etc/apt/apt.conf.d/99-magicptt-byon`
   - daily timer: `magicptt-byon-reapply.timer`
   - script: `/usr/local/sbin/magicptt-byon-reapply.sh`

3. **Install state** at `/var/lib/magicptt-byon/install.env` so a full
   re-run of `install.sh` is possible if additive files were deleted.

## After an ASL update

Usually nothing — the apt hook restores includes automatically.

Manual force:

```bash
sudo MAGICPTT_BYON_FORCE=1 /usr/local/sbin/magicptt-byon-reapply.sh
```

Or from your clone:

```bash
cd BYON-ASL3
sudo ./install.sh --node … --sip-password … --ami-password … --lan …
```

Log: `/var/log/magicptt-byon-reapply.log`
