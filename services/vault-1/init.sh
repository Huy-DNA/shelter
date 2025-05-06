#!/bin/bash
set -e

source /vault/config/.env
vault operator init > /vault/data/init.txt

vault auth enable userpass

vault write auth/userpass/users/root \
  password=$ROOT_PASSWORD \
  policies=root
