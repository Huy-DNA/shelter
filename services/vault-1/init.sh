#!/bin/bash
set -e

source /vault/config/.env
vault operator init > /vault/data/init.txt

VAULT_TOKEN=$(grep 'Initial Root Token' /vault/data/init.txt | awk '{print $NF}')
vault login $VAULT_TOKEN

vault auth enable userpass

vault policy write admin - <<EOL
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOL
vault policy write metrics - << EOF
path "/sys/metrics" {
  capabilities = ["read"]
}
path "kv/data/prometheus/*" {
  capabilities = ["read"]
}
EOF

vault write auth/userpass/users/root \
  password=$ROOT_PASSWORD \
  policies=admin
vault write auth/userpass/users/metrics \
  password=$METRICS_PASSWORD \
  policies=metrics

vault secrets enable -path=kv kv-v2

TOKEN=$(vault token create -field=token -policy metrics)
vault kv put kv/prometheus/vault-metrics token="$TOKEN"
