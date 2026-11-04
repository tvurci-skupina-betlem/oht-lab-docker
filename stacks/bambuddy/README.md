# Bambuddy

Self-hosted control plane for Bambu Lab 3D printers (monitoring, print queue,
archive, slicing) deployed on OHT-LAB via Komodo. It talks to printers
directly over the LAN, without the Bambu cloud.

- Website: <https://bambuddy.cool/>
- Source: <https://github.com/maziggy/bambuddy>
- Wiki: <http://wiki.bambuddy.cool>

## Deployment model

- Mode: Docker Compose, bridge networking
- Target: docker2
- Reverse proxy: Caddy
- Hostname: `bambuddy.betlem.cloud` (private, local DNS only)
- Internal container port: `8000`
- Host bind: `${BAMBUDDY_BIND_IP:-127.0.0.1}:${BAMBUDDY_PORT:-8000}`
- Image: `ghcr.io/maziggy/bambuddy`, pinned via `BAMBUDDY_IMAGE_TAG`

## Storage

- `/app/data`: local named volume `bambuddy-data` (SQLite DB, app state)
- `/app/logs`: local named volume `bambuddy-logs`
- `/app/data/backups`: `/mnt/cephfs/appdata/bambuddy/backups` (scheduled
  backups)

The database is intentionally on a local volume: SQLite on CephFS caused
locking problems for Uptime Kuma. The stack is therefore tied to docker2.
Enable scheduled backups in Settings so a copy lands on CephFS; to move the
stack to another node, restore from that backup.

## Networking decisions

Upstream recommends `network_mode: host` for SSDP printer discovery and for
the virtual printer feature. On docker2 that would collide with ports already
used by other stacks (for example `3000` used by TREK), so this stack runs in
bridge mode and publishes only the web UI.

Consequences:

- Printers must be added manually by IP address, serial number and LAN
  access code (printer screen -> Settings -> LAN only / access code).
- Give each printer a DHCP reservation so its IP does not change.
- The virtual printer feature (sending from Bambu Studio / OrcaSlicer to
  Bambuddy as if it were a printer) is disabled. Enabling it later requires
  publishing `322`, `990`, `3000`, `3002`, `6000`, `8883`, `2024-2026` and
  a passive FTP range, plus `VIRTUAL_PRINTER_PASV_ADDRESS` and
  `VIRTUAL_PRINTER_ADVERTISE_ADDRESS` set to the docker2 IP. A dedicated
  node or macvlan network is the cleaner option for that.

## First boot

1. Deploy the stack from Komodo.
2. Open the UI and create the admin account on the first-run screen.
3. Add printers by IP.
4. Settings -> Backup: enable scheduled backups.

## Healthcheck

The upstream image ships its own Docker `HEALTHCHECK`.

## Reverse proxy notes

Bambuddy uses WebSockets for live printer status and camera streams. Caddy
handles them with a plain `reverse_proxy` directive:

```caddyfile
bambuddy.betlem.cloud {
  reverse_proxy 192.168.50.202:8000
}
```

## Updating

Bump `BAMBUDDY_IMAGE_TAG` in `komodo/resources/stacks.compose.toml` via pull
request. Read the upstream `UPDATING.md` and release notes first. Do not use
the in-app updater; it does not apply to Komodo-managed containers.
