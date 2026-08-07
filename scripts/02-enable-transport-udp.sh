#!/usr/bin/env bash
# Uncomment [transport-udp] bind 0.0.0.0:5060 in stock pjsip.conf.
set -euo pipefail

STAMP="$(date +%Y%m%d)"
cp /etc/asterisk/pjsip.conf "/etc/asterisk/pjsip.conf.backup-byon-${STAMP}"

python3 <<'PY'
from pathlib import Path
import re
p = Path("/etc/asterisk/pjsip.conf")
lines = p.read_text().splitlines(True)
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
if not done:
    raise SystemExit(";[transport-udp] block not found — edit pjsip.conf by hand")
p.write_text("".join(out))
print("OK: [transport-udp] bind=0.0.0.0:5060")
PY

systemctl restart asterisk
sleep 2
asterisk -rx 'pjsip show transports'
ss -ulnp | grep 5060 || echo "WARN: nothing on UDP 5060 yet"

echo "OK: transport-udp"
