#!/bin/sh
set -e

echo "🧹 Cleaning up old Docker services, containers, volumes, images..."

docker service rm vault_vault-1 vault_vault-2 vault_vault-3 vault_vault-transit-1 vault_prometheus vault_grafana vault_nginx || echo "Services not created yet"

for IMAGE in vault-1 vault-2 vault-3 vault-transit-1 nginx; do
  docker rm $(docker ps -a --filter ancestor=$IMAGE --format="{{.ID}}") --force 2>/dev/null || echo "Containers for $IMAGE not found"
done

docker volume rm vault_vault-1-data vault_vault-2-data vault_vault-3-data vault_vault-transit-1-data grafana-data vault_nginx-data vault_grafana-data || echo "Volumes not created yet"

docker rmi vault-1 vault-2 vault-3 vault-transit-1 nginx --force || echo "Images not created yet"

docker config rm prometheus-config 2>/dev/null || echo "No existing prometheus-config to remove"
