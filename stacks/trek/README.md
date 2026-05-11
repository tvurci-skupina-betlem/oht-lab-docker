# TREK

Self-hosted travel and trip planner deployed on OHT-LAB via Komodo.

## Deployment model

- Mode: Docker Compose
- Target: docker2
- Reverse proxy: Caddy
- Public hostname: `trek.betlem.cloud`
- Internal container port: `3000`
- Persistent data:
  - `./data`
  - `./uploads`

## Required secrets

Generate the encryption key:

```bash
openssl rand -hex 32
```

Set the result as:

```env
ENCRYPTION_KEY=<generated-value>
```

Do not commit the real `.env` file.

## First boot

On first boot, TREK creates an admin account. If explicit admin variables are
not set, credentials are printed to container logs:

```bash
docker logs trek
```

## Healthcheck

TREK exposes `http://localhost:3000/api/health`

## Reverse proxy notes

TREK uses WebSockets on the `/ws` path. The reverse proxy must support
HTTP `Upgrade: websocket` connections and must forward `/ws` to the TREK
container together with the normal HTTP/API routes.

Caddy supports WebSockets automatically with a standard `reverse_proxy`
directive, so a basic configuration is usually enough.

## Work to be done

- OpenAuth via FB, Google etc.
