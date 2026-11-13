# Dynacat

[Dynacat](https://github.com/Panonim/dynacat) is a Glance fork with live
widget updates, extra widgets and a UI editor. It runs here for a side-by-side
trial against Glance on the very same pages.

## Deployment model

- Mode: Docker Compose, Komodo stack `dynacat` on docker3
- Hostname: `https://dynacat.betlem.cloud` (private: local network/tailnet)
- Host bind: `192.168.50.203:8084`
- `compose.yml` extends the Glance service (same env and secrets) and only
  swaps the image, port and mounts.
- Config: `./config/dynacat.yml`, plus `../glance/config` mounted read-only at
  `/app/glance`. `dynacat.yml` includes `../glance/home.yml` and
  `../glance/infra.yml`.
- No persistent data

## Dynacat-only features

Put Dynacat-only pages or widgets in this `config/` directory and include them
from `dynacat.yml`, so the shared Glance pages stay valid for Glance.

## UI editor

Production mounts the config read-only, so the editor cannot save there
(Dynacat logs "Directory is not writable"). Use `dynacat-dev` to edit in the
browser, then `scripts/dash-dev.sh pull dynacat glance` to bring the changes
into Git. See `stacks/dashboards-dev/README.md`.

## Exposure

Private, no auth configured. Do not publish it without `auth:`.
