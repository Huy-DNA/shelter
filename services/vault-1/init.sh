#!/bin/bash
set -e

vault operator init > /vault/data/init.txt

ROOT_TOKEN=$(grep 'Initial Root Token' /vault/data/init.txt | awk '{print $NF}')

vault login $ROOT_TOKEN

vault auth enable userpass

vault write auth/userpass/users/root \
  password=$ROOT_PASSWORD \
  policies=root
