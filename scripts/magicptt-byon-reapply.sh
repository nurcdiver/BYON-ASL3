#!/usr/bin/env bash
# Re-apply Magic PTT BYON includes after ASL3 / Debian package updates wipe stock confs.
# Installed as /usr/local/sbin/magicptt-byon-reapply.sh — safe to run often.
set -euo pipefail

LOG="${MAGICPTT_BYON_LOG:-/var/log/magicptt-byon-reapply.log}"
STATE_DIR="/var/lib/magicptt-byon"
STATE_FILE="$STATE_DIR/install.env"
FORCE="${MAGICPTT_BYON_FORCE:-0}"

log() {
  local line
  line="$(date -Is) $*"
  echo "$line" >>"$LOG" 2>/dev/null || true
  echo "$line"
}

theme_ok() {
  [[ -f /etc/asterisk/pjsip_magicptt_byon.conf ]] || return 1
  [[ -f /etc/asterisk/extensions_magicptt_byon.conf ]] || return 1
  grep -qF 'pjsip_magicptt_byon.conf' /etc/asterisk/pjsip.conf 2>/dev/null || return 1
  grep -qF 'extensions_magicptt_byon.conf' /etc/asterisk/extensions.conf 2>/dev/null || return 1
  # AMI optional until first install with --ami-password
  if [[ -f /etc/asterisk/manager_magicptt_byon.conf ]]; then
    grep -qF 'manager_magicptt_byon.conf' /etc/asterisk/manager.conf 2>/dev/null || return 1
  fi
  return 0
}

ensure_includes_only() {
  # Fast path: stock parents lost #include lines but our additive files remain.
  if [[ -f /etc/asterisk/pjsip_magicptt_byon.conf ]]; then
    grep -qF 'pjsip_magicptt_byon.conf' /etc/asterisk/pjsip.conf 2>/dev/null \
      || echo '#include pjsip_magicptt_byon.conf' >> /etc/asterisk/pjsip.conf
  fi
  if [[ -f /etc/asterisk/extensions_magicptt_byon.conf ]]; then
    grep -qF 'extensions_magicptt_byon.conf' /etc/asterisk/extensions.conf 2>/dev/null \
      || echo '#include extensions_magicptt_byon.conf' >> /etc/asterisk/extensions.conf
  fi
  if [[ -f /etc/asterisk/manager_magicptt_byon.conf && -f /etc/asterisk/manager.conf ]]; then
    sed -i -E 's/^[[:space:]]*enabled[[:space:]]*=[[:space:]]*no/enabled = yes/I' \
      /etc/asterisk/manager.conf || true
    grep -qF 'manager_magicptt_byon.conf' /etc/asterisk/manager.conf \
      || echo '#include manager_magicptt_byon.conf' >> /etc/asterisk/manager.conf
  fi
}

full_reinstall_from_state() {
  [[ -f "$STATE_FILE" ]] || return 1
  # shellcheck disable=SC1090
  source "$STATE_FILE"
  local root="${INSTALL_ROOT:-}"
  [[ -n "$root" && -x "$root/install.sh" ]] || return 1
  [[ -n "${NODE:-}" && -n "${SIP_PASS:-}" ]] || return 1
  log "Full re-install from $root (node=$NODE)"
  local args=(
    --node "$NODE"
    --sip-user "${SIP_USER:-magicptt-byon}"
    --sip-password "$SIP_PASS"
    --lan "${LAN:-192.168.1.0/24}"
  )
  if [[ -n "${AMI_PASS:-}" ]]; then
    args+=(--ami-user "${AMI_USER:-magicptt-byon}" --ami-password "$AMI_PASS")
    [[ -n "${AMI_PERMIT:-}" ]] && args+=(--ami-permit "$AMI_PERMIT")
  fi
  bash "$root/install.sh" "${args[@]}" >>"$LOG" 2>&1
}

ensure_firewalld_ports() {
  # Idempotent — ASL3 appliance firewalld drops AMI/SIP until opened.
  local root=""
  if [[ -f "$STATE_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$STATE_FILE"
    root="${INSTALL_ROOT:-}"
  fi
  if [[ -n "$root" && -f "$root/scripts/05-open-firewalld-ports.sh" ]]; then
    bash "$root/scripts/05-open-firewalld-ports.sh" >>"$LOG" 2>&1 || true
  fi
}

main() {
  touch "$LOG" 2>/dev/null || true

  if [[ ! -d /etc/asterisk ]]; then
    log "SKIP: /etc/asterisk missing"
    exit 0
  fi

  ensure_firewalld_ports

  if [[ "$FORCE" != "1" ]] && theme_ok; then
    exit 0
  fi

  log "BYON markers missing or forced — restoring (force=$FORCE)"
  ensure_includes_only

  if theme_ok; then
    asterisk -rx 'module reload res_pjsip.so' >/dev/null 2>&1 || true
    asterisk -rx 'dialplan reload' >/dev/null 2>&1 || true
    asterisk -rx 'manager reload' >/dev/null 2>&1 || true
    log "OK: includes restored"
    exit 0
  fi

  if full_reinstall_from_state; then
    if theme_ok; then
      log "OK: full install restored BYON"
      exit 0
    fi
  fi

  log "ERROR: could not restore BYON — re-run sudo ./install.sh from BYON-ASL3 clone"
  exit 1
}

main "$@"
