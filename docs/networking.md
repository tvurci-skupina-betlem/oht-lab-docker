# Networking

Document externally reachable services, internal-only services, host ports,
reverse proxy routes, and tunnel dependencies here.

## Conventions

- Keep public hostnames explicit in stack README files.
- Avoid accidental host port conflicts.
- Prefer a shared reverse proxy network for HTTP services.
- Document whether a service is public, private, or VPN-only.

## Inventory

| Service        | Hostname                  | Node    | Host Port | Exposure |
| -------------- | ------------------------- | ------- | --------- | -------- |
| NetBox         | netbox.betlem.cloud       | docker3 | 8000      | public   |
| Bambuddy       | bumbuddy.betlem.cloud     | docker2 | 8000      | public   |
| Uptime Kuma    | uptimekuma.betlem.cloud   | docker2 | 3001      | private  |
| Dockge         | dockge.betlem.cloud       | docker2 | 5001      | private  |
| Komodo Core    | komodo.betlem.cloud       | docker2 | 9120      | private  |
| Homepage       | homepage.betlem.cloud     | docker3 | 3000      | private  |
| Diode          | (none, gRPC)              | docker3 | 8080      | LAN only |
| Vaultwarden    | vault.betlem.cloud        | docker3 | 8081      | public   |
| Pi-hole 1      | 10.10.10.10               | CT 101  | 443       | private  |
| Pi-hole 2      | 10.10.10.11               | CT 301  | 443       | private  |
| Home Assistant | ha.betlem.cloud           | VM 303  | 8123      | private  |
| Glance         | glance.betlem.cloud       | docker3 | 8082      | private  |
| Dynacat        | dynacat.betlem.cloud      | docker3 | 8084      | private  |
| Dashwise       | dashwise.betlem.cloud     | docker3 | 3016      | private  |
| Beszel         | beszel.betlem.cloud       | docker3 | 8090      | private  |
| Homepage dev   | homepage-dev.betlem.cloud | docker3 | 3010      | private  |
| Glance dev     | glance-dev.betlem.cloud   | docker3 | 8083      | private  |
| Dynacat dev    | dynacat-dev.betlem.cloud  | docker3 | 8085      | private  |
| Beszel agents  | (none, SSH from hub)      | pve1-3  | 30876     | LAN only |

Public exposure means a `CNAME` record has been set up at Cloudflare DNS.
Private exposure means only Betlem local DNS has this `CNAME` record.
