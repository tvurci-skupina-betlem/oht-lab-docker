# Komodo Periphery

Reference Compose definition for the Komodo Periphery agent on each Docker
node. Periphery is bootstrapped by hand on the node (it cannot deploy itself),
so this file is kept here for review and recovery.

## Why the root directory matters

Periphery clones every Git-backed stack into
`${PERIPHERY_ROOT_DIRECTORY}/stacks/<stack-name>/` and runs `docker compose`
from the stack's run directory. Compose turns relative bind mounts such as
`./config` into absolute paths as seen **inside the Periphery container**, then
hands them to the **host** Docker daemon.

If the root directory is mounted at a different path on the host than inside
the container (for example `./data:/etc/komodo`), the host has no such path.
Docker silently creates an empty directory and mounts that. Applications then
start with empty config, and some (Homepage) write default files into it,
ignoring the files from Git.

Always mount the root directory at the identical path on both sides:

```yaml
- /etc/komodo:/etc/komodo
```

## Install or migrate on a node

```bash
sudo mkdir -p /etc/komodo
cp .env.example .env   # fill in the Core public key or passkey
docker compose up -d
```

Persistent application data must not live in the stack checkout. Komodo can
re-clone it at any time. Use `/mnt/cephfs/appdata/<stack>`, or a local path
such as `/opt/appdata/<stack>` for SQLite databases.

## Current OHT-LAB nodes

The existing nodes predate this file and were fixed in place on 2026-11-05
instead of being redeployed from it. Both already mounted `/opt/stacks` at the
same path inside and outside the container, so only `PERIPHERY_ROOT_DIRECTORY`
had to change (in `compose.yml` and `.env`):

- docker1:
- docker2: compose in `/opt/stacks/komodo` (together with Core),
  root `/opt/stacks/komodo/data/periphery`,
  keys `./data/periphery-keys:/config/keys`
- docker3: compose in `/opt/stacks/komodo-periphery`,
  root `/opt/stacks/komodo-periphery/data`,
  keys `./keys:/config/keys`
- oht-ai1: Periphery runs as the systemd service `periphery` with the binary
  `/usr/local/bin/periphery` and config `/etc/komodo/periphery.config.toml`
  (no Docker).

Notes:

- The old `./data/...:/etc/komodo` mount is kept, so nothing that still refers
  to `/etc/komodo` breaks.
- `PERIPHERY_PRIVATE_KEY=file:/config/keys/periphery.key` was not persisted
  before, so every recreate generated a new key. The key is now bind-mounted.
- On docker2, Periphery runs next to Komodo Core and is reached as
  `https://periphery:8120`. Recreate only that service:
  `docker compose up -d --no-deps periphery`.
- Running stacks keep their old mounts until they are redeployed from Komodo.
  Stale copies from before the fix were moved to
  `/root/old-etc-komodo-stacks-20261105/` on each node.

## Upgrading

Core and the Docker-based Periphery agents use the `:2` image tag.

1. Dump the Core database on docker2 into
   `/opt/stacks/komodo/data/komodo/backups/` with
   `mongodump --archive --gzip` inside `komodo-mongo`.
2. On docker2, in `/opt/stacks/komodo`:
   `docker compose pull core periphery && docker compose up -d core periphery`.
   Mongo is pinned to `mongo:7` and is upgraded separately.
3. On docker1 and docker3, in `/opt/stacks/komodo-periphery`:
   `docker compose pull && docker compose up -d`.
4. On oht-ai1, replace `/usr/local/bin/periphery` with `periphery-aarch64`
   from the matching GitHub release and restart the `periphery` service.
5. Check that every server reports the new version with state `Ok`.

## Moving a node to this definition

When moving from an older layout where the root directory is mounted at a
different path (for example `/opt/stacks/komodo-periphery/data` at
`/etc/komodo`):

1. Move any stack data that lives in the checkout to a path outside it first,
   otherwise the stack starts with empty data after the switch.
2. Stop and remove the old Periphery container.
3. Start this definition with `PERIPHERY_ROOT_DIRECTORY` set to the existing
   host data directory, so existing checkouts and keys are reused.
4. Redeploy every stack on that node from Komodo so its containers are
   recreated with correct mounts.
5. Remove leftovers under the old path once all stacks run correctly.

## Verify

```bash
docker inspect homepage \
  --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{println}}{{end}}'
```

The source of `/app/config` must be a path under `PERIPHERY_ROOT_DIRECTORY`
that contains the YAML files from Git.

## Upstream references

- [Komodo Periphery compose](https://github.com/moghtech/komodo/blob/main/compose/periphery.compose.yaml)
- [Root directory discussion](https://github.com/moghtech/komodo/discussions/180)
