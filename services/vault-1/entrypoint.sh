#!/bin/sh
set -e
apk add curl jq

source /vault/config/.env
umask 077

wait_for_transit() {
  until curl -s http://vault-transit-1:8200/v1/sys/health | grep -q '"initialized":true'; do
    echo "vault-transit not ready yet, waiting..."
    sleep 2
  done
}

wait_for_transit

MAX_DURATION=300  # 5 minutes in seconds
RETRY_DELAY=5     # 5 seconds between attempts

echo "Authenticating to Vault..."

start_time=$(date +%s)

while true; do
  VAULT_TOKEN=$(curl -s \
      --request POST \
      --data "{\"password\": \"$UNSEAL_PASSWORD\"}" \
      http://vault-transit-1:8200/v1/auth/userpass/login/internal-server | jq -r '.auth.client_token')
  
  if [ "$VAULT_TOKEN" != "null" ] && [ -n "$VAULT_TOKEN" ]; then
    echo "Authentication successful!"
    break
  fi
  
  current_time=$(date +%s)
  elapsed_time=$((current_time - start_time))
  
  echo "Authentication attempt $attempt failed. Elapsed time: ${elapsed_time}s of ${MAX_DURATION}s"
  
  if [ $elapsed_time -ge $MAX_DURATION ]; then
    echo "Maximum retry duration (5 minutes) reached. Authentication failed."
    exit 1
  fi
  
  echo "Retrying in $RETRY_DELAY seconds..."
  sleep $RETRY_DELAY
done

echo "Proceeding with Vault token..."

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

if [ -f /vault/data/init.txt ]; then
  echo "Vault already initialized"
else
  echo "Initializing vault..."
  source /vault/init.sh
fi

wait "$VAULT_PID"
