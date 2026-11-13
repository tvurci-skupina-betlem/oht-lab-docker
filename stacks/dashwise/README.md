# Dashwise

[Dashwise](https://github.com/andreasmolnardev/dashwise) dashboard, deployed
for a side-by-side trial with Homepage, Glance and Dynacat.

## Deployment model

- Mode: Docker Compose, Komodo stack `dashwise` on docker3
- Image: `andreasmolnardev/dashwise:v1.0-rc2` (pre-release, all-in-one
  container with a bundled PocketBase)
- Hostname: `https://dashwise.betlem.cloud` (private: local network/tailnet)
- Host bind: `192.168.50.203:3016` (app); PocketBase `8090` is not published
- Data: `/opt/appdata/dashwise/pb_data` on docker3 local disk

## Configuration is in the UI, not in Git

Dashwise has no YAML config. Users, dashboards, links, widgets and
integrations live in its PocketBase database and are edited in the browser.
Only `compose.yml` and environment variables are versioned here. Links can be
bulk imported/exported in Settings > Apps.

## First run

1. Open `https://dashwise.betlem.cloud` and **Sign up** with your own account.
2. Set `DASHWISE_DISABLE_SIGNUP=true` in Komodo (stack `dashwise`) and
   redeploy, so nobody else on the LAN can create an account.

The PocketBase superuser is `admin@betlem.cloud` with the Komodo secret
`DASHWISE_ADMIN_PASSWORD`.

Integrations of interest: Beszel (use the read-only `dashboards@betlem.cloud`
user, see `stacks/beszel/README.md`) and link monitoring.

## Backup and restore

Back up `/opt/appdata/dashwise/pb_data`, and always before upgrading:
upstream reported data loss during an earlier upgrade.
