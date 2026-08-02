#!/usr/bin/env bash
# BYON one-shot ASL3 node prep.
# Usage: sudo ./install.sh --node YOUR_NODE --sip-user USER --sip-password PASS --lan 192.168.1.0/24
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE=""
SIP_USER="magicptt-byon"
SIP_PASS=""
LAN="192.168.1.0/24"

usage() {
  sed -n '2,12p' "$0"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --node) NODE="$2"; shift 2 ;;
    --sip-user) SIP_USER="$2"; shift 2 ;;
    --sip-password) SIP_PASS="$2"; shift 2 ;;
    --lan) LAN="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

[[ -n "$NODE" && -n "$SIP_PASS" ]] || usage
[[ "$(id -u)" -eq 0 ]] || { echo "Run as root (sudo ./install.sh …)"; exit 1; }

echo "== BYON node prep: rpt ${NODE}, SIP user ${SIP_USER}, LAN ${LAN}"

bash "$ROOT/scripts/01-enable-pjsip-modules.sh"
bash "$ROOT/scripts/02-enable-transport-udp.sh"
bash "$ROOT/scripts/03-install-peer.sh" \
  --node "$NODE" \
  --sip-user "$SIP_USER" \
  --sip-password "$SIP_PASS" \
  --lan "$LAN"

echo ""
echo "Done. Verify:"
echo "  asterisk -rx 'pjsip show endpoint ${SIP_USER}'"
echo "  asterisk -rx 'dialplan show magicptt-byon'"
echo "  ss -ulnp | grep 5060"
echo ""
echo "Next: Magic PTT Desktop (same LAN) → AllStarLink3 → Save SIP → Start bridge."
