#!/bin/sh
# Render ${VAR} placeholders in the Orb config template from the container
# environment, then hand off to the stock image entrypoint.
#
# Orb Agent 2.8 does not expand environment variables in its config file
# unless a secrets manager is configured, and it parses typed fields such as
# dry_run before any expansion, so the template must be rendered first.
set -eu

template=/opt/orb/agent.yaml.tmpl
rendered=/tmp/agent.yaml

perl -pe 's/\$\{(\w+)\}/defined $ENV{$1} ? $ENV{$1} : die "orb: environment variable $1 is not set\n"/ge' \
  "$template" > "$rendered"

exec /usr/local/bin/orb-agent-entry.sh "$@"
