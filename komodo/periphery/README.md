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

When moving from an older layout (for example
`/opt/stacks/komodo-periphery/data` mounted at `/etc/komodo`):

1. Stop and remove the old Periphery container.
2. Start this definition.
3. Redeploy every stack on that node from Komodo so it is cloned again into
   the new root directory and its containers are recreated with correct
   mounts.
4. Remove the old data directory once all stacks run correctly.

Persistent application data must not live in the stack checkout. Komodo can
re-clone it at any time. Use `/mnt/cephfs/appdata/<stack>` instead.

## docker2

On docker2, Periphery runs next to Komodo Core and is reached as
`https://periphery:8120` over the Core network. Apply the same root directory
rule to that Periphery service in the Core compose file.

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
