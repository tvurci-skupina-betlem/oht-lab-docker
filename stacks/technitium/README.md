# Technitium DNS

Recursive DNS resolver with ad blocking and the local `betlem.cloud` split
horizon. Meant to replace the two Pi-hole LXCs, so DNS keeps working when the
Proxmox cluster or Ceph is down.

## Deployment model

- Mode: Docker Compose, `network_mode: host`
- Primary: Komodo stack `technitium` on docker5 (oht-lab5, Raspberry Pi,
  outside the Proxmox cluster), `192.168.50.105`
- Secondary: planned on one of the Proxmox Docker nodes, same `compose.yml`
  with its own Komodo stack and environment (`TECHNITIUM_HOSTNAME`,
  `TECHNITIUM_WEB_ADDRESSES`)
- DNS: UDP/TCP 53 on every host address (LAN and tailnet)
- Web console: `http://192.168.50.105:5380`, bound only to the addresses in
  `TECHNITIUM_WEB_ADDRESSES` (LAN IP and `127.0.0.1` for the healthcheck)
- Data: `/opt/appdata/technitium` on local disk, mounted at `/etc/dns`
  (config, zones, dashboard stats, server log). Never on CephFS.
- Admin user `admin`, password from Komodo secret `TECHNITIUM_ADMIN_PASSWORD`.
  It is applied on the first start only; later changes are made in the web
  console.

## Resolution

- Full recursion from the root servers (like unbound behind Pi-hole), no
  upstream forwarders.
- Recursion allowed only for private networks
  (`AllowOnlyForPrivateNetworks`). Check whether the tailnet range
  `100.64.0.0/10` counts before pointing tailnet DNS here.
- Blocking enabled with the same lists as Pi-hole: StevenBlack hosts and the
  Czech Turris list.

The `DNS_SERVER_*` variables are read when the config is created. Changes to
blocklists, recursion or logging after the first start are made in the web
console (Settings) and live in `/etc/dns`, not in Git.

## Logging and the SD card

oht-lab5 runs from a microSD card, so writes are kept small:

- Query logging is off. If query history is wanted, use a Technitium app
  that exports queries to another host (database or syslog), not a local
  file.
- Server log (errors and events) in `/etc/dns/logs`, kept 7 days.
- Dashboard stats kept 30 days (small hourly files).
- Docker logs use the `local` driver capped at 3x10 MB
  (`/etc/docker/daemon.json` on oht-lab5).

## Split horizon `betlem.cloud`

To be configured after the first start (web console, Zones). The Pi-hole
setup it replaces is described in the OHT-LAB notes: every `*.betlem.cloud`
name resolves to Caddy `192.168.50.115`, and public Cloudflare `AAAA`/`HTTPS`
records must not leak to LAN clients.

## Backup and restore

Back up `/opt/appdata/technitium` (or use Settings > Backup in the web
console). To restore, put the folder back before the first start; the admin
password from the environment is then ignored.

## Upstream references

- [Technitium DNS Server](https://technitium.com/dns/)
- [Docker environment variables](https://github.com/TechnitiumSoftware/DnsServer/blob/master/DockerEnvironmentVariables.md)
- [Sample compose file](https://github.com/TechnitiumSoftware/DnsServer/blob/master/docker-compose.yml)
