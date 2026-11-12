# Vaultwarden

Self-hosted Bitwarden-compatible password manager deployed on OHT-LAB via
Komodo.

## Deployment model

- Mode: Docker Compose, single instance (not HA, see below)
- Target: docker3
- Reverse proxy: Caddy (CT 104 on pve2)
- Public hostname: `vault.betlem.cloud`
- Host port: `192.168.50.203:8081` (container port `8080`)
- Persistent data: `${VAULTWARDEN_DATA_ROOT}/data` on docker3
  (`/opt/appdata/vaultwarden/data`)
- Backups: `${VAULTWARDEN_BACKUP_ROOT}` on CephFS
  (`/mnt/cephfs/appdata/vaultwarden/backups`)

## Why single instance

Vaultwarden is designed to run as one process. Multiple replicas are not
supported (WebSocket live sync is per process), and SQLite on CephFS has
locking problems. Bitwarden clients keep an encrypted offline copy of the
vault, so a short outage only blocks edits and new logins. Recovery is a
redeploy from backup on another node.

Do not rely on this vault alone for lab break-glass credentials (Proxmox
root, Ceph, router, NAS, Cloudflare). It runs on the cluster those
credentials recover. Keep an offline encrypted export and a paper copy.

## Storage

State lives on docker3's local disk, outside the Komodo Git checkout:

- `db.sqlite3` (+ `-wal`, `-shm`): the vault database
- `rsa_key.pem`: JWT signing key (older installs also have `rsa_key.pub.pem`)
- `attachments/`, `sends/`: uploaded files
- `config.json`: settings saved from `/admin` (if enabled)
- `icon_cache/`: disposable

Create the directory once on docker3 before the first deploy:

```sh
mkdir -p /opt/appdata/vaultwarden/data /mnt/cephfs/appdata/vaultwarden/backups
chown -R 1000:1000 /opt/appdata/vaultwarden /mnt/cephfs/appdata/vaultwarden
```

## Backups

The `backup` sidecar runs [backup/backup.sh](backup/backup.sh). On start and
then daily at `BACKUP_HOUR` it writes
`vaultwarden-YYYYMMDD-HHMMSS.tar.gz` to `VAULTWARDEN_BACKUP_ROOT`, keeping
`BACKUP_KEEP_DAYS` days. Each archive holds a consistent SQLite copy made
with the online backup API (integrity-checked), the RSA keys, attachments,
sends and `config.json`.

Vault items are encrypted with each user's master password, but the RSA key
and `config.json` are sensitive. Archives are mode `600`.

CephFS is still inside the cluster. Copy archives off-cluster too (for
example SI-NAS1), so a full lab loss can be recovered on any Docker host.

## Restore

The restore must include `rsa_key*`. If clients connect to a Vaultwarden
that rejects their tokens (empty or wrong database, different RSA key), they
log out and wipe their offline copy. Verify a restored instance from one
device before letting the rest sync.

```sh
# on docker3, with the stack stopped in Komodo
cd /opt/appdata/vaultwarden
mv data data.broken-$(date +%Y%m%d)
mkdir data
tar -xzf /mnt/cephfs/appdata/vaultwarden/backups/vaultwarden-<stamp>.tar.gz -C data
chown -R 1000:1000 data
# start the stack in Komodo
```

To move to another node, restore into that node's
`/opt/appdata/vaultwarden`, change `server` and `VAULTWARDEN_BIND_IP` in
`komodo/resources/stacks.compose.toml`, and point Caddy at the new IP.

## First account

Signups are off. To create the first account:

1. In Komodo, set `SIGNUPS_ALLOWED=true` and redeploy.
2. Register at `https://vault.betlem.cloud`.
3. Set `SIGNUPS_ALLOWED=false` and redeploy.

Further users: enable `/admin` temporarily and send invitations, or repeat
the steps above. Invited users get an email with a registration link.

## Admin panel

`ADMIN_TOKEN` is not set, so `/admin` is disabled. To enable it, generate an
Argon2 hash with `docker exec -it vaultwarden /vaultwarden hash`, add it to
the Komodo environment as `ADMIN_TOKEN` (single-quoted), and redeploy. Remove
the line again when done.

Optional settings (`ADMIN_TOKEN`, `SMTP_*`, `PUSH_*`) reach the container
through `env_file: .env` only when defined. Never leave them empty: an empty
`SMTP_HOST=` makes Vaultwarden refuse to start.
Settings saved in `/admin` go to `config.json` and override the environment.

## Email (SMTP)

Vaultwarden sends mail through smtp2go (`mail-eu.smtp2go.com:2525`,
STARTTLS) as `info@betlem.cloud`, with the same smtp2go login as NetBox
(Komodo variables `NETBOX_EMAIL_USERNAME` and `NETBOX_EMAIL_PASSWORD`).

Mail is used for organization and `/admin` invitations, email
verification, new device login notices and email-based two-step login.
To test, open Account settings in the web vault and send the email
verification message.

## Client settings

On every browser extension, desktop and mobile client set
**Vault timeout action = Lock**, not *Log out*. *Log out* deletes the
offline copy each time the vault times out.

## Reverse proxy

WebSocket notifications use the same port since Vaultwarden 1.29, so a plain
`reverse_proxy` is enough. Caddy sends `X-Real-IP`, which Vaultwarden reads
via `IP_HEADER`.

```caddyfile
vault.betlem.cloud {
    reverse_proxy http://192.168.50.203:8081 {
        header_up X-Real-IP {client_ip}
    }
}
```

For requests arriving through Cloudflare Tunnel, `{client_ip}` is the
cloudflared connector's IP unless Caddy's global `servers` block lists the
connectors in `trusted_proxies` and reads `CF-Connecting-IP` via
`client_ip_headers`. Login rate limiting and logs then see the real client.

If the hostname is published through Cloudflare Tunnel, do not put
Cloudflare Access in front of the whole site (mobile and desktop apps cannot
pass it). Protect only `/admin`, or keep it disabled.

## Healthcheck

The image has a built-in healthcheck (`/healthcheck.sh`) that respects
`ROCKET_PORT`. HTTP check for Uptime Kuma: `https://vault.betlem.cloud/alive`.
