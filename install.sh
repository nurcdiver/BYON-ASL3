#!/usr/bin/env bash
# BYON one-shot ASL3 node prep — Magic PTT proprietary add-on.
# Copyright (c) 2026 SHTF Radio Networks. See LICENSE (not open source).
# Usage:
#   sudo ./install.sh --node YOUR_NODE --sip-user USER --sip-password PASS \
#     --lan 192.168.1.0/24 \
#     [--ami-password PASS] [--ami-user magicptt-byon] [--ami-permit 192.168.0.0/255.255.0.0]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE=""
SIP_USER="magicptt-byon"
SIP_PASS=""
LAN="192.168.1.0/24"
AMI_USER="magicptt-byon"
AMI_PASS=""
# manager.conf permit= uses dotted mask, not CIDR. Empty → derive from --lan.
AMI_PERMIT=""
AMI_PERMIT_SET=0
STATE_DIR="/var/lib/magicptt-byon"

usage() {
  sed -n '2,12p' "$0"
  exit 1
}

# Convert CIDR (10.0.0.0/24) → AMI permit (10.0.0.0/255.255.255.0).
cidr_to_ami_permit() {
  local cidr="$1"
  python3 - "$cidr" <<'PY'
import ipaddress, sys
n = ipaddress.ip_network(sys.argv[1], strict=False)
print(f"{n.network_address}/{n.netmask}")
PY
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --node) NODE="$2"; shift 2 ;;
    --sip-user) SIP_USER="$2"; shift 2 ;;
    --sip-password) SIP_PASS="$2"; shift 2 ;;
    --lan) LAN="$2"; shift 2 ;;
    --ami-user) AMI_USER="$2"; shift 2 ;;
    --ami-password) AMI_PASS="$2"; shift 2 ;;
    --ami-permit) AMI_PERMIT="$2"; AMI_PERMIT_SET=1; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

[[ -n "$NODE" && -n "$SIP_PASS" ]] || usage
[[ "$(id -u)" -eq 0 ]] || { echo "Run as root (sudo ./install.sh …)"; exit 1; }

if [[ "$AMI_PERMIT_SET" -eq 0 || -z "$AMI_PERMIT" ]]; then
  AMI_PERMIT="$(cidr_to_ami_permit "$LAN")"
fi

echo "== BYON node prep: rpt ${NODE}, SIP user ${SIP_USER}, LAN ${LAN}"
echo "   AMI permit ${AMI_PERMIT}"

bash "$ROOT/scripts/01-enable-pjsip-modules.sh"
bash "$ROOT/scripts/02-enable-transport-udp.sh"
bash "$ROOT/scripts/03-install-peer.sh" \
  --node "$NODE" \
  --sip-user "$SIP_USER" \
  --sip-password "$SIP_PASS" \
  --lan "$LAN"

if [[ -n "$AMI_PASS" ]]; then
  echo "== AMI user for Magic PTT Desktop Repeater desk"
  bash "$ROOT/scripts/04-install-ami-user.sh" \
    --ami-user "$AMI_USER" \
    --ami-password "$AMI_PASS" \
    --ami-permit "$AMI_PERMIT"
else
  echo "NOTE: No --ami-password — skipping AMI user (bridge audio still works)."
  echo "      Re-run with --ami-password to enable Repeater desk login/link/commands."
fi

# Persist install args so apt reapply can restore after ASL package wipes.
install -d -m 0750 "$STATE_DIR"
umask 077
cat > "$STATE_DIR/install.env" <<EOF
INSTALL_ROOT=$ROOT
NODE=$NODE
SIP_USER=$SIP_USER
SIP_PASS=$SIP_PASS
LAN=$LAN
AMI_USER=$AMI_USER
AMI_PASS=$AMI_PASS
AMI_PERMIT=$AMI_PERMIT
EOF
chmod 600 "$STATE_DIR/install.env"

# Auto-restore after ASL3 / Debian updates.
install -m 0755 "$ROOT/scripts/magicptt-byon-reapply.sh" \
  /usr/local/sbin/magicptt-byon-reapply.sh
if [[ -d /etc/apt/apt.conf.d && -f "$ROOT/apt/99-magicptt-byon" ]]; then
  install -m 0644 "$ROOT/apt/99-magicptt-byon" /etc/apt/apt.conf.d/99-magicptt-byon
  echo "apt hook -> /etc/apt/apt.conf.d/99-magicptt-byon"
fi
if [[ -d /etc/systemd/system && -f "$ROOT/systemd/magicptt-byon-reapply.service" ]]; then
  install -m 0644 "$ROOT/systemd/magicptt-byon-reapply.service" \
    /etc/systemd/system/magicptt-byon-reapply.service
  install -m 0644 "$ROOT/systemd/magicptt-byon-reapply.timer" \
    /etc/systemd/system/magicptt-byon-reapply.timer
  systemctl daemon-reload >/dev/null 2>&1 || true
  systemctl enable --now magicptt-byon-reapply.timer >/dev/null 2>&1 || true
  echo "systemd timer -> magicptt-byon-reapply.timer (daily safety net)"
fi

echo ""
echo "Done. Verify:"
echo "  asterisk -rx 'pjsip show endpoint ${SIP_USER}'"
echo "  asterisk -rx 'dialplan show magicptt-byon'"
echo "  ss -ulnp | grep 5060"
if [[ -n "$AMI_PASS" ]]; then
  echo "  ss -tlnp | grep 5038"
  echo "  AMI user: ${AMI_USER}  (enter in Magic PTT Desktop → AllStarLink3)"
fi
echo ""
echo "After ASL updates: auto-restored by apt hook + daily timer"
echo "  Manual: sudo MAGICPTT_BYON_FORCE=1 /usr/local/sbin/magicptt-byon-reapply.sh"
echo "  Log: /var/log/magicptt-byon-reapply.log"
echo ""
echo "Next: Magic PTT Desktop (same LAN) → AllStarLink3 → Save → Start bridge."
