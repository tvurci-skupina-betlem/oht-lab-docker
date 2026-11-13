#!/usr/bin/env bash
# Fast edit loop for the dashboard configs (Homepage, Glance, Dynacat).
#
# The dashboards-dev stack on docker3 runs homepage-dev, glance-dev and
# dynacat-dev. They read their config from /opt/dashdev/<app> instead of the
# Git checkout. This script copies your working-tree YAML there; the apps
# pick changes up on the next page load, without a restart or a commit.
#
#   https://homepage-dev.betlem.cloud   <- stacks/homepage/config
#   https://glance-dev.betlem.cloud     <- stacks/glance/config
#   https://dynacat-dev.betlem.cloud    <- stacks/dynacat/config (+ glance pages)
#
# Usage: scripts/dash-dev.sh <command> [app...]   (app: homepage|glance|dynacat, default all)
#   push     copy the repo config to the dev instance
#   watch    push, then keep pushing every file you save (Ctrl+C to stop)
#   pull     copy dev-instance edits (e.g. the Dynacat UI editor) back into the repo;
#            only files already in the repo unless --new is given
#   diff     show what differs between the repo and the dev instance
#   restart  restart the dev container (needed after env/compose changes only)
#   logs     tail the dev container log
#
# Access: by default through the Proxmox host that runs docker3 (CT 203):
#   DASH_DEV_SSH=claude-pve3  DASH_DEV_CT=203
# For direct SSH into docker3 set DASH_DEV_SSH=<user@docker3> DASH_DEV_CT=
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
SSH_TARGET="${DASH_DEV_SSH:-claude-pve3}"
CT_ID="${DASH_DEV_CT-203}"
REMOTE_ROOT="${DASH_DEV_ROOT:-/opt/dashdev}"
POLL_SECONDS="${DASH_DEV_POLL:-1}"
ALL_APPS="homepage glance dynacat"

die() { echo "dash-dev: $*" >&2; exit 1; }

# Run a shell script (read from stdin) on docker3 as root.
remote() {
  if [ -n "${CT_ID}" ]; then
    ssh -o BatchMode=yes "${SSH_TARGET}" "sudo pct exec ${CT_ID} -- sh -s"
  else
    ssh -o BatchMode=yes "${SSH_TARGET}" "sudo sh -s"
  fi
}

local_dir() { echo "${ROOT_DIR}/stacks/$1/config"; }

# Config files we manage: YAML plus custom CSS/JS, no logs.
list_files() {
  (cd "$(local_dir "$1")" && find . -type f \( -name '*.yml' -o -name '*.yaml' -o -name '*.css' -o -name '*.js' \) \
    -not -path './logs/*' | sed 's|^\./||' | sort)
}

# Push the given files of one app in a single SSH round trip. Files are written
# in place (`>` truncates, same inode) so the apps' file watchers keep working.
push_files() {
  local app="$1"; shift
  [ "$#" -gt 0 ] || return 0
  local dir; dir="$(local_dir "$app")"
  {
    echo "set -e"
    for f in "$@"; do
      local dest="${REMOTE_ROOT}/${app}/${f}"
      echo "mkdir -p '$(dirname "${dest}")'"
      echo "base64 -d > '${dest}' <<'__DASHDEV_EOF__'"
      base64 < "${dir}/${f}"
      echo "__DASHDEV_EOF__"
    done
  } | remote
  printf '%s  pushed %s: %s\n' "$(date +%H:%M:%S)" "${app}" "$*"
}

cmd_push() {
  local app
  for app in "$@"; do
    # shellcheck disable=SC2046
    push_files "${app}" $(list_files "${app}")
  done
}

snapshot() {
  local app
  for app in "$@"; do
    (cd "$(local_dir "${app}")" && list_files "${app}" | while read -r f; do
      printf '%s %s %s\n' "${app}" "$(md5sum < "$f" | cut -c1-32)" "$f"
    done)
  done
}

cmd_watch() {
  cmd_push "$@"
  echo "watching $* (every ${POLL_SECONDS}s, Ctrl+C to stop)"
  local before after app changed
  before="$(snapshot "$@")"
  while sleep "${POLL_SECONDS}"; do
    after="$(snapshot "$@")"
    [ "${before}" = "${after}" ] && continue
    for app in "$@"; do
      changed="$(diff <(echo "${before}" | grep "^${app} ") <(echo "${after}" | grep "^${app} ") \
        | sed -n 's/^> [^ ]* [^ ]* //p' || true)"
      # shellcheck disable=SC2086
      [ -n "${changed}" ] && push_files "${app}" ${changed}
    done
    before="${after}"
  done
}

cmd_pull() {
  local new=0 app
  if [ "${1:-}" = "--new" ]; then new=1; shift; fi
  for app in "$@"; do
    local dir tmp; dir="$(local_dir "${app}")"; tmp="$(mktemp -d)"
    echo "cd '${REMOTE_ROOT}/${app}' && tar cf - --exclude=./logs ." | remote | tar xf - -C "${tmp}"
    (cd "${tmp}" && find . -type f \( -name '*.yml' -o -name '*.yaml' -o -name '*.css' -o -name '*.js' \) \
      -not -path './logs/*' | sed 's|^\./||') | while read -r f; do
      if [ -f "${dir}/${f}" ] || [ "${new}" = 1 ]; then
        if ! cmp -s "${tmp}/${f}" "${dir}/${f}" 2>/dev/null; then
          mkdir -p "$(dirname "${dir}/${f}")"; cp "${tmp}/${f}" "${dir}/${f}"; echo "pulled ${app}/${f}"
        fi
      else
        echo "skipped new ${app}/${f} (use pull --new to take it)"
      fi
    done
    rm -rf "${tmp}"
  done
  (cd "${ROOT_DIR}" && git status --short -- stacks)
}

cmd_diff() {
  local app
  for app in "$@"; do
    local dir tmp; dir="$(local_dir "${app}")"; tmp="$(mktemp -d)"
    echo "cd '${REMOTE_ROOT}/${app}' && tar cf - --exclude=./logs ." | remote | tar xf - -C "${tmp}"
    diff -ru --exclude=logs "${dir}" "${tmp}" | sed "s|${tmp}|dev:${app}|" || true
    rm -rf "${tmp}"
  done
}

cmd_restart() { local a; for a in "$@"; do echo "docker restart ${a}-dev" | remote; done; }
cmd_logs() { local a; for a in "$@"; do echo "== ${a}-dev"; echo "docker logs --tail 40 ${a}-dev 2>&1" | remote; done; }

command="${1:-}"; [ -n "${command}" ] || { sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
shift
pull_flag=""
if [ "${command}" = "pull" ] && [ "${1:-}" = "--new" ]; then pull_flag="--new"; shift; fi
apps="${*:-${ALL_APPS}}"
for a in ${apps}; do
  case " ${ALL_APPS} " in *" ${a} "*) ;; *) die "unknown app '${a}' (expected: ${ALL_APPS})";; esac
done
# shellcheck disable=SC2086
case "${command}" in
  push) cmd_push ${apps} ;;
  watch) cmd_watch ${apps} ;;
  pull) cmd_pull ${pull_flag} ${apps} ;;
  diff) cmd_diff ${apps} ;;
  restart) cmd_restart ${apps} ;;
  logs) cmd_logs ${apps} ;;
  *) die "unknown command '${command}'" ;;
esac
