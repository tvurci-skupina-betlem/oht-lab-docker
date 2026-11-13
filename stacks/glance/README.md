# Glance

Glance dashboard, deployed next to Homepage, Dynacat and Dashwise for a
side-by-side trial.

## Deployment model

- Mode: Docker Compose, Komodo stack `glance` on docker3
- Hostname: `https://glance.betlem.cloud` (private: local network/tailnet)
- Host bind: `192.168.50.203:8082`
- Config: `./config`, mounted read-only from the Git checkout
- No persistent data

## Services

- `glance`: dashboard
- `dockerproxy`: read-only Docker socket proxy for the `docker-containers`
  widget (containers on docker3 only)

## Config layout

```text
config/glance.yml              server, theme, list of pages
config/home.yml                Home page
config/infra.yml               Infra page
config/widgets/proxmox.yml     Proxmox nodes with every CT/VM (custom-api)
config/widgets/komodo-stacks.yml  Komodo servers and stacks (custom-api)
config/widgets/beszel-hosts.yml   Beszel host CPU/RAM/disk/temp (custom-api)
config/widgets/disk-temps.yml     S.M.A.R.T. disk temperatures (custom-api)
```

Dynacat includes `home.yml` and `infra.yml` from this directory, so changes
here show up in both dashboards.

Included files start with `- name:` / `- type:`, because `$include` replaces
the whole list item line. Placeholders in the form `${NAME}` are substituted
everywhere, including comments; each must be defined in `compose.yml`.

## Secrets (Komodo)

| Variable                    | Komodo secret                            |
| --------------------------- | ---------------------------------------- |
| `PROXMOX_TOKEN_ID/SECRET`   | `HOMEPAGE_PROXMOX_TOKEN_ID/SECRET`       |
| `KOMODO_API_KEY/SECRET`     | `HOMEPAGE_KOMODO_API_KEY/SECRET`         |
| `BESZEL_PASSWORD`           | `BESZEL_DASHBOARD_PASSWORD`              |
| `PIHOLE_*_PASSWORD`         | `HOMEPAGE_PIHOLE_*_APP_PASSWORD`         |

## Exposure and authentication

Private like Homepage: no Cloudflare record, no Glance `auth` configured.
Do not publish it without adding `auth:` or Cloudflare Access first.

## Editing

Use the dev instance and `scripts/dash-dev.sh` (see
`stacks/dashboards-dev/README.md`), then open a PR.

## Upstream references

- [Glance configuration](https://github.com/glanceapp/glance/blob/main/docs/configuration.md)
- [Custom API widget](https://github.com/glanceapp/glance/blob/main/docs/custom-api.md)
- [Community widgets](https://github.com/glanceapp/community-widgets)
