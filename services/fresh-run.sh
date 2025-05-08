#!/bin/sh
set -e

echo "🧹 Cleaning up old Docker services, containers, volumes, images..."

docker service rm vault_vault-1 vault_vault-2 vault_vault-3 vault_vault-transit-1 vault_prometheus vault_grafana vault_nginx || echo "Services not created yet"

for IMAGE in vault-1 vault-2 vault-3 vault-transit-1 nginx; do
  docker rm $(docker ps -a --filter ancestor=$IMAGE --format="{{.ID}}") --force 2>/dev/null || echo "Containers for $IMAGE not found"
done

docker volume rm vault_vault-1-data vault_vault-2-data vault_vault-3-data vault_vault-transit-1-data grafana-data vault_nginx-data vault_grafana-data || echo "Volumes not created yet"

docker rmi vault-1 vault-2 vault-3 vault-transit-1 nginx --force || echo "Images not created yet"

echo "🧼 Cleaning old Docker config for Prometheus (if exists)..."
docker config rm prometheus-config 2>/dev/null || echo "No existing prometheus-config to remove"

echo "📦 Creating new Docker config for Prometheus..."
docker config create prometheus-config ./prometheus/prometheus.yml

echo "🔄 Initializing Docker Swarm (if not active)..."
if ! docker info --format '{{.Swarm.LocalNodeState}}' | grep -q "active"; then
  docker swarm init || echo "Swarm already initialized"
fi

echo "🔨 Building Vault service images..."
for SERVICE in vault-1 vault-2 vault-3 vault-transit-1 nginx; do
  echo "➡️ Building $SERVICE..."
  (cd $SERVICE && docker build -t $SERVICE .)
done

echo "🚀 Deploying full Vault stack with Prometheus and Grafana..."
docker stack deploy --compose-file=docker-compose.yml vault

echo "✅ Vault stack deployment complete."
