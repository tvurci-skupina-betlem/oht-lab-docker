# Operations

## Change Flow

1. Create a branch.
2. Edit stack files or docs.
3. Open a pull request.
4. Let validation run.
5. Merge to `main`.
6. Review or apply the change in Komodo.

## Rollback

Prefer reverting the Git commit and redeploying through Komodo. For urgent
incidents, use the target node directly and document what changed afterward.

## Local Validation

```sh
sh ./scripts/validate-compose.sh
```

## Break-Glass Deploy

```sh
cd /opt/stacks/oht-lab-docker
docker compose \
  --env-file stacks/<stack-name>/.env \
  -f stacks/<stack-name>/compose.yml \
  up -d
```

## Host Paths

The working checkout on Docker nodes should be:

```text
/opt/stacks/oht-lab-docker
```

Persistent application data that needs to survive node replacement, support HA,
or prepare for Swarm should be mounted from:

```text
/mnt/cephfs/appdata/<stack-name>/
```

Before deploying a stack that uses CephFS appdata, create the directory with
the expected ownership and permissions for the container user.
