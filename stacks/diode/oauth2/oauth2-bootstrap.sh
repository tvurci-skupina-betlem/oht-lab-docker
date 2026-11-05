#!/bin/sh
# Renders /etc/config/oauth2/client/client-credentials.json from environment
# variables, creates missing clients in Hydra with the upstream
# bootstrap-clients.sh, then stays up so Komodo sees a running container.
# Dependent services wait for the healthcheck (/tmp/bootstrapped).
#
# DIODE_TO_NETBOX_CLIENT_SECRET  Diode reconciler -> NetBox plugin
# NETBOX_TO_DIODE_CLIENT_SECRET  NetBox plugin -> Diode
# DIODE_INGEST_CLIENTS           space-separated "client_id=secret" pairs, one
#                                per Orb Agent, e.g. "orb-docker3=abc orb-si-home=def"
#
# Hydra only gets clients it does not know yet. Adding a pair and redeploying
# adds a client; changing an existing secret does not rotate it (delete the
# client in Hydra first).
set -eu

out=/etc/config/oauth2/client/client-credentials.json
rm -f /tmp/bootstrapped

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
      echo "oauth2-bootstrap: invalid DIODE_INGEST_CLIENTS entry for client '$id'" >&2
      exit 1
    fi
    client "$id" "$secret" "diode:ingest"
  done
} | jq -s . > "$out.tmp"
chmod 644 "$out.tmp"
mv "$out.tmp" "$out"
echo "oauth2-bootstrap: wrote $(jq length "$out") clients: $(jq -r 'map(.client_id) | join(", ")' "$out")"

# Hydra may still be migrating or starting; retry until the clients exist.
until /bin/sh /etc/config/oauth2/bootstrap-clients.sh; do
  echo "oauth2-bootstrap: Hydra not ready, retrying in 5s" >&2
  sleep 5
done

touch /tmp/bootstrapped
echo "oauth2-bootstrap: done, idling"
trap 'exit 0' TERM INT
while :; do sleep 3600 & wait $!; done
