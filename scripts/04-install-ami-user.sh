#!/usr/bin/env bash
# Additive AMI user for Magic PTT Desktop Repeater desk.
set -euo pipefail

AMI_USER="magicptt-byon"
AMI_PASS=""
AMI_PERMIT="192.168.0.0/255.255.0.0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ami-user) AMI_USER="$2"; shift 2 ;;
    --ami-password) AMI_PASS="$2"; shift 2 ;;
    --ami-permit) AMI_PERMIT="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

[[ -n "$AMI_PASS" ]] || { echo "Need --ami-password"; exit 1; }

# manager.conf uses subnet mask form for permit= (not CIDR).
cat > /etc/asterisk/manager_magicptt_byon.conf <<EOF
; Magic PTT BYON AMI user — ADDITIVE (BYON-ASL3 install)
; Desktop Repeater desk: status, link, curated commands.

[${AMI_USER}]
secret = ${AMI_PASS}
deny = 0.0.0.0/0.0.0.0
permit = ${AMI_PERMIT}
read = system,call,log,verbose,command,agent,user,config,dtmf,reporting,cdr,dialplan
write = system,call,agent,user,config,command,reporting,originate
writetimeout = 5000
EOF

# Ensure manager is enabled and our include is present.
if [[ -f /etc/asterisk/manager.conf ]]; then
  sed -i -E 's/^[[:space:]]*enabled[[:space:]]*=[[:space:]]*no/enabled = yes/I' \
    /etc/asterisk/manager.conf || true
  if ! grep -qE '^[[:space:]]*enabled[[:space:]]*=' /etc/asterisk/manager.conf; then
    # Ensure [general] has enabled=yes
    if grep -q '^\[general\]' /etc/asterisk/manager.conf; then
      sed -i '/^\[general\]/a enabled = yes' /etc/asterisk/manager.conf
    fi
  fi
  grep -qF 'manager_magicptt_byon.conf' /etc/asterisk/manager.conf \
    || echo '#include manager_magicptt_byon.conf' >> /etc/asterisk/manager.conf
fi

chown asterisk:asterisk /etc/asterisk/manager_magicptt_byon.conf
asterisk -rx 'manager reload' >/dev/null 2>&1 || true
asterisk -rx 'module reload manager' >/dev/null 2>&1 || true

echo "OK: AMI user ${AMI_USER} (permit ${AMI_PERMIT})"
echo "  Desktop AllStarLink3 → AMI user/password (same as install) → Login"
