#!/bin/sh
set -e
apk add curl jq

source /vault/config/.env
umask 077

echo "Authenticating to Vault..."
VAULT_TOKEN=$(curl -s \
    --request POST \
    --data "{\"password\": \"$UNSEAL_PASSWORD\"}" \
    http://vault-transit-1:8200/v1/auth/userpass/login/internal-server | jq -r '.auth.client_token')

if [ "$VAULT_TOKEN" == "null" ] || [ -z "$VAULT_TOKEN" ]; then
    echo "Authentication failed"
    exit 1
fi

echo "Authentication successful"

TRANSIT_TOKEN=$(curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    http://vault-transit-1:8200/v1/kv/auto-unseal/transit-token | jq -r '.data.token')

if [ "$TRANSIT_TOKEN" == "null" ] || [ -z "$TRANSIT_TOKEN" ]; then
    echo "Failed to retrieve transit token"
    exit 1
fi

export VAULT_TOKEN=$TRANSIT_TOKEN

echo "Transit token retrieved successfully"
echo "Starting vault..."
vault server -config=/vault/config/vault-config.hcl &
VAULT_PID=$!
echo "Waiting for Vault to start..."
for i in $(seq 1 30); do
  if vault status > /dev/null 2>&1; then
    echo "Vault is up!"
    break
  fi
  sleep 1
done
vault operator init
wait "$VAULT_PID"
