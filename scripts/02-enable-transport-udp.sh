#!/usr/bin/env bash
# Enable [transport-udp] bind 0.0.0.0:5060 in pjsip.conf.
# Stock ASL3 often has a commented ;[transport-udp] block — uncomment it.
# Some images omit that sample entirely — append a minimal transport.
set -euo pipefail

STAMP="$(date +%Y%m%d)"
cp /etc/asterisk/pjsip.conf "/etc/asterisk/pjsip.conf.backup-byon-${STAMP}"

python3 <<'PY'
from pathlib import Path
import re

p = Path("/etc/asterisk/pjsip.conf")
text = p.read_text()
lines = text.splitlines(True)

# Already active — nothing to do (bind may already be set).
if re.search(r"(?m)^\[transport-udp\]\s*$", text):
    print("OK: [transport-udp] already present")
    raise SystemExit(0)

out, i, done = [], 0, False
while i < len(lines):
    line = lines[i]
    if not done and re.match(r"^;\[transport-udp\]\s*$", line):
        out.append("[transport-udp]\n")
        i += 1
        while i < len(lines):
            l = lines[i]
            if not l.strip() or (l.startswith(";[") and "transport-udp]" not in l):
                break
            if l.startswith(";"):
                l = l[1:]
            if l.lstrip().startswith("bind="):
                l = "bind=0.0.0.0:5060\n"
            out.append(l if l.endswith("\n") else l + "\n")
            i += 1
        done = True
        continue
    out.append(line)
    i += 1

if done:
    p.write_text("".join(out))
    print("OK: uncommented [transport-udp] bind=0.0.0.0:5060")
    raise SystemExit(0)

# No sample block — append minimal UDP transport (BYON LAN SIP).
append = (
    "\n"
    "; Magic PTT BYON — added (stock pjsip.conf had no ;[transport-udp] sample)\n"
    "[transport-udp]\n"
    "type=transport\n"
    "protocol=udp\n"
    "bind=0.0.0.0:5060\n"
)
p.write_text("".join(out) + append)
print("OK: appended [transport-udp] bind=0.0.0.0:5060")
PY

systemctl restart asterisk
sleep 2
asterisk -rx 'pjsip show transports'
ss -ulnp | grep 5060 || echo "WARN: nothing on UDP 5060 yet"

echo "OK: transport-udp"
