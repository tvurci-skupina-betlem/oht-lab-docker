#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
STACK_DIR="${ROOT_DIR}/stacks"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required for compose validation" >&2
  exit 127
fi

found=0

for compose_file in "${STACK_DIR}"/*/compose.yml; do
  [ -f "${compose_file}" ] || continue
  found=1
  stack_path="$(dirname "${compose_file}")"
  stack_name="$(basename "${stack_path}")"
  env_file="${stack_path}/.env.example"

  echo "Validating ${stack_name}"

  if [ -f "${env_file}" ]; then
    docker compose --env-file "${env_file}" -f "${compose_file}" config >/dev/null
  else
    docker compose -f "${compose_file}" config >/dev/null
  fi

  swarm_file="${stack_path}/compose.swarm.yml"
  if [ -f "${swarm_file}" ]; then
    if [ -f "${env_file}" ]; then
      docker compose --env-file "${env_file}" -f "${compose_file}" -f "${swarm_file}" config >/dev/null
    else
      docker compose -f "${compose_file}" -f "${swarm_file}" config >/dev/null
    fi
  fi
done

if [ "${found}" -eq 0 ]; then
  echo "No compose.yml files found under ${STACK_DIR}" >&2
  exit 1
fi
