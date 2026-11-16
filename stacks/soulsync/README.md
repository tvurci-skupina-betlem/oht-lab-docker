# SoulSync

[SoulSync](https://github.com/Nezreka/SoulSync) (<https://ssync.net>, MIT)
music and video automation: playlist sync and discovery (Spotify, Tidal,
Deezer, Last.fm, ...), downloads from Soulseek (via slskd), Tidal, Qobuz,
Deezer and YouTube, AcoustID verification, tagging and library organisation.
Works standalone or with Plex, Jellyfin or Navidrome. Deployed on OHT-LAB
via Komodo.

## Deployment model

- Mode: Docker Compose, single instance
- Target: docker2
- Services: `soulsync` (gunicorn web UI + API, SQLite inside)
- Image: `boulderbadgedad/soulsync`, pinned by `SOULSYNC_IMAGE_TAG`
- Reverse proxy: Caddy (CT 104 on pve2)
- Hostname: `soulsync.betlem.cloud` (private, local DNS only)
- Host port: `192.168.50.202:8008` (container port `8008`)
- App state: `${SOULSYNC_DATA_ROOT}` on docker2 local disk
  (`/opt/appdata/soulsync`)
- Media: `${SOULSYNC_MEDIA_ROOT}` on CephFS (`/mnt/cephfs/appdata/soulsync`)
- Resource limit: 2 CPU / 2 GiB (upstream default)

## Storage

`DATA` = `/opt/appdata/soulsync`, `MEDIA` = `/mnt/cephfs/appdata/soulsync`.

| Host path            | Container path     | Purpose                      |
| -------------------- | ------------------ | ---------------------------- |
| `DATA/config`        | `/app/config`      | config.json, credentials     |
| `DATA/data`          | `/app/data`        | SQLite databases             |
| `DATA/logs`          | `/app/logs`        | application logs             |
| `DATA/scripts`       | `/app/scripts`     | user post-processing scripts |
| `MEDIA/downloads`    | `/app/downloads`   | download client input        |
| `MEDIA/staging`      | `/app/Staging`     | import staging               |
| `MEDIA/music`        | `/app/Transfer`    | finished music library       |
| `MEDIA/music-videos` | `/app/MusicVideos` | music videos                 |

`config/` holds account credentials and API keys, so treat it as sensitive.

Create the paths once on docker2 before the first deploy (run inside CT 202:
`ssh claude-pve2`, then `sudo pct exec 202 -- sh`):

```sh
mkdir -p /opt/appdata/soulsync/config /opt/appdata/soulsync/data \
  /opt/appdata/soulsync/logs /opt/appdata/soulsync/scripts \
  /mnt/cephfs/appdata/soulsync/downloads /mnt/cephfs/appdata/soulsync/staging \
  /mnt/cephfs/appdata/soulsync/music /mnt/cephfs/appdata/soulsync/music-videos
chown -R 1000:1000 /opt/appdata/soulsync /mnt/cephfs/appdata/soulsync
```

The entrypoint starts as root, remaps its `soulsync` user to `PUID`/`PGID`
and drops privileges with `gosu`. It warns in the log if a mount is not
writable. Check `findmnt /mnt/cephfs/appdata` first if the library looks empty.

The video side (movies, TV, YouTube) is not mounted. To use it, add mounts
such as `.../movies:/media/movies`, `.../tv:/media/tv` and
`.../youtube:/media/youtube`.

## First run and login

SoulSync has no env-based admin bootstrap: open the UI and finish the setup
wizard, which sets the admin PIN or username/password. **Do this before the
hostname is reachable from outside the LAN.** Sign-in can also use Plex, OIDC
or forward-auth headers (Authelia/Authentik/oauth2-proxy), see upstream
`docs/guides/OIDC.md`.

In Settings → Downloads set the Transfer path to `/app/Transfer`.

## Service accounts

Configured in the UI; nothing goes into Komodo:

- Spotify: create an app at developer.spotify.com with redirect URI
  `https://soulsync.betlem.cloud/callback` and set the same URI in SoulSync.
- Tidal: redirect URI `https://soulsync.betlem.cloud/tidal/callback`.
- Soulseek: needs a separate slskd instance (not part of this stack). Point
  slskd's download directory at the same CephFS `downloads/` path and enter
  its URL and API key in SoulSync.
- Plex/Jellyfin/Navidrome: point the media server at the `music/` library.

The OAuth redirects are resolved by the browser, so private (LAN-only) DNS is
enough. The standalone callback ports 8888/8889 are not published.

## Backups

Back up `/opt/appdata/soulsync/config` and `/opt/appdata/soulsync/data`
(stop the container or copy the SQLite files with `sqlite3 .backup`). The
library on CephFS can be rebuilt by re-downloading; copy it off-cluster only if
it matters.

## Upgrades

Releases are frequent. Bump `SOULSYNC_IMAGE_TAG` in Komodo after checking the
[release notes](https://github.com/Nezreka/SoulSync/releases). Startup can run
DB migrations; `/api/startup-status` stays healthy meanwhile, so do not
restart the container mid-upgrade.

## Reverse proxy

```caddyfile
soulsync.betlem.cloud {
    reverse_proxy http://192.168.50.202:8008
}
```

Caddy forwards Socket.IO websocket upgrades by default. If the hostname is
ever published through Cloudflare Tunnel, also add it to the split-horizon
records on both Pi-holes (`dns.hosts`, the `97-` and `98-` dnsmasq files).

## Validation

```sh
docker compose --env-file .env.example -f compose.yml config
```
