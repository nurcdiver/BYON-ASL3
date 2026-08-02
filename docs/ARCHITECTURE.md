# Architecture

## Problem

Members want **internet PTT** (phones, browsers) on a **My Room voice channel** while
**RF on their own repeater/node** stays on the LAN — without routing through a
shared hub or exposing home SIP to the internet.

## Solution (BYON v1)

| Leg | Technology |
|-----|------------|
| Internet ↔ room | WebRTC / Opus (Nexus) |
| Room ↔ bridge PC | WebRTC (Magic PTT Desktop) |
| Bridge PC ↔ node | **LAN SIP** + G.711 RTP (UDP, same subnet) |
| Node ↔ RF | AllStar `rpt(node\|P)` phone patch |

## Why not cloud SIP straight to the home node?

Some systems bridge a **cloud SIP server** to a central hub, then IAX to repeaters.
Home nodes are usually **`192.168.x.x`** — the cloud cannot reach them directly.
BYON puts the SIP leg on a **PC on the same LAN** as the node instead.

## Audio path

**App → RF:** Opus @ 48 kHz → Desktop → PCMU 8 kHz 20 ms → SIP  
**RF → App:** PCMU → gain → 48 kHz → Nexus (WebRTC)

## One bridge per room

The Desktop PC running the bridge must stay on the same LAN as the node.
Bridge is **manual start/stop** (PTT page). RF is not bridged when Desktop is off.

## What this repo covers

| In this repo | In Magic PTT (Desktop + app) |
|--------------|------------------------------|
| Node PJSIP + peer + dialplan | SIP bridge client + media mix |
| Install scripts + templates | AllStarLink3 settings + Start bridge |
| Smoke test + rollback | Sign-in, My Room, Nexus Connect |
