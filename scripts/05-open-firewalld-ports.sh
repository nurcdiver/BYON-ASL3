#!/usr/bin/env bash
# ASL3 ships firewalld (zone allstarlink). Open LAN AMI + SIP if firewall-cmd exists.
set -euo pipefail

if ! command -v firewall-cmd >/dev/null 2>&1; then
  echo "NOTE: firewall-cmd not found — skip firewalld ports"
  exit 0
fi

if ! firewall-cmd --state >/dev/null 2>&1; then
  echo "NOTE: firewalld not running — skip ports"
  exit 0
fi

ZONE="$(firewall-cmd --get-default-zone 2>/dev/null || echo allstarlink)"
if firewall-cmd --get-active-zones 2>/dev/null | grep -q '^allstarlink'; then
  ZONE="allstarlink"
fi

echo "== firewalld zone ${ZONE}: allow 5038/tcp (AMI) + 5060/udp (SIP)"
firewall-cmd --permanent --zone="${ZONE}" --add-port=5038/tcp >/dev/null || true
firewall-cmd --permanent --zone="${ZONE}" --add-port=5060/udp >/dev/null || true
firewall-cmd --reload >/dev/null || true
firewall-cmd --zone="${ZONE}" --list-ports || true
echo "OK: firewalld ports"
