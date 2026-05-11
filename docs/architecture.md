# Architecture

OHT-LAB runs containerized services on Docker nodes hosted inside a Proxmox environment.

The initial operating model is fixed-node Docker Compose. Komodo owns deployment state and talks to Periphery agents on each Docker node. The repository stores stack definitions and documentation so changes can be reviewed before they are deployed.

On Docker nodes, the repository checkout should live at `/opt/stacks/oht-lab-docker`. Komodo should remain the normal deployment path; direct use of that checkout is a break-glass option.

## Current Target

```text
GitHub
  -> Komodo Core
  -> Periphery agents
  -> docker1, docker2, docker3, docker4
  -> Docker Compose
```

## Future Target

Docker Swarm can be introduced later for services that benefit from cluster scheduling, rolling updates, or replicated service management.

Swarm-specific configuration belongs in `compose.swarm.yml` overlays so the fixed-node Compose files remain simple.

## Storage

Application data has two supported models:

```text
Local Docker volume                 -> node-local state
/mnt/cephfs/appdata/<stack-name>/   -> persistent, portable, HA-ready state
```

Use CephFS-backed appdata for services that need durable state across node replacement, future HA behavior, or Swarm migration. Use local volumes only when the data is disposable or intentionally bound to one node.
