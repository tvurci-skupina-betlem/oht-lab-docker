# Forgejo

Self-hosted Git forge (community fork of Gitea, the software behind
Codeberg) deployed on OHT-LAB via Komodo.

## Deployment model

- Mode: Docker Compose, single instance
- Target: docker4 (CT 204 on pve4)
- Image: `codeberg.org/forgejo/forgejo:<version>-rootless` (runs as UID
  1000, built-in SSH server). Version line 15.x is LTS.
- Reverse proxy: Caddy (CT 104, HA)
- Public hostname: `git.betlem.cloud` (Cloudflare Tunnel → Caddy)
- Host ports: HTTP `192.168.50.204:3000`, SSH `192.168.50.204:2222`
- Persistent data: `${FORGEJO_DATA_ROOT}` on docker4 local disk
  (`/opt/appdata/forgejo`), mounted at `/var/lib/gitea`
- Backups: `${FORGEJO_BACKUP_ROOT}` on CephFS
  (`/mnt/cephfs/appdata/forgejo/backups`)

## Configuration

Every `FORGEJO__<section>__<KEY>` environment variable is written into
`app.ini` on start (`/opt/appdata/forgejo/custom/conf/app.ini`). The compose
file sets the fixed settings; Komodo provides the per-site values. Settings
changed by hand in `app.ini` are overwritten when they also exist as a
variable.

`SECRET_KEY`, `INTERNAL_TOKEN` and the JWT secrets are generated on the first
start and stay only in `app.ini`. Losing them breaks 2FA and stored
credentials, so `app.ini` is part of every backup.

Main choices:

- SQLite (WAL) on local disk. Enough for a small team; never on CephFS.
- Registration disabled; accounts are created by an admin. Public repos and
  profiles are readable without login, new repos default to private.
- OpenID sign-in disabled, `OFFLINE_MODE` (no Gravatar/CDN calls).
- Built-in Forgejo Actions is on by default but has no runner yet.

## Storage

```sh
# on docker4, done once before the first deploy
mkdir -p /opt/appdata/forgejo /mnt/cephfs/appdata/forgejo/backups
chown -R 1000:1000 /opt/appdata/forgejo /mnt/cephfs/appdata/forgejo
```

Layout inside `/opt/appdata/forgejo`: `data/forgejo.db` (database),
`git/repositories/` (bare repos), `git/lfs/`, `data/attachments/`,
`custom/conf/app.ini`, `ssh/` (SSH host keys).

## Backups

The `backup` sidecar (same image) runs [backup/backup.sh](backup/backup.sh):
on start and then daily at `BACKUP_HOUR` (UTC) it runs `forgejo dump` and writes
`forgejo-YYYYMMDD-HHMMSS.tar.gz` (mode 600) to `FORGEJO_BACKUP_ROOT`,
keeping `BACKUP_KEEP_DAYS` days. The archive holds the database as SQL,
repositories, LFS, attachments, avatars and `app.ini`.

CephFS is still inside the cluster. Copy archives off-cluster too (for
example SI-NAS1).

## Restore

Archive layout: `app.ini`, `forgejo-db.sql` (consistent SQL dump),
`data/` (the whole `/var/lib/gitea`, including a raw copy of the SQLite
file) and `repos/` (bare repositories, once some exist). Upstream guide:
<https://forgejo.org/docs/latest/admin/command-line/#dump>.

With the stack stopped in Komodo, on docker4 (needs `sqlite3` on the host):

```sh
cd /opt/appdata && mv forgejo forgejo.broken-$(date +%Y%m%d)
mkdir -p /tmp/fj-restore forgejo
tar -xzf /mnt/cephfs/appdata/forgejo/backups/forgejo-<stamp>.tar.gz -C /tmp/fj-restore
cp -a /tmp/fj-restore/data/. forgejo/
[ -d /tmp/fj-restore/repos ] && mkdir -p forgejo/git/repositories \
  && cp -a /tmp/fj-restore/repos/. forgejo/git/repositories/
# The raw SQLite copy may be mid-write; rebuild it from the SQL dump.
rm -f forgejo/data/forgejo.db*
sqlite3 forgejo/data/forgejo.db < /tmp/fj-restore/forgejo-db.sql
chown -R 1000:1000 forgejo && rm -rf /tmp/fj-restore
# start the stack, then:
docker exec forgejo forgejo admin regenerate hooks
```

## First admin

```sh
docker exec -it forgejo forgejo admin user create --admin \
  --username <name> --email <mail> --random-password --must-change-password
```

`admin` is a reserved name. Further users: Site Administration → User
Accounts → Create.

## Reverse proxy and public access

```caddyfile
git.betlem.cloud {
    reverse_proxy http://192.168.50.204:3000
}
```

Published as a Cloudflare Tunnel public hostname `git.betlem.cloud` →
`https://192.168.50.115` (Caddy), like the other public hosts. LAN clients
resolve it to Caddy through the local `betlem.cloud` zone; the Pi-hole
split-horizon entries (`dns.hosts`, `97-…`, `98-…`) are needed while Pi-hole
still answers.

Large pushes: Cloudflare limits a request body to 100 MB on the free plan,
so a big first push or large LFS objects fail over the public hostname.
Push those over SSH on the LAN instead.

## SSH

Cloudflare Tunnel and Caddy carry only HTTPS, so Git over SSH works only on
the LAN and tailnet, directly to docker4:

```sh
git clone ssh://git@192.168.50.204:2222/<owner>/<repo>.git
```

Clone URLs in the UI show `FORGEJO_SSH_DOMAIN:FORGEJO_SSH_PORT`.

## Healthcheck

`/api/healthz` (container healthcheck and Uptime Kuma:
`https://git.betlem.cloud/api/healthz`).

## Upgrades

Bump `FORGEJO_IMAGE_TAG` in `komodo/resources/stacks.compose.toml`. Patch
releases within 15.x are drop-in. Before a major upgrade read the release
notes and make sure a fresh backup exists; downgrades are not supported.
