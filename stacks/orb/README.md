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

One agent per network that the others cannot reach. Every agent uses the same
compose file and template. Its scope comes from environment variables, set per
Komodo stack:

| Variable | Meaning | docker3 value |
| --- | --- | --- |
| `ORB_AGENT_NAME` | Agent name in Diode and NetBox | `orb-docker3` |
| `ORB_SCAN_TARGETS` | Comma-separated targets | `192.168.50.0/24` |
| `ORB_NETWORK_MASK` | Mask for discovered IPv4 addresses | `24` |
| `ORB_TENANT` | NetBox tenant for discovered addresses | `OHT-LAB` |
| `ORB_SCAN_SCHEDULE` | Cron schedule | `0 */6 * * *` |
| `ORB_SCAN_TIMEOUT` | Scan timeout in minutes | `10` |
| `DIODE_CLIENT_ID` | Diode ingest client of this agent | `orb-docker3` |

Diode creates a missing tenant on first ingestion. Keep tenant names stable;
a renamed tenant becomes a second tenant.

Each agent needs its own ingest client: add a `client_id=secret` pair to
`DIODE_INGEST_CLIENTS` on the Diode stack and redeploy Diode first.

Keep scopes tight. A `/16` takes far longer than a `/24` and may need a
larger `ORB_SCAN_TIMEOUT`.

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

Diode runs on docker3, see [Diode](../diode/README.md). When it and the NetBox
plugin are running, set:

```env
DIODE_TARGET=grpc://192.168.50.203:8080/diode
DIODE_CLIENT_ID=<agent client id from DIODE_INGEST_CLIENTS>
DIODE_CLIENT_SECRET=<its secret>
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
