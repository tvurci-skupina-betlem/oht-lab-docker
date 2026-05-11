# Backup And Restore

Backups should cover both deployment intent and runtime state.

## Back Up

- Komodo Core database and configuration.
- Stack `.env` files stored outside Git.
- Docker named volumes with application data.
- CephFS appdata under `/mnt/cephfs/appdata/<stack-name>/`.
- Reverse proxy and tunnel configuration.
- Any Ceph-backed data used by services.

## Restore Order

1. Restore host or LXC.
2. Restore Docker and networking prerequisites.
3. Restore Komodo Core.
4. Restore stack secrets and `.env` files.
5. Restore application volumes.
6. Redeploy through Komodo.
