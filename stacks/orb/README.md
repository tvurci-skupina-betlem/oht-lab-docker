# Orb Agent

Network discovery agent for OHT-LAB. Orb Agent runs NetBox Labs discovery
backends, including Nmap-based network discovery, and can forward discovered
entities to Diode for ingestion into NetBox.

## Deployment model

- Mode: Docker Compose
- Target: docker3
- Network mode: host
- Persistent output: `/mnt/cephfs/appdata/orb/output`
- Initial ingestion mode: dry-run

## Services

- `orb-agent`: NetBox Labs Orb Agent with the `network_discovery` backend

## Discovery scope

The initial policy scans:

```text
192.168.50.0/24
```

The policy is intentionally limited to OHT-LAB's management/LAN subnet. Expand
`config/agent.yaml` only after confirming scan behavior and runtime impact.

## Dry-run first

The stack defaults to:

```env
DIODE_DRY_RUN=true
```

This writes discovery output under `/mnt/cephfs/appdata/orb/output` instead of
ingesting directly into NetBox. Keep this enabled until Diode, credentials, and
NetBox import behavior are verified.

## Config sync

`config/agent.yaml` is mounted straight from the Komodo stack checkout. This
relies on Periphery mounting its root directory at the same path on the host
and inside the container, see [Komodo Periphery](../../komodo/periphery/README.md).
If Docker creates a directory at `config/agent.yaml` instead of mounting the
file, that mount is wrong on the node.

`config/agent.yaml` is a template. Orb Agent 2.8 does not expand `${VAR}`
placeholders on its own (only through a secrets manager), and it parses typed
fields such as `dry_run` before any expansion. `render-config.sh` runs as the
container entrypoint, fills the placeholders from the container environment
into `/tmp/agent.yaml`, fails if a variable is unset, and then starts the stock
image entrypoint with the rendered file.

## NetBox ingestion

When Diode is ready, set:

```env
DIODE_TARGET=grpc://<diode-host>:8080/diode
DIODE_CLIENT_ID=<diode-client-id>
DIODE_CLIENT_SECRET=<diode-client-secret>
DIODE_DRY_RUN=false
```

## Runtime permissions

Orb network discovery uses Nmap. The container runs with host networking,
`NET_RAW`, and `NET_ADMIN` so Nmap can perform normal host discovery from the
Docker node.

## Upstream references

- [Orb Agent repository](https://github.com/netboxlabs/orb-agent)
- [Orb Agent network discovery backend](https://github.com/netboxlabs/orb-agent/blob/develop/docs/backends/network_discovery.md)
- [NetBox Discovery quickstart](https://netboxlabs.com/blog/netbox-discovery-quickstart-guide/)
