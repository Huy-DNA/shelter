#!/bin/sh
set -e

source /.env
umask 077

wait_for_leader() {
  until curl -s http://vault-1:8200/v1/sys/health | grep -q '"sealed":false'; do
    echo "Primary vault still sealed, waiting..."
    sleep 2
  done
}

wait_for_leader

MAX_DURATION=300  # 5 minutes in seconds
RETRY_DELAY=5     # 5 seconds between attempts

echo "Authenticating to Vault..."

start_time=$(date +%s)

while true; do
  VAULT_TOKEN=$(curl -s \
      --request POST \
      --data "{\"password\": \"$METRICS_PASSWORD\"}" \
      http://vault-1:8200/v1/auth/userpass/login/metrics | jq -r '.auth.client_token')
  
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

METRICS_TOKEN=$(curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    http://vault-1:8200/kv/prometheus/vault-metrics | jq -r '.data.token')
echo $METRICS_TOKEN


prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/prometheus
