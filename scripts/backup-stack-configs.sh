#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
BACKUP_DIR="${BACKUP_DIR:-${ROOT_DIR}/backups/stack-configs}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
TARGET="${BACKUP_DIR}/stack-configs-${STAMP}.tar.gz"

mkdir -p "${BACKUP_DIR}"

tar \
  --exclude='*/.env' \
  --exclude='*/.env.*' \
  --exclude='*.log' \
  -czf "${TARGET}" \
  -C "${ROOT_DIR}" \
  stacks komodo docs README.md SECURITY.md .env.example

echo "${TARGET}"
