# Phone PTT key discovery

BYON keys the repeater via **SIP DTMF** on the phone patch (`rpt(node|P)`).

## Match your node's `rpt.conf`

Different sites use different phone-function mappings:

| Site type | Typical mapping | Key digits | Unkey |
|-----------|-----------------|------------|-------|
| Many member nodes | `99 = cop,6` | `*99` | `#` |
| Some central hubs | `6 = cop,6` | `*6` | `#` |

Example (many member nodes):

```ini
phone_functions = functions
99 = cop,6          ; PTT (phone mode only)
```

## Symptom

- RF → room works, app → RF silent  
- Cause: bridge sent the wrong key sequence (e.g. `*6` when the node expects `*99`)

## Verify on your node

```bash
grep -nE 'phone_functions|cop,6|^\[functions\]|^\[YOUR_NODE\]' /etc/asterisk/rpt.conf | head -40
```

Magic PTT Desktop **0.3.16+** defaults to `*99` / `#` for member nodes.
