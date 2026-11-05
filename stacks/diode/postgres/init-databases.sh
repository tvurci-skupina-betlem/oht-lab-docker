#!/bin/sh
# Runs once, on first start with an empty data directory. Creates the Diode
# and Hydra databases with their own users.
set -eu

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "${POSTGRES_DB:-$POSTGRES_USER}" \
  -v diode_pw="$DIODE_POSTGRES_PASSWORD" -v hydra_pw="$HYDRA_POSTGRES_PASSWORD" <<'EOSQL'
CREATE USER diode WITH PASSWORD :'diode_pw';
CREATE DATABASE diode OWNER diode;
GRANT ALL PRIVILEGES ON DATABASE diode TO diode;

CREATE USER hydra WITH PASSWORD :'hydra_pw';
CREATE DATABASE hydra OWNER hydra;
GRANT ALL PRIVILEGES ON DATABASE hydra TO hydra;
EOSQL
