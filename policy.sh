#!/usr/bin/env bash
set -euo pipefail

export VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
# export VAULT_TOKEN=<root token>  before running this

echo "== Enabling KV-v2 at secret/ (mount path 'secret', app path 'app/production') =="
vault secrets enable -path=secret -version=2 kv-v2 2>/dev/null || echo "already enabled"

echo "== Writing the static secret =="
vault kv put secret/app/production \
  API_KEY=Prod_991823 \
  encryption_salt="$(openssl rand -hex 16)"

echo "== Reading it back to confirm =="
vault kv get secret/app/production

echo "== Creating the frontend-reader policy =="
vault policy write frontend-reader ./frontend-reader.hcl

echo "== Issuing a token scoped to frontend-reader to prove restriction =="
CHILD_TOKEN=$(vault token create -policy="frontend-reader" -field=token)

echo "-- read should succeed --"
VAULT_TOKEN="$CHILD_TOKEN" vault kv get secret/app/production

echo "-- write should be denied --"
if VAULT_TOKEN="$CHILD_TOKEN" vault kv put secret/app/production API_KEY=hacked 2>/dev/null; then
  echo "!! PROBLEM: write succeeded, policy is too permissive"
else
  echo "OK: write denied as expected"
fi

echo "-- delete should be denied --"
if VAULT_TOKEN="$CHILD_TOKEN" vault kv delete secret/app/production 2>/dev/null; then
  echo "!! PROBLEM: delete succeeded, policy is too permissive"
else
  echo "OK: delete denied as expected"
fi
