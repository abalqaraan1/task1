#!/usr/bin/env bash
set -euo pipefail

export VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
# export VAULT_TOKEN=<root token>  before running this

echo "== Enabling the database secrets engine =="
vault secrets enable database 2>/dev/null || echo "already enabled"

echo "== Configuring the connection (Vault authenticates as vaultadmin) =="
vault write database/config/postgres \
  plugin_name=postgresql-database-plugin \
  allowed_roles="app-db-role" \
  connection_url="postgresql://{{username}}:{{password}}@postgres-db:5432/appdb?sslmode=disable" \
  username="vaultadmin" \
  password="VaultDB_Admin_ChangeMe_2026"

# Rotate the vaultadmin password immediately so only Vault knows it from now on.
vault write -force database/rotate-root/postgres

echo "== Creating app-db-role: 1 hour TTL, self-destructing credentials =="
vault write database/roles/app-db-role \
  db_name=postgres \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
    GRANT app_readonly TO \"{{name}}\";" \
  revocation_statements="REASSIGN OWNED BY \"{{name}}\" TO vaultadmin; \
    DROP OWNED BY \"{{name}}\"; \
    DROP ROLE IF EXISTS \"{{name}}\";" \
  default_ttl="1h" \
  max_ttl="1h"

echo "== Requesting a live credential to prove it works =="
vault read database/creds/app-db-role

echo ""
echo "The lease_id above carries default_ttl=1h/max_ttl=1h."
echo "Vault's expiration manager will auto-revoke it at expiry, which runs"
echo "the revocation_statements above and drops the role from Postgres."
echo ""
echo "To PROVE self-destruction without waiting 60 minutes, force-revoke:"
echo '  vault lease revoke database/creds/app-db-role/<lease_id>'
echo "then connect to Postgres and confirm the role no longer exists:"
echo '  docker exec -it postgres-db psql -U root -d appdb -c "\du"'
