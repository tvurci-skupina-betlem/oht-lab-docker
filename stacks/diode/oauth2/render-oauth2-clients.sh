#!/bin/sh
# Writes /etc/config/oauth2/client/client-credentials.json for
# diode-auth-bootstrap and diode-reconciler from environment variables.
#
# DIODE_TO_NETBOX_CLIENT_SECRET  Diode reconciler -> NetBox plugin
# NETBOX_TO_DIODE_CLIENT_SECRET  NetBox plugin -> Diode
# DIODE_INGEST_CLIENTS           space-separated "client_id=secret" pairs, one
#                                per Orb Agent, e.g. "orb-docker3=abc orb-si-home=def"
#
# The bootstrap only creates clients that do not exist in Hydra yet. Adding a
# pair and redeploying adds a client; changing an existing secret does not
# rotate it (delete the client in Hydra first).
set -eu

out=/etc/config/oauth2/client/client-credentials.json

: "${DIODE_TO_NETBOX_CLIENT_SECRET:?DIODE_TO_NETBOX_CLIENT_SECRET is not set}"
: "${NETBOX_TO_DIODE_CLIENT_SECRET:?NETBOX_TO_DIODE_CLIENT_SECRET is not set}"
: "${DIODE_INGEST_CLIENTS:?DIODE_INGEST_CLIENTS is not set}"

client() {
  jq -n --arg id "$1" --arg secret "$2" --arg scope "$3" \
    '{client_id: $id, client_secret: $secret, grant_types: ["client_credentials"], scope: $scope}'
}

{
  client diode-to-netbox "$DIODE_TO_NETBOX_CLIENT_SECRET" "netbox:read netbox:write"
  client netbox-to-diode "$NETBOX_TO_DIODE_CLIENT_SECRET" "diode:read diode:write"
  for pair in $DIODE_INGEST_CLIENTS; do
    id=${pair%%=*}
    secret=${pair#*=}
    if [ -z "$id" ] || [ -z "$secret" ] || [ "$id" = "$pair" ]; then
      echo "diode-oauth2-init: invalid DIODE_INGEST_CLIENTS entry for client '$id'" >&2
      exit 1
    fi
    client "$id" "$secret" "diode:ingest"
  done
} | jq -s . > "$out.tmp"

chmod 644 "$out.tmp"
mv "$out.tmp" "$out"
echo "diode-oauth2-init: wrote $(jq length "$out") clients: $(jq -r 'map(.client_id) | join(", ")' "$out")"
