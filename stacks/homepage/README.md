# Homepage

Application dashboard and start page for OHT-LAB services.

## Deployment model

- Mode: Docker Compose
- Target: docker3
- Reverse proxy via Caddy
- Public hostname: `https://homepage.betlem.cloud`
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

## Authentication

Homepage does not provide authentication. For external access via Cloudflare,
a Cloudflare Access login is to be setup.

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

## Upstream references

- [Homepage Docker installation](https://gethomepage.dev/installation/docker/)
- [Homepage Docker integration](https://gethomepage.dev/configs/docker/)
- [Homepage Proxmox widget](https://gethomepage.dev/widgets/services/proxmox/)
