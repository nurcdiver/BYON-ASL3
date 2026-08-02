# Magic PTT Desktop (bridge client)

BYON uses **Magic PTT Desktop** on the LAN as the bridge host. The Desktop app is
not part of this repository — this repo prepares your **ASL3 node** only.

## Minimum version

**0.3.23+**

Download: https://magicptt.com/desktop/Magic-PTT-Desktop-Setup.exe

## What Desktop does

1. Signs in and joins your My Room on **Nexus** as the bridge participant  
2. SIP OPTIONS probe → Digest INVITE → `rpt(node|P)` on the LAN  
3. DTMF `*99` / `#` on most member nodes (or `*6` / `#` on some hub-style configs)  
4. G.711 ↔ Nexus WebRTC media mix  

## Configuration (Magic PTT app)

- My Room → **AllStarLink3** tab — node IP, node number, SIP credentials  
- PTT page → **Start / Stop RF bridge** (Desktop only)

Use the **same** SIP user and password you chose when running `install.sh` on the node.
