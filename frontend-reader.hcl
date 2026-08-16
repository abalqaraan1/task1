# Read-only access to the KV-v2 "production" app config.
# Note: for kv-v2, the actual data lives under "secret/data/<path>",
# and version metadata under "secret/metadata/<path>" — the API
# transparently prepends "data/" or "metadata/" to what you pass to
# `vault kv` commands, but policies must reference the real API paths.

path "secret/data/app/production/*" {
  capabilities = ["read"]
}

path "secret/data/app/production" {
  capabilities = ["read"]
}

# Explicitly deny everything else under this KV mount, including
# metadata deletion/version management, so update/delete are blocked.
path "secret/metadata/app/production/*" {
  capabilities = ["read", "list"]
}

path "secret/*" {
  capabilities = ["deny"]
}
