# Networking

Document externally reachable services, internal-only services, host ports,
reverse proxy routes, and tunnel dependencies here.

## Conventions

- Keep public hostnames explicit in stack README files.
- Avoid accidental host port conflicts.
- Prefer a shared reverse proxy network for HTTP services.
- Document whether a service is public, private, or VPN-only.

## Inventory

| Service     | Hostname                | Node    | Host port | Exposure |
| ----------- | ----------------------- | ------- | --------- | -------- |
| Uptime Kuma | uptimekuma.betlem.cloud | docker2 | 3001      | private  |
| Dockge      | dockge.betlem.cloud     | docker2 | 5001      | private  |
| NetBox      | netbox.betlem.cloud     | docker3 | 8000      | public   |
| Komodo Core | komodo.betlem.cloud     | docker2 | 9120      | private  |

Public exposure means a `CNAME` record has been set up at Cloudflare DNS.
Private exposure means only Betlem local DNS has this "CNAME" record.
