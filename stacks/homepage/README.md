# Homepage

Application dashboard and start page for OHT-LAB services.

## Deployment model

- Mode: Docker Compose
- Target: docker3
- Reverse proxy via Caddy
- Hostname: `https://homepage.betlem.cloud` (private: local network only)
- Internal container port: `3000`
- Host bind: `${HOMEPAGE_BIND_IP:-192.168.50.203}:${HOMEPAGE_PORT:-3000}`
- Persistent config: `./config`

## Services

- `homepage`: Dashboard UI
- `dockerproxy`: Read-only Docker socket proxy for local container discovery

## Required configuration

Homepage v1.0+ requires `HOMEPAGE_ALLOWED_HOSTS` for every hostname used to
access the UI. Keep it comma-separated with no spaces.

```env
HOMEPAGE_ALLOWED_HOSTS=homepage.betlem.cloud
```

## Exposure and authentication

Homepage is **private**. It is reachable only from the local network, through
the `homepage.betlem.cloud` record in Betlem local DNS. There is no Cloudflare
DNS record for it, so it is not reachable from the internet.

Homepage has no authentication of its own, and the dashboard shows internal
details (Proxmox cluster metrics, running containers, links to private
services). Keep it off the internet: do not add a Cloudflare `CNAME` or tunnel
route for it unless an authentication layer, such as Cloudflare Access, is put
in front first.

## Backup and restore

Back up the `config` directory. It contains the dashboard layout, bookmarks,
service links, and Docker integration config.

## Specific widget integrations

### Proxmox widget

The dashboard has one cluster-wide Proxmox card and one node-specific card for
each `pve1` through `pve4`. The cluster card omits the widget `node` setting,
so Homepage shows cluster-wide VM/LXC counts and average resource metrics. The
node cards pin the same widget to a specific Proxmox node.

Use a stable Proxmox API URL for `HOMEPAGE_VAR_PROXMOX_URL`. If that URL points
to a down node, all Proxmox widgets fail until the endpoint is reachable again.
If the API endpoint is reachable but an individual node is down, only that
node-specific card should lose live node metrics; the cluster card and other
node cards can still work from the reachable cluster API.

Create a Proxmox API token for Homepage and grant it read-only visibility for
the cluster resources you want displayed. The Homepage widget expects the token
ID as the username and the token secret as the password:

```env
HOMEPAGE_VAR_PROXMOX_URL=https://lab.betlem.cloud:8006
HOMEPAGE_VAR_PROXMOX_USERNAME=homepage@pam!homepage
HOMEPAGE_VAR_PROXMOX_PASSWORD=<proxmox-api-token-secret>
```

Use `user@realm!token-id` for `HOMEPAGE_VAR_PROXMOX_USERNAME`, for example
`homepage@pam!homepage`. Keep the real token secret in Komodo or a host-local
`.env` file.

### Docker integration

This stack uses `ghcr.io/tecnativa/docker-socket-proxy` instead of mounting
`/var/run/docker.sock` into Homepage directly. Homepage connects to the proxy
through `config/docker.yaml`:

```yaml
local-docker:
  host: dockerproxy
  port: 2375
```

This only discovers containers on the Docker node where Homepage is deployed.
For services on other nodes, keep explicit entries in `config/services.yaml` or
add additional remote Docker proxies later.

### qBittorrent widget

The `ArrStuff` group shows qBittorrent on OHT-NAS1 through Caddy at
`https://qbittorrent.betlem.cloud` (upstream `http://192.168.50.50:6363`).
The password comes from the Komodo secret variable
`HOMEPAGE_QBITTORRENT_PASSWORD` through `HOMEPAGE_VAR_QBITTORRENT_PASSWORD`;
never write it into `config/services.yaml`.

### Komodo widget

The Komodo card shows stack health (total, running, down, unhealthy). The widget
calls Komodo Core through Caddy at `https://komodo.betlem.cloud`. Create an API
key and secret in Komodo settings, preferably for a dedicated read-only service
user, and store them as the Komodo secret variables `HOMEPAGE_KOMODO_API_KEY`
and `HOMEPAGE_KOMODO_API_SECRET`.

### Pi-hole widgets

The `Network` group has one card per Pi-hole, reached through Caddy:
`https://pihole-primary.betlem.cloud` (`10.10.10.10`) and
`https://pihole-secondary.betlem.cloud` (`10.10.10.11`). Both run Pi-hole v6,
so the widget has `version: 6`.
In each Pi-hole, create an app password (Settings > Web interface / API >
Configure app password) and store it as the Komodo secret variables
`HOMEPAGE_PIHOLE_PRIMARY_APP_PASSWORD` and
`HOMEPAGE_PIHOLE_SECONDARY_APP_PASSWORD`. In the Pi-hole app-password dialog,
copy the password first, then click **Enable new app password**; without that
click the password is never saved.

### Uptime Kuma widget

Uptime Kuma has no full API, so the widget reads one status page from
`https://uptimekuma.betlem.cloud/status/<slug>`. Create a status page in Uptime
Kuma that includes the monitors you want counted, then set its slug in
`HOMEPAGE_VAR_UPTIMEKUMA_SLUG` (default `oht-lab`). The status page needs no
credentials.

### HTTPS

Every link and widget uses an HTTPS hostname served by Caddy (CT 104 on pve2,
`/etc/caddy/Caddyfile`, not managed in this repository). Caddy talks plain HTTP
to the upstream on the LAN. The only exception is the router bookmark,
`https://192.168.50.1:8443/`, which uses the router's own self-signed
certificate.

Docker nodes resolve `*.betlem.cloud` through the Pi-holes (wildcard
`address=/betlem.cloud/192.168.50.115`), so these hostnames point to Caddy
on the LAN.

## Config is managed in Git

Komodo deploys `config/` straight from this repository. Edits made on the
host are overwritten on the next deploy, so change the YAML here and redeploy.

## Upstream references

- [Homepage Docker installation](https://gethomepage.dev/installation/docker/)
- [Homepage Docker integration](https://gethomepage.dev/configs/docker/)
- [Homepage Proxmox widget](https://gethomepage.dev/widgets/services/proxmox/)
