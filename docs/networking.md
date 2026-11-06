# Networking

Document externally reachable services, internal-only services, host ports,
reverse proxy routes, and tunnel dependencies here.

## Conventions

- Keep public hostnames explicit in stack README files.
- Avoid accidental host port conflicts.
- Prefer a shared reverse proxy network for HTTP services.
- Document whether a service is public, private, or VPN-only.

## Inventory

| Service        | Hostname                      | Node     | Port | Exposure |
| -------------- | ----------------------------- | -------- | ---- | -------- |
| Uptime Kuma    | uptimekuma.betlem.cloud       | docker2  | 3001 | private  |
| Dockge         | dockge.betlem.cloud           | docker2  | 5001 | private  |
| NetBox         | netbox.betlem.cloud           | docker3  | 8000 | public   |
| Komodo Core    | komodo.betlem.cloud           | docker2  | 9120 | private  |
| Bambuddy       | bumbuddy.betlem.cloud         | docker2  | 8000 | public   |
| Homepage       | homepage.betlem.cloud         | docker3  | 3000 | private  |
| Diode          | (none, gRPC)                  | docker3  | 8080 | LAN only |
| Pi-hole 1      | pihole-primary.betlem.cloud   | CT 101   | 80   | private  |
| Pi-hole 2      | pihole-secondary.betlem.cloud | CT 301   | 80   | private  |
| qBittorrent    | qbittorrent.betlem.cloud      | OHT-NAS1 | 6363 | private  |
| Home Assistant | ha.betlem.cloud               | VM 303   | 8123 | private  |

The last four services run outside the Docker nodes: Pi-hole 1 is CT 101 on
pve2 (`10.10.10.10`), Pi-hole 2 is CT 301 on pve3 (`10.10.10.11`), qBittorrent
runs on OHT-NAS1 (`192.168.50.50`), and Home Assistant is VM 303 on pve3
(`192.168.50.111`). Caddy proxies all of them over HTTPS.

Public exposure means a `CNAME` record has been set up at Cloudflare DNS.
Private exposure means only Betlem local DNS has this "CNAME" record.
