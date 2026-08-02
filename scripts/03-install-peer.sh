#!/usr/bin/env bash
# Additive BYON peer + dialplan — only adds new include files on the node.
set -euo pipefail

NODE=""
SIP_USER="magicptt-byon"
SIP_PASS=""
LAN="192.168.1.0/24"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --node) NODE="$2"; shift 2 ;;
    --sip-user) SIP_USER="$2"; shift 2 ;;
    --sip-password) SIP_PASS="$2"; shift 2 ;;
    --lan) LAN="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

[[ -n "$NODE" && -n "$SIP_PASS" ]] || { echo "Need --node and --sip-password"; exit 1; }

cat > /etc/asterisk/pjsip_magicptt_byon.conf <<EOF
; Magic PTT BYON Desktop peer — ADDITIVE (BYON-ASL3 install)

[${SIP_USER}]
type=endpoint
transport=transport-udp
context=magicptt-byon
disallow=all
allow=ulaw
allow=alaw
auth=${SIP_USER}
aors=${SIP_USER}
direct_media=no
rtp_symmetric=yes
force_rport=yes
rewrite_contact=yes

[${SIP_USER}]
type=auth
auth_type=userpass
username=${SIP_USER}
password=${SIP_PASS}

[${SIP_USER}]
type=aor
max_contacts=2
remove_existing=yes

[${SIP_USER}-identify]
type=identify
endpoint=${SIP_USER}
match=${LAN}
EOF

cat > /etc/asterisk/extensions_magicptt_byon.conf <<EOF
; Magic PTT BYON dialplan — Desktop SIP → local rpt node ${NODE}

[magicptt-byon]
exten => ${NODE},1,NoOp(Magic PTT BYON Desktop -> rpt ${NODE})
 same => n,Answer()
 same => n,rpt(${NODE}|P)
 same => n,Hangup()
exten => ${SIP_USER},1,Goto(${NODE},1)
exten => s,1,Goto(${NODE},1)
EOF

grep -qF 'pjsip_magicptt_byon.conf' /etc/asterisk/pjsip.conf \
  || echo '#include pjsip_magicptt_byon.conf' >> /etc/asterisk/pjsip.conf
grep -qF 'extensions_magicptt_byon.conf' /etc/asterisk/extensions.conf \
  || echo '#include extensions_magicptt_byon.conf' >> /etc/asterisk/extensions.conf

chown asterisk:asterisk /etc/asterisk/pjsip_magicptt_byon.conf \
  /etc/asterisk/extensions_magicptt_byon.conf

asterisk -rx 'module reload res_pjsip.so'
asterisk -rx 'dialplan reload'
sleep 1
asterisk -rx "pjsip show endpoint ${SIP_USER}"
asterisk -rx 'dialplan show magicptt-byon'

echo "OK: peer ${SIP_USER} → rpt(${NODE}|P)"
