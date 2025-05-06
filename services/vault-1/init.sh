#!/bin/bash
set -e

vault operator init > /vault/data/init.txt

vault write auth/userpass/users/root \
    password=$ROOT_PASSWORD \
    policies=root
