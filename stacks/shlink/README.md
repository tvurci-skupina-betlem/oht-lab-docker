# Shlink

Self-hosted URL shortener with visit statistics and a REST API, deployed on
OHT-LAB via Komodo. Short links use `hlav.ac`.

## Deployment model

- Mode: Docker Compose, single instance
- Target: `docker-ha1` (CT 205). Its rootfs is a Ceph RBD disk and the CT is
  a Proxmox HA resource in the `Default` node-affinity rule (pve1-3), so if a
  node dies the whole CT, database included, restarts on another node in
  about 1-2 minutes.
- Images: `shlinkio/shlink`, `shlinkio/shlink-web-client`, `postgres`
  (versions pinned in Komodo)
- Reverse proxy: Caddy (CT 104, HA)
- Hostnames:
  - `hlav.ac`: short links, public (Cloudflare Tunnel → Caddy → `192.168.50.205:8080`)
  - `shlink.betlem.cloud`: admin web client, private (LAN/tailnet only)
    → `192.168.50.205:8081`
- Persistent data: `${SHLINK_DATA_ROOT}` (`/opt/appdata/shlink`) on the CT
  rootfs: `postgres/` (database) and `backups/` (pg_dump archives)

## Why this layout

Shlink keeps all state in its database, so the database decides how
available Shlink is. Postgres sits on a block device (RBD) that moves with
the CT, which is the only automatic failover in the cluster that needs no
database clustering. CephFS is avoided for Postgres on purpose: it is slower
for fsync-heavy writes, and a stale container on another node could open the
same data directory and corrupt it.

Several Shlink containers on different nodes would also need Redis for
shared locks (`REDIS_SERVERS`) and a replicated database. Not worth it while
Caddy itself is a single HA CT.

## Configuration

Komodo provides all values; secrets are Komodo variables:

| Variable                      | Purpose                                         |
| ----------------------------- | ----------------------------------------------- |
| `SHLINK_POSTGRES_PASSWORD`    | Database password                               |
| `SHLINK_INITIAL_API_KEY`      | Admin API key, created on the first start only  |
| `SHLINK_GEOLITE_LICENSE_KEY`  | MaxMind key for visit geolocation (may be empty) |

`INITIAL_API_KEY` is ignored once any API key exists. Further keys:
`docker exec shlink shlink api-key:generate`.

`TRUSTED_PROXIES=2` covers cloudflared and Caddy in front of Shlink.
Visitor IPs are anonymized (`ANONYMIZE_REMOTE_ADDR`).

## Admin UI

Open `https://shlink.betlem.cloud`, add a server with URL `https://hlav.ac`
and the API key from the Komodo variable `SHLINK_INITIAL_API_KEY`. The key
stays in that browser's local storage. The web client deliberately has no
preconfigured server: it would hand the key to anyone who opens the page.

The hosted <https://app.shlink.io> works the same way.

## Backups

- The `backup` sidecar runs [backup/backup.sh](backup/backup.sh) on start and
  daily at `BACKUP_HOUR`: `pg_dump --format=custom` into
  `/opt/appdata/shlink/backups/shlink-YYYYMMDD-HHMMSS.dump` (mode 600),
  keeping `BACKUP_KEEP_DAYS` days.
- The nightly Proxmox vzdump job (all guests, 03:00) copies the whole CT,
  including those archives, to `oht-nas1-backups`.

## Restore

With the stack running (empty or broken database), on docker-ha1:

```sh
docker exec -i shlink-postgres sh -c \
  'pg_restore --clean --if-exists --no-owner -U "$POSTGRES_USER" -d "$POSTGRES_DB"' \
  < /opt/appdata/shlink/backups/shlink-<stamp>.dump
docker restart shlink
```

Whole-CT restore: restore CT 205 from vzdump in Proxmox (storage
`oht-lab-pool01`), then `ha-manager add ct:205` again if it was removed.

## Importing from Bitly

`hlav.ac` was a Bitly custom domain. To keep existing links working, import
them before moving DNS (needs a Bitly access token):

```sh
docker exec -it shlink shlink short-url:import bitly
```

Answer yes to keeping short codes and to importing custom domains.

## Operations

```sh
# where is the CT running
ssh claude-pve1 'sudo ha-manager status | grep ct:205'
# node reboot: HA moves CT 205 like Caddy (node-maintenance)
docker exec shlink shlink short-url:list
docker exec shlink shlink visit:locate   # after adding a GeoLite key
```
