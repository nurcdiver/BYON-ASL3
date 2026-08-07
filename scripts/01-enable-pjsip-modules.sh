#!/usr/bin/env bash
# Enable PJSIP + sorcery + RTP helpers for BYON node prep.
set -euo pipefail

STAMP="$(date +%Y%m%d)"
cp /etc/asterisk/modules.conf "/etc/asterisk/modules.conf.backup-byon-${STAMP}"

sed -i -E \
  's/^;load[[:space:]]*=[[:space:]]*(res_pjproject\.so|.*pjsip.*)/load = \1/' \
  /etc/asterisk/modules.conf

sed -i -E \
  's/^;load[[:space:]]*=[[:space:]]*(res_sorcery_.*|res_rtp_asterisk\.so|func_sorcery\.so|bridge_(builtin_features|builtin_interval_features|holding|native_rtp|simple)\.so)/load = \1/' \
  /etc/asterisk/modules.conf

grep -nE 'noload.*sorcery|noload.*pjproject|noload.*pjsip' /etc/asterisk/modules.conf || true

systemctl restart asterisk
sleep 3
asterisk -rx 'module show like sorcery' | head -20
asterisk -rx 'module show like pjsip' | head -40
grep -iE 'pjproject|Failed to resolve|unknown dependencies' /var/log/asterisk/messages.log | tail -10 || true

echo "OK: PJSIP modules loaded"
