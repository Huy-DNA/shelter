#!/bin/sh
set -e

docker service rm vault_vault-1 vault_vault-2 vault_vault-3 vault_vault-transit-1 || echo "Services not created yet"
docker rm $(docker ps -a --filter ancestor=vault-1 --format="{{.ID}}") --force 2&> /dev/null || echo "Containers not created yet"
docker rm $(docker ps -a --filter ancestor=vault-2 --format="{{.ID}}") --force 2&> /dev/null || echo "Containers not created yet"
docker rm $(docker ps -a --filter ancestor=vault-3 --format="{{.ID}}") --force 2&> /dev/null || echo "Containers not created yet"
docker rm $(docker ps -a --filter ancestor=vault-transit-1 --format="{{.ID}}") --force 2&> /dev/null || echo "Containers not created yet"
docker volume rm vault_vault-1-data vault_vault-2-data vault_vault-3-data vault_vault-transit-1-data || echo "Volumes not created yet"
docker rmi vault-1 vault-2 vault-3 vault-transit-1 --force || echo "Images not created yet"

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

echo "Starting full Vault stack..."
sudo docker stack deploy --compose-file=docker-compose.yml vault

echo "Vault deployment complete."
