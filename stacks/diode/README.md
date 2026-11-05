# Diode

NetBox Labs ingestion service. Orb Agents send discovered entities to Diode
over gRPC. Diode reconciles them and writes them into NetBox through the
NetBox Diode plugin.

```text
Orb Agent --gRPC--> nginx :8080 --> ingester --> redis --> reconciler
                          |                                     |
                          +--> diode-auth --> Hydra              v
                                                       NetBox plugin API
```

## Deployment model

- Mode: Docker Compose
- Target: docker3, next to NetBox
- Endpoint: `grpc://192.168.50.203:8080/diode` (LAN only, no reverse proxy)
- Persistent data: `/opt/appdata/diode/` (local disk: PostgreSQL and Redis)

## Services

- `ingress-nginx`: single entry point, routes gRPC and auth, checks tokens
- `diode-ingester`: accepts ingestion requests from agents
- `diode-reconciler`: diffs ingested entities against NetBox and applies them
- `diode-auth`: token endpoint and introspection, backed by Hydra
- `hydra`, `hydra-migrate`: Ory Hydra OAuth2 server and its schema migration
- `postgres`: databases for the reconciler (`diode`) and Hydra (`hydra`)
- `redis`: Redis Stack, ingestion queue
- `diode-oauth2-init`: renders the OAuth2 client list from environment
  variables (runs once per deploy, then exits)
- `diode-auth-bootstrap`: creates missing OAuth2 clients in Hydra, then exits

## OAuth2 clients

Upstream keeps client secrets in `oauth2/client/client-credentials.json`. Here
`diode-oauth2-init` renders that file into a named volume from Komodo
variables, so no secret is stored in Git:

- `diode-to-netbox`: used by the Diode reconciler, scope
  `netbox:read netbox:write`, secret `DIODE_TO_NETBOX_CLIENT_SECRET`
- `netbox-to-diode`: used by the NetBox Diode plugin, scope
  `diode:read diode:write`, secret `NETBOX_TO_DIODE_CLIENT_SECRET`
- one client per Orb Agent, scope `diode:ingest`, listed in
  `DIODE_INGEST_CLIENTS`

`DIODE_INGEST_CLIENTS` is a space-separated list of `client_id=secret` pairs,
for example `orb-docker3=... orb-si-home=...`. Give every agent its own client
so one site can be revoked without touching the others.

The bootstrap only creates clients that Hydra does not know yet. Adding a pair
and redeploying adds a client. Changing the secret of an existing client does
not rotate it; delete the client in Hydra first:

```bash
docker exec diode-hydra hydra delete oauth2-client <client_id> --endpoint http://127.0.0.1:4445
```

## Required secrets

Generate each with `openssl rand -hex 32` and store them as Komodo variables:

```text
DIODE_REDIS_PASSWORD
DIODE_POSTGRES_ADMIN_PASSWORD
DIODE_POSTGRES_PASSWORD
DIODE_HYDRA_POSTGRES_PASSWORD
DIODE_HYDRA_SECRETS_SYSTEM
DIODE_TO_NETBOX_CLIENT_SECRET
DIODE_NETBOX_TO_DIODE_CLIENT_SECRET   (also used by the NetBox stack)
DIODE_INGEST_ORB_DOCKER3_SECRET       (one per Orb Agent)
```

`postgres/init-databases.sh` creates the databases only on first start with an
empty data directory. Changing a database password later needs `ALTER USER`.

## NetBox side

NetBox runs a custom image with `netboxlabs-diode-netbox-plugin`, see
[NetBox](../netbox/README.md). The plugin must reach Diode at
`DIODE_TARGET_OVERRIDE`, and Diode must reach the plugin API at
`NETBOX_DIODE_PLUGIN_API_BASE_URL`.

## Deploy order

1. Create the Komodo variables above.
2. Deploy `diode`.
3. Deploy `netbox` (builds the plugin image and runs its migrations).
4. Set Orb `DIODE_TARGET`, client ID and secret, then `DIODE_DRY_RUN=false`.

## Verify

```bash
docker compose ps
docker logs diode-oauth2-init
docker logs diode-auth-bootstrap
docker logs diode-reconciler --tail 50
```

In NetBox, the Diode plugin pages (Plugins → Diode) show the connection state
and the ingestion log.

## Upstream references

- [Diode server](https://github.com/netboxlabs/diode/tree/release/diode-server)
- [Diode NetBox plugin](https://github.com/netboxlabs/diode-netbox-plugin)
