#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

for compose_file in "${ROOT_DIR}/stacks"/*/compose.yml; do
  [ -f "${compose_file}" ] || continue
  dirname "${compose_file}" | xargs basename
done
