# Stack Template

Use this directory as the starting point for new fixed-node Compose stacks.

## Files

- `compose.yml` is the default Compose deployment file.
- `compose.swarm.yml` is an optional overlay for future Swarm deployment.
- `.env.example` documents variables that must be provided outside Git.

## Manual Validation

```sh
docker compose --env-file .env.example -f compose.yml config
```

## Manual Deployment

```sh
cp .env.example .env
docker compose --env-file .env -f compose.yml up -d
```

## Notes To Fill In

- Target node:
- Host ports:
- Storage model: local Docker volume or `/mnt/cephfs/appdata/<stack-name>/`
- Persistent volumes:
- Backup procedure:
- Public hostnames:
