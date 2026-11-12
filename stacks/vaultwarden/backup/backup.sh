#!/bin/sh
# Nightly Vaultwarden backup sidecar.
#
# Makes a consistent SQLite copy with the online backup API (safe while
# Vaultwarden runs) and archives it together with the rest of /data:
# attachments, sends, rsa_key* (JWT signing key) and config.json.
# Without rsa_key* a restore logs every client out and wipes its offline copy.
set -u

BACKUP_HOUR="${BACKUP_HOUR:-03}"
BACKUP_KEEP_DAYS="${BACKUP_KEEP_DAYS:-30}"
BACKUP_UID="${BACKUP_UID:-1000}"
BACKUP_GID="${BACKUP_GID:-1000}"

log() { echo "$(date -Iseconds) $*"; }

# Install tools as root, then re-run as the data owner so no root-owned
# -wal/-shm or archive files ever land next to Vaultwarden's data.
if [ "$(id -u)" = "0" ]; then
  apk add --no-cache sqlite tzdata su-exec >/dev/null || { log "apk add failed"; exit 1; }
  exec su-exec "${BACKUP_UID}:${BACKUP_GID}" /bin/sh "$0" "$@"
fi

run_backup() {
  # Never create the database: Vaultwarden must be the first to open it.
  if [ ! -s /data/db.sqlite3 ]; then
    log "no database yet, skipping"; return 0
  fi
  stamp="$(date +%Y%m%d-%H%M%S)"
  work="$(mktemp -d)" || return 1
  out="/backups/vaultwarden-${stamp}.tar.gz"

  if ! sqlite3 'file:/data/db.sqlite3?mode=ro' ".backup '${work}/db.sqlite3'"; then
    rm -rf "${work}"; return 1
  fi
  if [ "$(sqlite3 "${work}/db.sqlite3" 'PRAGMA integrity_check;')" != "ok" ]; then
    rm -rf "${work}"; return 1
  fi

  for item in attachments sends rsa_key.pem rsa_key.pub.pem config.json; do
    if [ -e "/data/${item}" ]; then
      cp -a "/data/${item}" "${work}/" || { rm -rf "${work}"; return 1; }
    fi
  done

  if ! tar -czf "${out}.tmp" -C "${work}" .; then
    rm -rf "${work}" "${out}.tmp"; return 1
  fi
  rm -rf "${work}"
  chmod 600 "${out}.tmp" && mv "${out}.tmp" "${out}" || return 1

  find /backups -name 'vaultwarden-*.tar.gz' -mtime "+${BACKUP_KEEP_DAYS}" -delete
  log "backup ok: ${out}"
}

backup_or_warn() {
  run_backup || log "backup FAILED" >&2
}

# One backup shortly after start so a fresh deploy is covered immediately.
sleep 60
backup_or_warn
last_day=""

while true; do
  sleep 60
  today="$(date +%F)"
  if [ "$(date +%H)" = "${BACKUP_HOUR}" ] && [ "${today}" != "${last_day}" ]; then
    backup_or_warn
    last_day="${today}"
  fi
done
