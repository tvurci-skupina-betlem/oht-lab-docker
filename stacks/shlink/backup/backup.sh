#!/bin/sh
# Nightly Shlink database backup sidecar.
#
# Writes a pg_dump custom-format archive (short URLs, visits, API keys,
# domains) to /backups. That directory is on the CT 205 rootfs, which the
# nightly Proxmox vzdump job copies off the cluster.
set -u

BACKUP_HOUR="${BACKUP_HOUR:-03}"
BACKUP_KEEP_DAYS="${BACKUP_KEEP_DAYS:-14}"

log() { echo "$(date -Iseconds) $*"; }

run_backup() {
  stamp="$(date +%Y%m%d-%H%M%S)"
  out="/backups/shlink-${stamp}.dump"
  part="/backups/.partial-shlink-${stamp}.dump"

  if ! pg_dump --format=custom --no-owner --file="${part}"; then
    rm -f "${part}"; return 1
  fi
  chmod 600 "${part}" && mv "${part}" "${out}" || return 1

  find /backups -name 'shlink-*.dump' -mtime "+${BACKUP_KEEP_DAYS}" -delete
  log "backup ok: ${out}"
}

backup_or_warn() {
  run_backup || log "backup FAILED" >&2
}

# One backup shortly after start so a fresh deploy is covered immediately.
sleep 120
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
