#!/bin/sh
set -e

if ! docker info --format '{{.Swarm.LocalNodeState}}' | grep -q "active"; then
  echo "Initializing Docker Swarm..."
  sudo docker swarm init
fi

cd vault-1
docker build -t vault-1 .
cd -

cd vault-2
docker build -t vault-2 .
cd -

cd vault-3
docker build -t vault-3 .
cd -

cd vault-transit-1
docker build -t vault-transit-1 .
cd -

cd nginx
docker build -t nginx .
cd -

echo "Starting full Vault stack..."
sudo docker stack deploy --compose-file=docker-compose.yml vault

echo "Vault deployment complete."
