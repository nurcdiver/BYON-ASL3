# BYON — Bring Your Own Node (ASL3 ↔ WebRTC room)

**BYON** links a member-owned **AllStarLink3 node** on the LAN to a **Nexus voice room**
using **Magic PTT Desktop** on the same network. RF traffic stays on the member's LAN;
internet PTT rides the Nexus room only.

This repository contains everything needed to **prepare an ASL3 node** for BYON.
Download Magic PTT Desktop from [magicptt.com](https://magicptt.com) (**0.3.23+**).

> **Ownership:** BYON is a **Magic PTT add-on**, not open source. SHTF Radio Networks
> retains all rights. You may use these files only to prep **your own** node for
> **your** Magic PTT My Room. Do not redistribute, fork for others, or build a
> competing service from this repo. Live BYON access may become a **premium Magic PTT
> feature**; this repo does not grant platform access by itself. See `LICENSE`.

## Architecture

```
[Phones / browsers] ──WebRTC──► [Nexus voice room]
                                      ▲
                                      │ WebRTC (Desktop Connect)
[ASL3 node / repeater] ◄──LAN SIP──► [Bridge PC on same LAN]
```

- **Direct LAN SIP** to your node — not through a shared internet hub or cloud SIP trunk to your home network.
- One bridge per linked My Room, running only while the Desktop bridge is started.
- Audio: Opus in the room → Desktop → G.711 on LAN SIP → `rpt(node|P)`.

## Quick start (node prep — one command)

On the **ASL3 node** (SSH):

```bash
git clone https://github.com/nurcdiver/BYON-ASL3.git
cd BYON-ASL3
sudo ./install.sh \
  --node YOUR_NODE \
  --sip-user magicptt-byon \
  --sip-password 'CHOOSE_A_STRONG_PASSWORD' \
  --lan 192.168.1.0/24
```

Then on the **bridge PC** (Magic PTT Desktop, same LAN):

1. My Room → **AllStarLink3** — enter node IP, node number, SIP user/password → Save  
2. PTT page → **Start RF bridge**

See `docs/SMOKE-TEST.md` for a full verification checklist.

## What this repo contains

| Path | Purpose |
|------|---------|
| `install.sh` | One-shot node prep (modules + transport + peer + dialplan) |
| `scripts/` | Individual steps (for debugging or partial re-run) |
| `templates/` | Parameterized Asterisk includes |
| `docs/` | Architecture, phone-key discovery, smoke test |

## Phone PTT keying (critical)

Member nodes often use **`*99`** to key phone-mode PTT. Some central hub systems use `*6` instead — match **your** node's `rpt.conf` (see `docs/PHONE-KEY.md`).

## Requirements

- AllStarLink3 on the same LAN as the bridge PC  
- PJSIP enabled on the node (this repo automates that)  
- UDP **5060** reachable from the bridge PC  
- Magic PTT Desktop **0.3.23+** with AllStar Link enabled for your My Room  

## License

**Proprietary — all rights reserved.** Not MIT, not GPL, not public domain.

See [`LICENSE`](LICENSE). Summary:

- **Allowed:** run `install.sh` on **your** ASL3 node to link **your** My Room via Magic PTT Desktop, while you have a valid Magic PTT account and admin-enabled AllStar Link.
- **Not allowed:** redistribute, sell, mirror, fork for others, strip notices, or use any of this to build a competing PTT/bridge product.
- **Premium:** Magic PTT may charge for BYON / AllStar Link in the future; cloning this repo does not bypass that.

Questions or licensing requests: magicptt.com.

## Status

Field-proven LAN SIP setup with two-way RF ↔ room audio. Node automation lives here;
configure and start the bridge in Magic PTT Desktop.
