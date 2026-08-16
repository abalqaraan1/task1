#!/usr/bin/env bash
set -euo pipefail

export VAULT_ADDR="http://127.0.0.1:8200"
SECRETS_FILE="./vault-init.json"   # KEEP THIS FILE SAFE — root token + unseal keys live here

echo "== Bringing up Vault + Postgres =="
docker compose up -d

echo "== Waiting for Vault to respond =="
until curl -s "$VAULT_ADDR/v1/sys/health" >/dev/null 2>&1; do
  sleep 1
done

echo "== Initializing Vault (5 key shares, 3-key threshold) =="
vault operator init \
  -key-shares=5 \
  -key-threshold=3 \
  -format=json > "$SECRETS_FILE"

chmod 600 "$SECRETS_FILE"

echo "== Unsealing with 3 of the 5 keys =="
KEY1=$(jq -r '.unseal_keys_b64[0]' "$SECRETS_FILE")
KEY2=$(jq -r '.unseal_keys_b64[1]' "$SECRETS_FILE")
KEY3=$(jq -r '.unseal_keys_b64[2]' "$SECRETS_FILE")

vault operator unseal "$KEY1"
vault operator unseal "$KEY2"
vault operator unseal "$KEY3"

echo "== Status after unseal =="
vault status

ROOT_TOKEN=$(jq -r '.root_token' "$SECRETS_FILE")
export VAULT_TOKEN="$ROOT_TOKEN"

echo ""
echo "== Proving the seal/unseal cycle =="
vault operator seal
vault status || true   # will show sealed=true, exit code 2 is expected here

vault operator unseal "$KEY1"
vault operator unseal "$KEY2"
vault operator unseal "$KEY3"
vault status

echo ""
echo "Root token and unseal keys are saved in $SECRETS_FILE. Export it for later steps:"
echo "  export VAULT_ADDR=http://127.0.0.1:8200"
echo "  export VAULT_TOKEN=$(jq -r '.root_token' "$SECRETS_FILE")"
