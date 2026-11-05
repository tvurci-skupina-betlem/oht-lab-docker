# Komodo

Komodo is the deployment control plane for this repository.

The intended model is:

```text
GitHub repository
  -> Komodo Resource Sync and webhooks
  -> Komodo Core
  -> Periphery agents
  -> Docker nodes
```

## Resources

The files under `komodo/resources/` describe the Komodo resources that should
exist for OHT-LAB. The live Resource Sync object is created locally in Komodo,
not bootstrapped automatically by this repository.

The production sync should be named:

```text
oht-lab-production-sync
```

The matching reference definition is kept in
`komodo/resources/sync.toml` for documentation and recovery. The live sync
should point at these resource files:

```text
komodo/resources/servers.toml
komodo/resources/stacks.compose.toml
komodo/resources/stacks.swarm.toml
komodo/resources/procedures.toml
```

Keep the production sync on the `main` branch. Avoid using it for temporary
feature-branch deployments.

Expected mapping:

```text
docker1 -> OHT-LAB1 / pve1
docker2 -> OHT-LAB2 / pve2
docker3 -> OHT-LAB3 / pve3
docker4 -> OHT-LAB4 / pve4
```

## Periphery agents

The reference Periphery definition is in
[`komodo/periphery/`](periphery/README.md). Its root directory must be mounted
at the same path on the host and inside the container, otherwise relative bind
mounts such as `./config` resolve to empty directories and stacks ignore their
config files from Git.

## Initial Rollout

1. Add `docker1` through `docker4` as Komodo Servers with Periphery agents
   using `komodo/periphery/compose.yml`.
2. Configure the Git provider for this repository.
3. Create a local Resource Sync named `oht-lab-production-sync`.
4. Configure it for the `main` branch and the resource paths listed above.
5. Use `komodo/resources/sync.toml` as the reference definition if Komodo must
   be recreated.
6. Start with detect-and-review sync behavior.
7. Enable automatic deployment only after webhook behavior is verified on a
   non-critical stack.

## Testing New Stacks

Do not add a long-lived branch-specific Resource Sync for temporary stack
testing. For experiments such as the Orb rollout, create a temporary unmanaged
Komodo Stack instead:

```text
name: orb-test
server: docker3
repo: tvurci-skupina-betlem/oht-lab-docker
branch: add-orb-and-diode-for-netbox
run directory: stacks/orb
compose file: compose.yml
```

Copy the environment from the `orb` entry in
`komodo/resources/stacks.compose.toml`.

Use dry-run settings and non-production credentials where possible. Delete the
temporary stack after validation, then let `oht-lab-production-sync` manage the
real stack from `main` after the pull request is merged.
