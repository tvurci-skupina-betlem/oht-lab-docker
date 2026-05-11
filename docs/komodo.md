# Komodo Model

Komodo maps this repository to operational resources:

| Komodo concept | OHT-LAB use |
| --- | --- |
| Server | `docker1`, `docker2`, `docker3`, `docker4` |
| Stack | One Compose application |
| Resource Sync | Declarative resource definitions from Git |
| Procedure | Controlled workflows such as validate, pull, deploy |
| Swarm | Future cluster deployment target |

## Initial Policy

Use Git-backed stacks with manual approval for critical deployments until webhook and Resource Sync behavior is verified in the live installation.

## Stack Paths

Each Komodo Stack should point to one stack directory under `stacks/`.

Example:

```text
stacks/uptime-kuma/compose.yml
```
