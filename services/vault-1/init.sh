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

vault write auth/userpass/users/root \
  password=$ROOT_PASSWORD \
  policies=admin
