# Technitium DNS

Recursive DNS resolver with ad blocking and the local `betlem.cloud` split
horizon. Meant to replace the two Pi-hole LXCs, so DNS keeps working when the
Proxmox cluster or Ceph is down.

## Deployment model

- Mode: Docker Compose, `network_mode: host`
- Primary: Komodo stack `technitium` on docker5 (oht-lab5, Raspberry Pi,
  outside the Proxmox cluster), `192.168.50.105`
- Secondary: Komodo stack `technitium-secondary` on docker1 (CT 201 on pve1),
  `192.168.50.201`, same `compose.yml` with its own environment
  (`TECHNITIUM_HOSTNAME`, `TECHNITIUM_WEB_ADDRESSES`)
- Both nodes form a Technitium cluster (see [Cluster](#cluster)); keep
  `TECHNITIUM_IMAGE_TAG` identical on both stacks
- DNS: UDP/TCP 53 on every host address (LAN and tailnet)
- Web console: `http://192.168.50.105:5380`, bound only to the addresses in
  `TECHNITIUM_WEB_ADDRESSES` (LAN IP and `127.0.0.1` for the healthcheck)
- Data: `/opt/appdata/technitium` on local disk, mounted at `/etc/dns`
  (config, zones, dashboard stats, server log). Never on CephFS.
- Admin user `admin`, password from Komodo secret `TECHNITIUM_ADMIN_PASSWORD`.
  It is applied on the first start only; later changes are made in the web
  console.

## Cluster

Technitium (v14+) clustering keeps the two nodes in sync. docker5 is the
primary, docker1 joins it as secondary.

- Synced from the primary: settings, Allowed/Blocked lists, apps and their
  config, users, groups, permissions and API tokens.
- Zones are synced only when they are members of the cluster catalog zone
  (Zone Options > General > Catalog).
- Not synced: cache, logs, dashboard stats and node-specific settings.
- Config changes are possible only while the primary is online. The secondary
  keeps answering DNS on its own and can be promoted with *Promote To Primary*.
- Node-to-node traffic is HTTPS with a self-signed certificate pinned through
  DNS (DANE). It must go directly between the node IPs, never through Caddy.
- Some Technitium releases break cluster compatibility: upgrade both stacks to
  the same tag together.

Setup (done once, web console):

1. Primary (docker5): Administration > Cluster > Initialize > New Cluster,
   cluster domain `dns.oht-lab.internal`, primary IP `192.168.50.105`.
2. Secondary (docker1): Administration > Cluster > Initialize > Join Cluster,
   secondary IP `192.168.50.201`, primary URL from step 1, admin login of the
   primary.

## Resolution

- Full recursion from the root servers (like unbound behind Pi-hole), no
  upstream forwarders.
- Recursion allowed only for private networks
  (`AllowOnlyForPrivateNetworks`). The tailnet range `100.64.0.0/10` counts
  as private (tested 2026-11-16 from a tailnet client against docker5's
  tailnet IP).
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

Every `*.betlem.cloud` name resolves to Caddy `192.168.50.115` on the LAN,
public names reach the same services through Cloudflare Tunnel.

- Primary zone `betlem.cloud` on the cluster primary, member of the cluster
  catalog zone, so docker1 holds the same zone.
- Records: `@` and `*` `A 192.168.50.115`, TTL 300. Nothing else; a new
  service needs no DNS change.
- The server is authoritative for the whole zone and never asks Cloudflare,
  so public `AAAA` and `HTTPS` (ECH, `ipv4hint`) records cannot leak to LAN
  clients: those queries get an empty `NOERROR`. This replaces the Pi-hole
  `dns.hosts` + `local=` + `dns-rr` workaround.
- Side effect: other record types published at Cloudflare (`MX`, `TXT`) are
  not visible from the LAN either.
- Bare hostnames (`OHT-5`) and the `.lan` suffix are not served. The ASUS
  router answers bare DHCP names only, not under `.lan`, and has no reverse
  zone, so no forwarder zones point at it.

Check from any LAN host:

```sh
dig +short @192.168.50.105 homepage.betlem.cloud A      # 192.168.50.115
dig +short @192.168.50.201 trek.betlem.cloud AAAA       # empty
dig @192.168.50.105 vault.betlem.cloud TYPE65           # NOERROR, no answer
```

## Backup and restore

Back up `/opt/appdata/technitium` (or use Settings > Backup in the web
console). To restore, put the folder back before the first start; the admin
password from the environment is then ignored.

## Upstream references

- [Technitium DNS Server](https://technitium.com/dns/)
- [Docker environment variables](https://github.com/TechnitiumSoftware/DnsServer/blob/master/DockerEnvironmentVariables.md)
- [Sample compose file](https://github.com/TechnitiumSoftware/DnsServer/blob/master/docker-compose.yml)
