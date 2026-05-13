# NetBox

Network source-of-truth and IPAM/DCIM platform deployed on OHT-LAB via
Komodo.

## Deployment model

- Mode: Docker Compose
- Target: docker3
- Reverse proxy: Caddy
- Public hostname: `netbox.betlem.cloud`
- Internal container port: `8080`
- Host bind: `${NETBOX_BIND_IP:-127.0.0.1}:${NETBOX_PORT:-8000}`
- Persistent data: `/mnt/cephfs/appdata/netbox/`

## Services

- `netbox`: NetBox web application
- `netbox-worker`: NetBox background job worker
- `postgres`: PostgreSQL database
- `redis`: Valkey queue backend
- `redis-cache`: Valkey cache backend

## Required secrets

Generate deployment secrets before first boot:

```bash
openssl rand -base64 32
openssl rand -base64 64
```

Set these variables in Komodo or in a host-local `.env` file:

```env
POSTGRES_PASSWORD=<generated-value>
REDIS_PASSWORD=<generated-value>
REDIS_CACHE_PASSWORD=<generated-value>
SECRET_KEY=<generated-value>
API_TOKEN_PEPPER_1=<generated-value>
SUPERUSER_PASSWORD=<generated-value>
SUPERUSER_API_TOKEN=<generated-value>
```

Do not commit the real `.env` file.

## First boot

The stack bootstraps the first admin account using:

```env
SKIP_SUPERUSER=false
SUPERUSER_NAME=admin
SUPERUSER_EMAIL=admin@betlem.cloud
SUPERUSER_PASSWORD=<generated-value>
SUPERUSER_API_TOKEN=<generated-value>
```

After the first successful login, rotate or disable the bootstrap credentials
according to your operating procedure.

## Reverse proxy notes

NetBox listens on container port `8080`. A local reverse proxy can use:

```text
127.0.0.1:8000
```

When publishing through Caddy, keep these environment values aligned with the
public hostname:

```env
ALLOWED_HOSTS=netbox.betlem.cloud localhost
CSRF_TRUSTED_ORIGINS=https://netbox.betlem.cloud
```

## Backup and restore

Back up `/mnt/cephfs/appdata/netbox/` and take logical PostgreSQL dumps before
major upgrades:

```bash
docker exec netbox-postgres pg_dump -U netbox netbox > netbox.sql
```

The media, reports, scripts, Postgres data, and Valkey data live under the same
appdata root for node portability.

## Upstream references

- [NetBox Docker wiki](https://github.com/netbox-community/netbox-docker/wiki/)
- [NetBox Docker release compose](https://github.com/netbox-community/netbox-docker/blob/release/docker-compose.yml)
