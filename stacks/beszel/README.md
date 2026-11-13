# Beszel

Lightweight host monitoring: CPU, RAM, disk, network, sensor temperatures and
S.M.A.R.T. data (HDD/SSD/NVMe temperature and health) of the Proxmox hosts.
Feeds the disk-temperature widgets in Glance, Dynacat and Homepage.

## Deployment model

- Mode: Docker Compose, Komodo stack `beszel` on docker3
- Hostname: `https://beszel.betlem.cloud` (private: local network/tailnet)
- Host bind: `192.168.50.203:8090`
- Data: `/opt/appdata/beszel` on docker3 local disk (PocketBase/SQLite)
- First admin user is created from `BESZEL_USER_EMAIL` /
  `BESZEL_USER_PASSWORD` (Komodo secret `BESZEL_ADMIN_PASSWORD`) on a fresh
  install only.

## Agents

The hub connects over SSH to an agent on every Proxmox host. Agents run as a
systemd service directly on the host, not in Docker, because an unprivileged
LXC cannot read host disks or sensors.

| System | Address        | Port  | Notes                              |
| ------ | -------------- | ----- | ---------------------------------- |
| pve1   | 192.168.50.101 | 30876 | 4x SATA HDD, 2x NVMe               |
| pve2   | 192.168.50.102 | 30876 | 1x SATA SSD, 1x NVMe               |
| pve3   | 192.168.50.103 | 30876 | 1x SATA SSD, 1x NVMe               |
| pve4   | 192.168.50.104 | -     | not installed: host was unreachable |

Installed on each host (as root):

```sh
apt-get install -y smartmontools
curl -sL https://get.beszel.dev -o /tmp/install-agent.sh
sh /tmp/install-agent.sh -k "<hub public key>" -p 45876 -v 0.21.2 --auto-update false
```

Two systemd drop-ins in `/etc/systemd/system/beszel-agent.service.d/`:

```ini
# smart.conf: SATA needs CAP_SYS_RAWIO, NVMe needs CAP_SYS_ADMIN
[Service]
SupplementaryGroups=disk
AmbientCapabilities=CAP_SYS_RAWIO CAP_SYS_ADMIN
CapabilityBoundingSet=CAP_SYS_RAWIO CAP_SYS_ADMIN
```

```ini
# port.conf
[Service]
Environment="PORT=30876"
```

Port 30876 instead of the default 45876: 45876 lies in Linux's ephemeral port
range (32768-60999). On pve1, `ceph-mon` had an outgoing connection using
local port 45876, so the agent could not bind. After changing a system's port
in the hub, restart the hub container; it does not reconnect on its own.

The hub public key is shown in the UI ("Add system") or returned by
`GET /api/beszel/getkey` for a logged-in user. Add a system in the UI with
host `192.168.50.10x` and port `30876`.

S.M.A.R.T. is collected every hour (`SMART_INTERVAL`, default `1h`).

## Accounts used by the dashboards

| Account                   | Type                    | Used by                  | Komodo secret               |
| ------------------------- | ----------------------- | ------------------------ | --------------------------- |
| `admin@betlem.cloud`      | admin user + superuser  | you                      | `BESZEL_ADMIN_PASSWORD`     |
| `dashboards@betlem.cloud` | read-only user          | Glance, Dynacat          | `BESZEL_DASHBOARD_PASSWORD` |
| `homepage@betlem.cloud`   | PocketBase superuser    | Homepage `beszel` widget | `BESZEL_HOMEPAGE_PASSWORD`  |

The Homepage widget logs in through `_superusers` and does not work with a
normal user. Treat that password like an admin password.

## PocketBase settings (Beszel UI > `/_/` > Settings)

- **Trusted proxy:** header `X-Forwarded-For`, rightmost IP. Without it every
  request appears to come from Caddy and all clients share one rate limit.
- **Rate limits:** `*:auth` 10 per 60 s, with docker3 (`192.168.50.203`) in
  excluded IPs. Glance and Dynacat log in on every widget refresh. Because
  Beszel is reachable on the LAN at `192.168.50.203:8090`, a LAN client can
  spoof `X-Forwarded-For` to dodge the limit; acceptable on the home LAN.

These live in the Beszel database, not in Git. Re-apply them after a restore
from scratch.

## Backup and restore

Back up `/opt/appdata/beszel` (stop the stack first, or use the PocketBase
backup in `/_/`). Agents keep no state worth backing up.

## Upstream references

- [Beszel hub installation](https://beszel.dev/guide/hub-installation)
- [Beszel agent installation](https://beszel.dev/guide/agent-installation)
- [S.M.A.R.T. data](https://beszel.dev/guide/smart-data)
