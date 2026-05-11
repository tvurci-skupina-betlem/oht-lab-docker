# OHT-LAB Docker

This repository describes the container operations model for OHT-LAB, a small Proxmox-based homelab and service platform. The goal is to keep application deployment reproducible, reviewable, and portable across individual Docker nodes and a future Docker Swarm mode.

The current deployment model is fixed-node Docker Compose managed through Komodo. Swarm support is treated as a migration path, not a requirement for every stack on day one.

## Repository Layout

```text
docs/                 Operational and architecture notes
komodo/resources/     Declarative Komodo resource sync files
scripts/              Local validation and maintenance helpers
stacks/               Compose stacks, one directory per application
stacks/_template/     Starting point for new stacks
```

Each stack should follow this shape:

```text
stacks/<stack-name>/
  compose.yml
  compose.swarm.yml      # optional migration overlay
  .env.example
  README.md
```

## Deployment Model

Production intent lives on `main`. Changes should be proposed through pull requests, validated by GitHub Actions and then applied by Komodo after merge.

```text
GitHub repo
  -> Komodo Git integration or webhook
  -> Komodo Core
  -> Periphery agents on docker1...docker4
  -> Docker Compose stacks
```

Manual deployment from a node remains a break-glass path:

```sh
cd /opt/stacks/oht-lab-docker
docker compose -f stacks/<stack-name>/compose.yml config
docker compose -f stacks/<stack-name>/compose.yml up -d
```

## Storage Conventions

The repository checkout on Docker nodes should live at:

```text
/opt/stacks/oht-lab-docker
```

Application data that must survive node replacement, support future HA, or be ready for Swarm migration should use CephFS-backed paths:

```text
/mnt/cephfs/appdata/<stack-name>/
```

Local Docker named volumes are acceptable for disposable state or services that are intentionally tied to one node. Each stack README should state which storage model it uses.

## Nodes

```text
docker1 -> OHT-LAB1 / pve1
docker2 -> OHT-LAB2 / pve2
docker3 -> OHT-LAB3 / pve3
docker4 -> OHT-LAB4 / pve4
```

## Validation

Run all Compose validation locally:

```sh
sh ./scripts/validate-compose.sh
```

List stack directories:

```sh
sh ./scripts/list-stacks.sh
```

GitHub Actions also validates Compose syntax on pull requests and pushes to `main`.

## Rules

- Commit `.env.example` files only.
- Keep runtime secrets outside Git.
- Prefer pinned image versions over floating `latest` tags for services that matter.
- Document host ports, persistent volumes, and backup needs in each stack README.
- Use `/mnt/cephfs/appdata/<stack-name>/` for persistent appdata that needs HA, portability, or future Swarm readiness.
- Keep fixed-node Compose files clean; add Swarm-specific behavior in `compose.swarm.yml` when needed.
