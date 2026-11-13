# Dashboards dev

Dev instances of Homepage, Glance and Dynacat for trying out layout and widget
changes before they go into a pull request.

| App      | Dev URL                             | Port |
| -------- | ----------------------------------- | ---- |
| homepage | `https://homepage-dev.betlem.cloud` | 3010 |
| glance   | `https://glance-dev.betlem.cloud`   | 8083 |
| dynacat  | `https://dynacat-dev.betlem.cloud`  | 8085 |

Each dev instance reads `/opt/dashdev/<app>` on docker3, which
`scripts/dash-dev.sh` fills from `stacks/<app>/config`.

`dynacat-dev` also mounts `/opt/dashdev/glance` at `/app/glance` (read-write),
because Dynacat shares the Glance page files.

## Deployment model

- Mode: Docker Compose on docker3, Komodo stack `dashboards-dev`
- The services `extends` the production definitions in `../homepage`,
  `../glance` and `../dynacat`, so image tags, environment variables and
  secrets stay identical. Only the ports, container names and config mounts
  differ.
- Config is **not** taken from the Git checkout. It lives in `/opt/dashdev` on
  docker3 (local disk, scratch data, no backup needed).
- Private like production: local network or tailnet only.

## Edit loop

Run these from the repo root (Git Bash on Windows works):

```sh
scripts/dash-dev.sh watch glance      # or: homepage, dynacat, or nothing for all
```

1. Edit `stacks/<app>/config/*.yml` in your editor.
2. On save, `watch` copies the changed file to docker3 (about 1 second).
3. Refresh `https://<app>-dev.betlem.cloud`. Homepage, Glance and Dynacat
   reload their YAML without a restart.
4. When it looks right, commit, open a PR and merge. Komodo deploys
   production from `main`.

Other commands:

```sh
scripts/dash-dev.sh push [app]        # one-off copy of the repo config
scripts/dash-dev.sh diff [app]        # repo vs dev instance
scripts/dash-dev.sh pull [app]        # dev edits -> repo (e.g. Dynacat UI editor)
scripts/dash-dev.sh pull --new [app]  # ... including files that are new
scripts/dash-dev.sh logs [app]        # container log (YAML errors show here)
scripts/dash-dev.sh restart [app]     # only needed after env/compose changes
```

The script reaches docker3 through its Proxmox host by default
(`ssh claude-pve3`, then `pct exec 203`). To use your own access, set for
example `DASH_DEV_SSH=root@192.168.50.103` (Proxmox host) or
`DASH_DEV_SSH=you@192.168.50.203 DASH_DEV_CT=` (direct SSH into docker3).

### Dynacat UI editor

Dynacat has a built-in editor (pencil icon). On `dynacat-dev` it saves to
`/opt/dashdev/dynacat` and `/opt/dashdev/glance`; bring those edits into the
repo with `scripts/dash-dev.sh pull dynacat glance` and review `git diff`.
The editor is open to anyone on the LAN while no `auth` is configured. In
production the config is mounted read-only, so the editor cannot save there.

## Gotchas

- Glance/Dynacat replace `${NAME}` everywhere in the YAML, **comments
  included**. Every placeholder needs a matching variable in `compose.yml` and
  Komodo, or the whole config is rejected.
- A Glance `$include` replaces the whole `- $include: file.yml` line, dash
  included. Included files must therefore start with `- name:` (page) or
  `- type:` (widget).
- Changing environment variables or `compose.yml` needs a Komodo redeploy of
  `dashboards-dev` (the stack is Git-backed), not just `dash-dev.sh restart`.
- If a broken YAML was pushed while a container was starting, it may sit in a
  restart back-off; `scripts/dash-dev.sh restart <app>` clears it.
