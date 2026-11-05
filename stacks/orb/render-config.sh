#!/bin/sh
# Render ${VAR} placeholders in the Orb config template from the container
# environment, then hand off to the stock image entrypoint.
#
# Orb Agent does not expand environment variables in its config file unless
# a secrets manager is configured, and it parses typed fields such as dry_run
# before any expansion, so the template must be rendered first.
#
# Uses only POSIX awk: newer images ship busybox and no perl.
set -eu

template=/opt/orb/agent.yaml.tmpl
rendered=/tmp/agent.yaml

awk '
{
  out = ""
  line = $0
  while (match(line, /\$\{[A-Za-z_][A-Za-z0-9_]*\}/)) {
    name = substr(line, RSTART + 2, RLENGTH - 3)
    if (!(name in ENVIRON)) {
      print "orb: environment variable " name " is not set" > "/dev/stderr"
      exit 1
    }
    out = out substr(line, 1, RSTART - 1) ENVIRON[name]
    line = substr(line, RSTART + RLENGTH)
  }
  print out line
}
' "$template" > "$rendered"

exec /usr/local/bin/orb-agent-entry.sh "$@"
