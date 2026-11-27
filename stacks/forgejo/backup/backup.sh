#!/bin/sh
# Nightly Forgejo backup sidecar.
#
# Runs `forgejo dump` (database as SQL, repositories, LFS, attachments,
# avatars, app.ini) into a tar.gz on CephFS. app.ini holds SECRET_KEY and
# INTERNAL_TOKEN, without which 2FA secrets and stored credentials are lost,
# so archives are mode 600.
set -u

# The image has no zoneinfo for busybox date: BACKUP_HOUR is in UTC.
BACKUP_HOUR="${BACKUP_HOUR:-03}"
BACKUP_KEEP_DAYS="${BACKUP_KEEP_DAYS:-14}"

log() { echo "$(date -Iseconds) $*"; }

run_backup() {
  if [ ! -s /var/lib/gitea/data/forgejo.db ]; then
    log "no database yet, skipping"; return 0
  fi
  stamp="$(date +%Y%m%d-%H%M%S)"
  out="/backups/forgejo-${stamp}.tar.gz"
  # dump appends .tar.gz unless the name already ends with it.
  part="/backups/.partial-forgejo-${stamp}.tar.gz"
  work="$(mktemp -d /tmp/forgejo-dump.XXXXXX)" || return 1

  # Forgejo creates this only with the first repository; dump fails without it.
  mkdir -p /var/lib/gitea/git/repositories

  if ! forgejo dump --config /var/lib/gitea/custom/conf/app.ini --tempdir "${work}" \
      --type tar.gz --file "${part}" --quiet; then
    rm -rf "${work}" "${part}"; return 1
  fi
  rm -rf "${work}"
  chmod 600 "${part}" && mv "${part}" "${out}" || return 1

  find /backups -name 'forgejo-*.tar.gz' -mtime "+${BACKUP_KEEP_DAYS}" -delete
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
