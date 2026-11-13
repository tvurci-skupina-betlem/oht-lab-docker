# Spotizerr

[Spotizerr Phoenix](https://lavaforge.org/spotizerrphoenix/spotizerr-phoenix)
music downloader (Spotify metadata, Spotify/Deezer sources) deployed on
OHT-LAB via Komodo. Docs: <https://spotizerr-phoenix.readthedocs.io>.

## Deployment model

- Mode: Docker Compose, single instance
- Target: docker2
- Services: `spotizerr` (web UI + API), `spotizerr-redis` (task queue)
- Reverse proxy: Caddy (CT 104 on pve2)
- Public hostname: `spotizerr.betlem.cloud`
- Host port: `192.168.50.202:7171` (container port `7171`)
- App state: `${SPOTIZERR_DATA_ROOT}` on docker2 local disk
  (`/opt/appdata/spotizerr`)
- Music library: `${SPOTIZERR_DOWNLOADS_ROOT}` on CephFS
  (`/mnt/cephfs/appdata/spotizerr/downloads`)
- Redis: local named volume `spotizerr_redis-data` (disposable queue state)

## Storage

`/opt/appdata/spotizerr` holds:

- `data/`: configuration, Spotify/Deezer credentials, watch lists, history DB
- `logs/`: application logs
- `.cache`: a **file** (Spotify API token cache). If it does not exist,
  Docker creates a directory instead and the app fails.

`data/` contains account credentials, so treat it as sensitive.

Create the paths once on docker2 before the first deploy:

```sh
mkdir -p /opt/appdata/spotizerr/data /opt/appdata/spotizerr/logs \
  /mnt/cephfs/appdata/spotizerr/downloads
touch /opt/appdata/spotizerr/.cache
chown -R 1000:1000 /opt/appdata/spotizerr /mnt/cephfs/appdata/spotizerr
```

The container runs as `1000:1000` (`PUID`/`PGID`) with
`SKIP_SET_PERMISSIONS=true`, so ownership must be right on the host.

## Backups

Back up `/opt/appdata/spotizerr/data` (small). Downloads live on CephFS and
can be re-downloaded; copy them off-cluster only if the library matters.

## Accounts and login

`ENABLE_AUTH=true`, `DISABLE_REGISTRATION=true`. On first start the app
creates the admin `DEFAULT_ADMIN_USERNAME` with `DEFAULT_ADMIN_PASSWORD`
(Komodo secret `SPOTIZERR_ADMIN_PASSWORD`). Further users are created by the
admin in the UI.

Optional Google SSO: create an OAuth client with redirect URI
`https://spotizerr.betlem.cloud/api/auth/sso/callback`, add
`GOOGLE_CLIENT_ID`/`GOOGLE_CLIENT_SECRET` to the Komodo environment, set
`SSO_ENABLED=true` and redeploy.

## Spotify and Deezer accounts

Configured in the UI under Configuration → Accounts:

- Spotify: register with the `spotizerr-auth` helper on a machine where the
  Spotify desktop client is running, pointing it at
  `https://spotizerr.betlem.cloud`. It needs a Spotify API `client_id` and
  `client_secret` (developer.spotify.com).

  ```sh
  docker run --network=host --rm -it spotizerrphoenix/spotizerr-auth
  ```

- Deezer (optional, FLAC with Premium): paste the `arl` cookie from
  deezer.com.

## Reverse proxy

```caddyfile
spotizerr.betlem.cloud {
    reverse_proxy http://192.168.50.202:7171
}
```

If the hostname is published through Cloudflare Tunnel, also add it to the
split-horizon records on both Pi-holes (`dns.hosts`, the `97-` and `98-`
dnsmasq files), otherwise Firefox on the LAN fails with ECH errors.
