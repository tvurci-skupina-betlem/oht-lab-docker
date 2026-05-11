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

TREK exposes:

```
http://localhost:3000/api/health
```

## Reverse proxy notes

TREK uses WebSockets. The reverse proxy must support WebSocket upgrades for:

```
/ws
```

## Work to be done

- OpenAuth via FB, Google etc.
