# Networking

Document externally reachable services, internal-only services, host ports, reverse proxy routes, and tunnel dependencies here.

## Conventions

- Keep public hostnames explicit in stack README files.
- Avoid accidental host port conflicts.
- Prefer a shared reverse proxy network for HTTP services.
- Document whether a service is public, private, or VPN-only.

## Inventory

| Service | Hostname | Node | Host port | Exposure |
| --- | --- | --- | --- | --- |
| Komodo Core | TBD | TBD | TBD | private |
| Uptime Kuma | TBD | docker2 | TBD | private |
