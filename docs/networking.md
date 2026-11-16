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
| Homepage       | homepage.betlem.cloud     | docker3 | 3000      | 🔒       |
| Home Assistant | ha.betlem.cloud           | VM 303  | 8123      | ️🔒       |
| Dynacat        | dynacat.betlem.cloud      | docker3 | 8084      | 🔒       |
| Glance         | glance.betlem.cloud       | docker3 | 8082      | 🔒       |
| Dashwise       | dashwise.betlem.cloud     | docker3 | 3016      | 🔒       |
| Vaultwarden    | vault.betlem.cloud        | docker3 | 8081      | 🔓       |
| Bambuddy       | bumbuddy.betlem.cloud     | docker2 | 8000      | 🔓       |
| Trek           | trek.betlem.cloud         | docker2 | 3000      | 🔓       |
| SoulSync       | soulsync.betlem.cloud     | docker2 | 8008      | 🔒       |
| Komodo Core    | komodo.betlem.cloud       | docker2 | 9120      | 🔓       |
| Dockge         | dockge.betlem.cloud       | docker2 | 5001      | 🔒       |
| Technitium 1   | 192.168.50.105 (DNS :53)  | docker5 | 53, 5380  | LAN only |
| Technitium 2   | 192.168.50.xxx (DNS :53)  | docker1 | 53, 5380  | LAN only |
| Pi-hole 1      | 10.10.10.10               | CT 101  | 443       | 🔒       |
| Pi-hole 2      | 10.10.10.11               | CT 301  | 443       | 🔒       |
| Uptime Kuma    | uptimekuma.betlem.cloud   | docker2 | 3001      | 🔒       |
| Beszel         | beszel.betlem.cloud       | docker3 | 8090      | 🔒       |
| Beszel agents  | (none, SSH from hub)      | all     | 30876     | LAN only |
| NetBox         | netbox.betlem.cloud       | docker3 | 8000      | 🔓       |
| Diode          | (none, gRPC)              | docker3 | 8080      | LAN only |
| Homepage dev   | homepage-dev.betlem.cloud | docker3 | 3010      | 🔒       |
| Glance dev     | glance-dev.betlem.cloud   | docker3 | 8083      | 🔒       |
| Dynacat dev    | dynacat-dev.betlem.cloud  | docker3 | 8085      | 🔒       |

🔒 Public exposure means a `CNAME` record has been set up at Cloudflare DNS.
🔒 Private exposure means only Betlem local DNS has this `CNAME` record.
