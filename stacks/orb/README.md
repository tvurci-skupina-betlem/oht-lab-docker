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
| `ORB_TENANT` | NetBox tenant for discovered addresses | `Betlém` |
| `ORB_TENANT_GROUP` | Group of that tenant | `OHT IT Services` |
| `ORB_VRF` | NetBox VRF for discovered addresses | `OHT-BETLEM` |
| `ORB_SCAN_SCHEDULE` | Cron schedule | `0 */6 * * *` |
| `ORB_SCAN_TIMEOUT` | Scan timeout in minutes | `10` |
| `DIODE_CLIENT_ID` | Diode ingest client of this agent | `orb-docker3` |

Tenant, tenant group and VRF must already exist in NetBox and match exactly.
A mismatch makes Diode create a second tenant or VRF instead of matching.
Every VRF has "enforce unique" on, so overlapping customer ranges such as
`192.168.0.0/24` stay separate.

Each agent needs its own ingest client: add a `client_id=secret` pair to
`DIODE_INGEST_CLIENTS` on the Diode stack and redeploy Diode first.

Keep scopes tight. A `/16` takes far longer than a `/24` and may need a
larger `ORB_SCAN_TIMEOUT`.

## Agents

- `orb-docker3`: docker3 (OHT-LAB), managed by Komodo, scope
  `192.168.50.0/24`, tenant `Betlém`, VRF `OHT-BETLEM`
- `orb-si-home`: SI-HOME-SERVER1 CT 103 (`172.27.1.22`), by hand, scope
  `172.27.1.0/24`, tenant `SEBESTA Home`, VRF `SI-HOME`
- `orb-si-nas1`: SI-NAS1 CT 102 (`192.168.0.20`), by hand, scope
  `192.168.0.0/24`, tenant `SEBESTA Industries`, VRF `SI-OFFICE`; staged,
  not started until SI-NAS1 is back at the office

## Remote sites (standalone)

SEBESTA agents are not managed by Komodo. Each host has a plain copy of this
directory in `/opt/stacks/orb` with a local `.env` (mode 600):

```bash
cd /opt/stacks/orb
docker compose up -d
docker logs orb-agent --tail 20
```

To update, copy `compose.yml`, `render-config.sh` and `config/agent.yaml` from
this repo again and run `docker compose up -d`.

They reach Diode on `192.168.50.203:8080` over Tailscale: the Docker LXC runs
`tailscale` with `--accept-routes`, and the OHT-LAB subnet router
(`oht-lab-tailscale-ha-exit`) advertises `192.168.50.0/24`.

The `DIODE_CLIENT_SECRET` in each host's `.env` must equal the matching
Komodo variable (`DIODE_INGEST_ORB_SI_HOME_SECRET`,
`DIODE_INGEST_ORB_SI_NAS1_SECRET`) used in the Diode stack's
`DIODE_INGEST_CLIENTS`.

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
