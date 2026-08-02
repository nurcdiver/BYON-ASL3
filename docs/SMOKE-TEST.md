# Smoke test checklist

## Node prep (this repo)

After `sudo ./install.sh …`:

```bash
asterisk -rx 'pjsip show transports'          # transport-udp on 0.0.0.0:5060
asterisk -rx 'pjsip show endpoint YOUR_USER'  # endpoint listed
asterisk -rx 'dialplan show magicptt-byon'    # exten → rpt
ss -ulnp | grep 5060
```

From bridge PC (same LAN):

```bash
# Optional — SIP OPTIONS (Desktop does this automatically)
echo -e "OPTIONS sip:NODE_IP SIP/2.0\r\n..." | nc -u NODE_IP 5060
```

## Magic PTT Desktop (bridge client)

Requires Magic PTT Desktop **0.3.23+**, My Room with AllStar Link enabled, owner account.

1. AllStarLink3 tab → node IP, node number, SIP user/password → Save  
2. PTT page → Start RF bridge  
3. Expect: Nexus up · SIP up · RF ↔ room mix active  
4. Second client in room: hear RF when radio keys; key PTT → hear on RF  
5. Stop bridge when done

## Rollback (node only)

```bash
sudo sed -i '/pjsip_magicptt_byon.conf/d' /etc/asterisk/pjsip.conf
sudo sed -i '/extensions_magicptt_byon.conf/d' /etc/asterisk/extensions.conf
sudo rm -f /etc/asterisk/pjsip_magicptt_byon.conf /etc/asterisk/extensions_magicptt_byon.conf
sudo asterisk -rx 'module reload res_pjsip.so'
sudo asterisk -rx 'dialplan reload'
```
